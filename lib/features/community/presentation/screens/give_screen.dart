import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/payment_repository.dart';

class GiveScreen extends StatefulWidget {
  const GiveScreen({super.key, this.paymentRepository});

  final PaymentRepository? paymentRepository;

  @override
  State<GiveScreen> createState() => _GiveScreenState();
}

class _GiveScreenState extends State<GiveScreen> {
  String _purpose = 'Tithe';
  String _settlement = 'card';
  int _amountIndex = 1;
  bool _submitting = false;
  String? _error;
  String? _providerLabel;
  bool _providerActive = false;
  String? _proofName;
  List<int>? _proofBytes;
  final TextEditingController _customAmount = TextEditingController();

  static const _purposes = <String>[
    'Tithe',
    'Offering',
    'Missions',
    'Building Project',
    'Seed',
  ];

  /// Major-unit NGN presets shown in the UI; submitted as `amount_minor` (×100).
  static const _amounts = <int?>[1000, 2000, 5000, null];

  PaymentRepository? get _repo =>
      widget.paymentRepository ??
      AppServicesScope.maybeOf(context)?.paymentRepository;

  String _purposeLabel(String value) {
    switch (value) {
      case 'Tithe':
        return fhcT(context, 'give.purposeTithe', fallback: 'Tithe');
      case 'Offering':
        return fhcT(context, 'give.purposeOffering', fallback: 'Offering');
      case 'Missions':
        return fhcT(context, 'give.purposeMissions', fallback: 'Missions');
      case 'Building Project':
        return fhcT(
          context,
          'give.purposeBuilding',
          fallback: 'Building Project',
        );
      case 'Seed':
        return fhcT(context, 'give.purposeSeed', fallback: 'Seed');
      default:
        return value;
    }
  }

  String _purposeCode(String value) {
    return switch (value) {
      'Tithe' => 'tithe',
      'Offering' => 'offering',
      'Missions' => 'missions',
      'Building Project' => 'projects',
      'Seed' => 'donation',
      _ => 'offering',
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppServicesScope.maybeOf(context);
    if (services?.visualReview == true) return;
    final repo = _repo;
    if (repo == null || _providerLabel != null) return;
    repo.getConfiguration().then((result) {
      if (!mounted) return;
      switch (result) {
        case AppSuccess(:final value):
          final active = value['active'] == true;
          final provider = '${value['provider'] ?? ''}'.trim();
          setState(() {
            _providerActive = active;
            _providerLabel = active && provider.isNotEmpty
                ? provider[0].toUpperCase() + provider.substring(1)
                : fhcT(
                    context,
                    'give.notActivated',
                    fallback: 'Not activated',
                  );
          });
        case AppError():
          setState(
            () => _providerLabel = fhcT(
              context,
              'give.notActivated',
              fallback: 'Not activated',
            ),
          );
      }
    });
  }

  @override
  void dispose() {
    _customAmount.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  String get _buttonLabel {
    if (_submitting) {
      return fhcT(context, 'give.processing', fallback: 'Processing…');
    }
    final amount = _selectedAmountMajor();
    if (amount == null) {
      return fhcT(context, 'nav.give', fallback: 'Give');
    }
    return fhcT(
      context,
      'give.giveAmount',
      args: {'amount': _formatNaira(amount)},
      fallback: 'Give {amount}',
    );
  }

  int? _selectedAmountMajor() {
    final preset = _amounts[_amountIndex];
    if (preset != null) return preset;
    final parsed = num.tryParse(_customAmount.text.trim().replaceAll(',', ''));
    if (parsed == null || parsed < 1) return null;
    return parsed.round();
  }

  static String _formatNaira(int amount) {
    final raw = amount.toString();
    final buffer = StringBuffer('₦');
    for (var i = 0; i < raw.length; i++) {
      final fromEnd = raw.length - i;
      if (i > 0 && fromEnd % 3 == 0) buffer.write(',');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  String _chipLabel(int? amount) {
    if (amount == null) {
      return fhcT(context, 'give.other', fallback: 'Other');
    }
    return _formatNaira(amount);
  }

  Future<void> _pickProof() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
      allowMultiple: false,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes ?? const <int>[];
    if (bytes.isEmpty) return;
    setState(() {
      _proofName = file.name;
      _proofBytes = bytes;
      _error = null;
    });
  }

  bool get _needsProof => _settlement == 'manual';

  Future<void> _submit() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error = fhcT(
          context,
          'give.notConnected',
          fallback:
              'Giving is not connected to the payments service in this build.',
        );
      });
      return;
    }

    final amountMajor = _selectedAmountMajor();
    if (amountMajor == null) {
      setState(
        () => _error = fhcT(
          context,
          'give.enterAmount',
          fallback: 'Enter a gift amount of at least ₦1 to continue.',
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    String? proofId;
    if (_needsProof || _proofBytes != null) {
      final bytes = _proofBytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _submitting = false;
          _error = fhcT(
            context,
            'give.uploadReceiptRequired',
            fallback:
                'Upload a photo or PDF of your payment receipt before recording a manual gift.',
          );
        });
        return;
      }
      final uploaded = await repo.uploadPaymentProof(
        bytes: bytes,
        filename: _proofName ?? 'payment-receipt.jpg',
      );
      if (!mounted) return;
      switch (uploaded) {
        case AppError(:final failure):
          setState(() {
            _submitting = false;
            _error = paymentFailureMessage(failure);
          });
          return;
        case AppSuccess(:final value):
          proofId = '${value['id'] ?? value['public_id'] ?? ''}';
      }
    }

    final amountMinor = amountMajor * 100;
    final result = await repo.initiate({
      'amount_minor': amountMinor,
      'currency': 'NGN',
      'purpose_code': _purposeCode(_purpose),
      if (proofId != null && proofId.isNotEmpty) 'proof_file_asset_id': proofId,
    });

    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        final intentId = '${value['id'] ?? value['ulid'] ?? ''}';
        final provider = '${value['provider_code'] ?? ''}';
        if (provider == 'local_manual' && intentId.isNotEmpty) {
          if (proofId == null || proofId.isEmpty) {
            setState(() {
              _submitting = false;
              _settlement = 'manual';
              _error = fhcT(
                context,
                'give.uploadReceiptRequired',
                fallback:
                    'Upload a photo or PDF of your payment receipt before recording a manual gift.',
              );
            });
            return;
          }
          final completed = await repo.completeGivingIntent(
            intentId,
            proofFileAssetId: proofId,
          );
          if (!mounted) return;
          switch (completed) {
            case AppError(:final failure):
              setState(() {
                _submitting = false;
                _error = paymentFailureMessage(failure);
              });
              return;
            case AppSuccess(:final value):
              setState(() => _submitting = false);
              final receipt = value['receipt'];
              final transaction = value['transaction'];
              final receiptId =
                  receipt is Map ? '${receipt['id'] ?? ''}' : '';
              final txnId =
                  transaction is Map
                      ? '${transaction['id'] ?? ''}'
                      : intentId;
              fhcPush(
                context,
                receiptId.isNotEmpty
                    ? '/payments/success?id=${Uri.encodeComponent(receiptId)}'
                    : '/payments/success?id=${Uri.encodeComponent(txnId)}',
              );
              return;
          }
        }
        setState(() => _submitting = false);
        final checkoutUrl = hostedCheckoutUrlOf(value);
        if (checkoutUrl != null) {
          final launched = await launchUrl(
            Uri.parse(checkoutUrl),
            mode: LaunchMode.externalApplication,
          );
          if (!mounted) return;
          if (!launched) {
            setState(() {
              _error = fhcT(
                context,
                'give.checkoutOpenFailed',
                args: {
                  'provider': provider.isEmpty
                      ? fhcT(context, 'give.payment', fallback: 'payment')
                      : provider,
                },
                fallback:
                    'Could not open {provider} checkout. Try again from a device with a browser.',
              );
            });
            return;
          }
        }
        fhcPush(context, paymentIntentRoute(value));
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = paymentFailureMessage(failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'give.title', fallback: 'Give / Donate'),
            onBack: _goBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  fhcT(
                    context,
                    'give.wantToGiveTo',
                    fallback: 'I want to give to',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FhcTypography.label,
                ),
                const SizedBox(height: 7),
                _PurposeField(
                  value: _purpose,
                  options: _purposes,
                  labelOf: _purposeLabel,
                  onSelected: (value) => setState(() => _purpose = value),
                ),
                const SizedBox(height: 14),
                Text(
                  fhcT(
                    context,
                    'give.howAreYouPaying',
                    fallback: 'How are you paying?',
                  ),
                  style: FhcTypography.label,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _AmountChip(
                        label: fhcT(context, 'give.cardCheckout', fallback: 'Card'),
                        selected: _settlement == 'card',
                        onTap: () => setState(() => _settlement = 'card'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _AmountChip(
                        label: fhcT(
                          context,
                          'give.bankTransfer',
                          fallback: 'Bank transfer',
                        ),
                        selected: _settlement == 'manual',
                        onTap: () => setState(() => _settlement = 'manual'),
                      ),
                    ),
                  ],
                ),
                if (_needsProof) ...[
                  const SizedBox(height: 14),
                  FhcSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fhcT(
                            context,
                            'give.paymentReceipt',
                            fallback: 'Payment receipt',
                          ),
                          style: FhcTypography.label,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fhcT(
                            context,
                            'give.paymentReceiptHint',
                            fallback:
                                'Required for manual payment. Tithe and Offering are recorded as separate gifts.',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: FhcColors.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FhcPrimaryButton(
                          label: _proofName ??
                              fhcT(
                                context,
                                'give.uploadReceipt',
                                fallback: 'Upload receipt',
                              ),
                          onPressed: _submitting ? null : _pickProof,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  fhcT(context, 'give.amount', fallback: 'Amount'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FhcTypography.label,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < _amounts.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _AmountChip(
                          label: _chipLabel(_amounts[i]),
                          selected: _amountIndex == i,
                          onTap: () => setState(() => _amountIndex = i),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_amounts[_amountIndex] == null) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customAmount,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: fhcT(
                        context,
                        'give.customAmount',
                        fallback: 'Custom amount (NGN)',
                      ),
                      hintText: fhcT(
                        context,
                        'give.customAmountHint',
                        fallback: 'e.g. 7500',
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  fhcT(context, 'give.checkout', fallback: 'Checkout'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FhcTypography.label,
                ),
                const SizedBox(height: 8),
                FhcSurfaceCard(
                  child: Text(
                    _providerActive
                        ? fhcT(
                            context,
                            'give.checkoutActiveCopy',
                            args: {
                              'provider': _providerLabel ??
                                  fhcT(
                                    context,
                                    'give.activatedProvider',
                                    fallback: 'your activated provider',
                                  ),
                            },
                            fallback:
                                'Checkout opens {provider} '
                                '(Paystack, Flutterwave, or Stripe). Finish the gift '
                                'in that secure page, then return here to confirm.',
                          )
                        : fhcT(
                            context,
                            'give.checkoutInactiveCopy',
                            fallback:
                                'Giving stays closed until an administrator activates '
                                'Paystack, Flutterwave, or Stripe. No charge is created '
                                'while checkout is inactive.',
                          ),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: FhcColors.muted,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  FhcErrorState(
                    title: _errorTitle(_error!),
                    message: _error!,
                    onRetry: _submitting ? null : _submit,
                  ),
                ],
                const SizedBox(height: 16),
                FhcPrimaryButton(
                  label: _buttonLabel,
                  onPressed: _submitting ? null : _submit,
                ),
                const SizedBox(height: 8),
                Text(
                  fhcT(
                    context,
                    'give.noChargeUntilSuccess',
                    fallback:
                        'No charge is created until a governed payment intent succeeds.',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: FhcColors.muted,
                  ),
                ),
              ],
            ),
          ),
          FhcBottomNavigation(
            selected: 2,
            onSelected: (index) => fhcTab(context, index),
          ),
        ],
      ),
    );
  }

  String _errorTitle(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('governance')) {
      return fhcT(
        context,
        'give.notAvailable',
        fallback: 'Giving not available',
      );
    }
    return fhcT(
      context,
      'give.unableToStart',
      fallback: 'Unable to start giving',
    );
  }
}

class _PurposeField extends StatelessWidget {
  const _PurposeField({
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onSelected,
  });

  final String value;
  final List<String> options;
  final String Function(String value) labelOf;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FhcColors.white,
        borderRadius: radius,
        border: Border.all(color: FhcColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 22,
            color: FhcColors.muted,
          ),
          borderRadius: radius,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          style: FhcTypography.body,
          items: [
            for (final option in options)
              DropdownMenuItem<String>(
                value: option,
                child: Text(labelOf(option)),
              ),
          ],
          onChanged: (next) {
            if (next != null) onSelected(next);
          },
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Material(
        color: selected ? FhcColors.green : FhcColors.white,
        borderRadius: BorderRadius.circular(FhcRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.sm),
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? FhcColors.green : FhcColors.white,
              borderRadius: BorderRadius.circular(FhcRadius.sm),
              border: Border.all(
                color: selected ? FhcColors.green : FhcColors.border,
              ),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: selected ? FhcColors.white : FhcColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

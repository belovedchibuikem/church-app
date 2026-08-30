import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/payment_repository.dart';

class GivingHistoryScreen extends StatefulWidget {
  const GivingHistoryScreen({super.key, this.paymentRepository});

  final PaymentRepository? paymentRepository;

  @override
  State<GivingHistoryScreen> createState() => _GivingHistoryScreenState();
}

class _GivingHistoryScreenState extends State<GivingHistoryScreen> {
  FhcAsyncValue<List<_GivingEntry>> _state = const FhcAsyncValue.loading();

  PaymentRepository? get _repo =>
      widget.paymentRepository ??
      AppServicesScope.maybeOf(context)?.paymentRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) {
      _load();
    }
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'give.historyRequiresApi',
            fallback:
                'Giving history is waiting on the Laravel payments API. '
                'No fixture totals are shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.listTransactions();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'give.noTransactionsYet',
                fallback: 'No giving transactions yet.',
              ),
            );
          });
          return;
        }
        setState(() {
          _state = FhcAsyncValue.data([
            for (final item in value) _GivingEntry.fromJson(item),
          ]);
        });
      case AppError(:final failure):
        setState(() {
          final message = paymentFailureMessage(failure);
          _state = FhcAsyncValue.error(
            failure.code == 'PAYMENT_GOVERNANCE_DENIED' ||
                    failure is PaymentFailure
                ? PaymentFailure(message, code: failure.code)
                : failure is ForbiddenFailure
                ? ForbiddenFailure(message)
                : failure,
          );
        });
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          _GivingHeader(onBack: _back, onRefresh: _load),
          Expanded(
            child: FhcAsyncBody<List<_GivingEntry>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'give.noGivingYet',
                fallback: 'No giving yet',
              ),
              emptyMessage: fhcT(
                context,
                'give.completedGiftsAppearHere',
                fallback: 'Completed gifts will appear here.',
              ),
              unavailableTitle: fhcT(
                context,
                'give.historyUnavailable',
                fallback: 'Giving history unavailable',
              ),
              builder: (context, entries) {
                final total = entries.fold<num>(0, (sum, e) => sum + e.amount);
                return ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    _GivingSummary(
                      totalLabel: _formatGivingMoney(total),
                      countLabel: fhcT(
                        context,
                        'give.transactionCount',
                        args: {'count': '${entries.length}'},
                        fallback: '{count} Transactions',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FhcSurfaceCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var index = 0; index < entries.length; index++) ...[
                            if (index > 0) const Divider(height: 1),
                            _GivingRow(
                              entry: entries[index],
                              onTap: () {
                                final id = entries[index].id;
                                fhcPush(
                                  context,
                                  id.isEmpty
                                      ? '/payments/transaction'
                                      : '/payments/transaction?id=$id',
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const FhcBottomNavigation(selected: 4),
        ],
      ),
    );
  }

}

String _formatGivingMoney(num amountMinor) {
  return formatPaymentAmountMinor(amountMinor.round());
}

class _GivingHeader extends StatelessWidget {
  const _GivingHeader({required this.onBack, required this.onRefresh});
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FhcSizes.topBarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            fhcT(context, 'give.history', fallback: 'Giving History'),
            style: FhcTypography.titleSmall,
          ),
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: onBack,
              tooltip: fhcT(context, 'common.back', fallback: 'Back'),
              icon: const Icon(Icons.chevron_left, size: 28),
            ),
          ),
          Positioned(
            right: 12,
            child: Semantics(
              button: true,
              label: fhcT(
                context,
                'give.refreshHistory',
                fallback: 'Refresh giving history',
              ),
              child: InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(FhcRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fhcT(context, 'common.refresh', fallback: 'Refresh'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.refresh, size: 16, color: FhcColors.ink),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GivingSummary extends StatelessWidget {
  const _GivingSummary({required this.totalLabel, required this.countLabel});

  final String totalLabel;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fhcT(context, 'give.totalGiven', fallback: 'Total Given'),
                  style: const TextStyle(fontSize: 11, color: FhcColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  totalLabel,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.greenDark,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  countLabel,
                  style: const TextStyle(fontSize: 11, color: FhcColors.ink),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: FhcColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_outlined,
              size: 30,
              color: FhcColors.greenDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GivingEntry {
  const _GivingEntry({
    required this.id,
    required this.title,
    required this.date,
    required this.amountLabel,
    required this.amount,
    required this.icon,
  });

  factory _GivingEntry.fromJson(JsonObject json) {
    final amountMinor = paymentAmountMinorOf(json) ?? 0;
    final currency = '${json['currency'] ?? 'NGN'}';
    final dateRaw =
        '${json['occurred_at'] ?? json['created_at'] ?? json['paid_at'] ?? json['date'] ?? ''}';
    final parsed = DateTime.tryParse(dateRaw);
    final dateLabel =
        parsed == null
            ? (dateRaw.isEmpty ? '—' : dateRaw)
            : '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    final rawTitle =
        '${json['purpose_code'] ?? json['purpose'] ?? json['title'] ?? json['description'] ?? ''}';
    return _GivingEntry(
      id: '${json['id'] ?? json['ulid'] ?? ''}',
      title: rawTitle,
      date: dateLabel,
      amountLabel: formatPaymentAmountMinor(
        amountMinor,
        currency: currency.isEmpty ? 'NGN' : currency,
      ),
      amount: amountMinor,
      icon: Icons.card_giftcard_outlined,
    );
  }

  final String id;
  final String title;
  final String date;
  final String amountLabel;
  final num amount;
  final IconData icon;
}

class _GivingRow extends StatelessWidget {
  const _GivingRow({required this.entry, required this.onTap});
  final _GivingEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = entry.title.isEmpty
        ? fhcT(context, 'give.gift', fallback: 'Gift')
        : entry.title;
    return Semantics(
      button: true,
      label: '$title, ${entry.date}, ${entry.amountLabel}',
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(entry.icon, size: 22, color: FhcColors.ink),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        entry.date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: FhcColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  entry.amountLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.greenDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

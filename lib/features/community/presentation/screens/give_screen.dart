import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

enum _PayMethod { card, bank, ussd }

class GiveScreen extends StatefulWidget {
  const GiveScreen({super.key});

  @override
  State<GiveScreen> createState() => _GiveScreenState();
}

class _GiveScreenState extends State<GiveScreen> {
  String _purpose = 'Tithes & Offerings';
  int _amountIndex = 1;
  bool _recurring = false;
  _PayMethod _method = _PayMethod.card;

  static const _purposes = <String>[
    'Tithes & Offerings',
    'Missions',
    'Building Project',
    'Seed',
  ];

  static const _amounts = <int?>[1000, 2000, 5000, null];

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  void _setRecurring(bool value) => setState(() => _recurring = value);

  String get _buttonLabel {
    final amount = _amounts[_amountIndex];
    if (amount == null) return 'Give';
    return 'Give ${_formatNaira(amount)}';
  }

  static String _formatNaira(int amount) {
    final raw = amount.toString();
    final buffer = StringBuffer('N');
    for (var i = 0; i < raw.length; i++) {
      final fromEnd = raw.length - i;
      if (i > 0 && fromEnd % 3 == 0) buffer.write(',');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  static String _chipLabel(int? amount) {
    if (amount == null) return 'Other';
    return _formatNaira(amount);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(title: 'Give', onBack: _goBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                const Text(
                  'GIVE / DONATE',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: FhcColors.greenDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Support the work of the Kingdom.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: FhcColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                _FrequencySegment(
                  recurring: _recurring,
                  onChanged: _setRecurring,
                ),
                const SizedBox(height: 16),
                const Text(
                  'I want to give to',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FhcTypography.label,
                ),
                const SizedBox(height: 7),
                _PurposeField(
                  value: _purpose,
                  options: _purposes,
                  onSelected: (value) => setState(() => _purpose = value),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Amount',
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
                const SizedBox(height: 14),
                const Text(
                  'Payment Method',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FhcTypography.label,
                ),
                const SizedBox(height: 8),
                _PaymentMethods(
                  selected: _method,
                  onSelected: (value) => setState(() => _method = value),
                ),
                const SizedBox(height: 12),
                _RecurringCheck(
                  value: _recurring,
                  onChanged: _setRecurring,
                ),
                const SizedBox(height: 16),
                FhcPrimaryButton(label: _buttonLabel, onPressed: () {}),
                const SizedBox(height: 8),
                const Text(
                  'Your giving is secure and tax-deductible.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: FhcColors.muted,
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => fhcPush(context, FhcRoutes.giveHistory),
                    style: TextButton.styleFrom(
                      foregroundColor: FhcColors.green,
                      minimumSize: const Size(88, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Giving History',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          FhcBottomNavigation(
            selected: 0,
            onSelected: (index) => fhcTab(context, index),
          ),
        ],
      ),
    );
  }
}

class _FrequencySegment extends StatelessWidget {
  const _FrequencySegment({required this.recurring, required this.onChanged});

  final bool recurring;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: recurring ? 'Recurring giving' : 'One-time giving',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FhcColors.canvas,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              Expanded(
                child: _FrequencyTab(
                  label: 'One-time',
                  selected: !recurring,
                  onTap: () => onChanged(false),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _FrequencyTab(
                  label: 'Recurring',
                  selected: recurring,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyTab extends StatelessWidget {
  const _FrequencyTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 36,
          decoration: BoxDecoration(
            color: selected ? FhcColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1.1,
                color: selected ? FhcColors.white : FhcColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurposeField extends StatelessWidget {
  const _PurposeField({
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String value;
  final List<String> options;
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
              DropdownMenuItem<String>(value: option, child: Text(option)),
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

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods({required this.selected, required this.onSelected});

  final _PayMethod selected;
  final ValueChanged<_PayMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PaymentRow(
            selected: selected == _PayMethod.card,
            onTap: () => onSelected(_PayMethod.card),
            leading: const _CardBrandMark(),
            title: 'Card **** 4242',
            trailing: TextButton(
              onPressed: () => onSelected(_PayMethod.card),
              style: TextButton.styleFrom(
                foregroundColor: FhcColors.green,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                'Change',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const Divider(height: 1, color: FhcColors.border),
          _PaymentRow(
            selected: selected == _PayMethod.bank,
            onTap: () => onSelected(_PayMethod.bank),
            leading: const _PayIcon(Icons.account_balance_outlined),
            title: 'Bank Transfer',
          ),
          const Divider(height: 1, color: FhcColors.border),
          _PaymentRow(
            selected: selected == _PayMethod.ussd,
            onTap: () => onSelected(_PayMethod.ussd),
            leading: const _PayIcon(Icons.dialpad),
            title: 'USSD',
            subtitle: '*737*Grace*Amount#',
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? FhcColors.mint : FhcColors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _PayIcon extends StatelessWidget {
  const _PayIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: FhcColors.mint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: FhcColors.green, size: 16),
    );
  }
}

class _CardBrandMark extends StatelessWidget {
  const _CardBrandMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFF79E1B).withValues(alpha: 0.92),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringCheck extends StatelessWidget {
  const _RecurringCheck({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: 'Make this a recurring gift',
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(FhcRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  onChanged: (next) => onChanged(next ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: FhcColors.border, width: 1.4),
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return FhcColors.green;
                    }
                    return FhcColors.white;
                  }),
                  checkColor: FhcColors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Make this a recurring gift',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

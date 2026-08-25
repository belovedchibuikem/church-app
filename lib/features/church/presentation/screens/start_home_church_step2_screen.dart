import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class StartHomeChurchStep2Screen extends StatefulWidget {
  const StartHomeChurchStep2Screen({super.key});

  @override
  State<StartHomeChurchStep2Screen> createState() =>
      _StartHomeChurchStep2ScreenState();
}

class _StartHomeChurchStep2ScreenState
    extends State<StartHomeChurchStep2Screen> {
  static const _days = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const _times = <String>['5:00 PM', '6:00 PM', '7:00 PM', '8:00 PM'];

  static const _participants = <String>['10-20', '21-30', '31-50', '50+'];

  final Set<String> _selectedDays = {'Sun'};
  String _meetingTime = '6:00 PM';
  String _participantsRange = '10-20';

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.homeChurchStart);
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (!_selectedDays.remove(day)) {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(title: '', onBack: _onBack),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 640;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Start a Church\nin Your Home',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            height: 1.18,
                            fontWeight: FontWeight.w700,
                            color: FhcColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _StepBanner(),
                        const SizedBox(height: 10),
                        const _StepProgress(step: 2),
                        SizedBox(height: compact ? 16 : 22),
                        const FhcField(
                          label: 'Home Address',
                          hint: 'Enter your home address',
                          suffixIcon: Icons.location_on_outlined,
                          keyboardType: TextInputType.streetAddress,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        Text(
                          'Preferred Meeting Days',
                          style: FhcTypography.label,
                        ),
                        const SizedBox(height: 8),
                        _DayChips(
                          days: _days,
                          selected: _selectedDays,
                          onToggle: _toggleDay,
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        _DropdownField(
                          label: 'Meeting Time',
                          value: _meetingTime,
                          options: _times,
                          onChanged:
                              (value) => setState(() => _meetingTime = value),
                        ),
                        const SizedBox(height: 12),
                        _DropdownField(
                          label: 'Expected Participants',
                          value: _participantsRange,
                          options: _participants,
                          onChanged:
                              (value) =>
                                  setState(() => _participantsRange = value),
                        ),
                        SizedBox(height: compact ? 20 : 28),
                        FhcPrimaryButton(
                          label: 'Continue',
                          onPressed:
                              () =>
                                  fhcPush(context, FhcRoutes.homeChurchStart3),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBanner extends StatelessWidget {
  const _StepBanner();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: FhcColors.border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Step 2 of 4',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: FhcColors.muted,
            ),
          ),
        ),
        Expanded(child: Divider(color: FhcColors.border, height: 1)),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
              decoration: BoxDecoration(
                color: i < step ? FhcColors.green : FhcColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayChips extends StatelessWidget {
  const _DayChips({
    required this.days,
    required this.selected,
    required this.onToggle,
  });

  final List<String> days;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _DayChip(
              label: days[i],
              selected: selected.contains(days[i]),
              onTap: () => onToggle(days[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
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
      child: Material(
        color: selected ? FhcColors.green : FhcColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FhcRadius.sm),
          side: BorderSide(
            color: selected ? FhcColors.green : FhcColors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.sm),
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FhcTypography.label),
        const SizedBox(height: 7),
        DecoratedBox(
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FhcColors.ink,
              ),
              items: [
                for (final option in options)
                  DropdownMenuItem<String>(value: option, child: Text(option)),
              ],
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
            ),
          ),
        ),
      ],
    );
  }
}

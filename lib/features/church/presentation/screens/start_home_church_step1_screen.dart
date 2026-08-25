import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class StartHomeChurchStep1Screen extends StatefulWidget {
  const StartHomeChurchStep1Screen({super.key});

  @override
  State<StartHomeChurchStep1Screen> createState() =>
      _StartHomeChurchStep1ScreenState();
}

class _StartHomeChurchStep1ScreenState
    extends State<StartHomeChurchStep1Screen> {
  String _country = 'Nigeria';
  String _city = 'Lagos';

  static const _countries = <String>[
    'Nigeria',
    'Ghana',
    'Kenya',
    'United Kingdom',
    'United States',
  ];

  static const _cities = <String>[
    'Lagos',
    'Abuja',
    'Ibadan',
    'Port Harcourt',
    'Kano',
  ];

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
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
                final h = constraints.maxHeight;
                final compact = h < 520;
                final photoH = (h * 0.34).clamp(112.0, compact ? 136.0 : 172.0);

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
                      const _StepProgress(step: 1),
                      SizedBox(height: compact ? 12 : 16),
                      SizedBox(
                        height: photoH,
                        width: double.infinity,
                        child: const _LivingRoomPhoto(),
                      ),
                      SizedBox(height: compact ? 12 : 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'You can begin gathering people in the name of '
                          'Jesus right where you are. We will guide, support '
                          'and equip you every step of the way.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: FhcColors.ink,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      _DropdownField(
                        label: 'Country',
                        value: _country,
                        options: _countries,
                        onChanged: (value) => setState(() => _country = value),
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        label: 'City',
                        value: _city,
                        options: _cities,
                        onChanged: (value) => setState(() => _city = value),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: FhcPrimaryButton(
              label: 'Continue',
              onPressed: () => fhcPush(context, FhcRoutes.homeChurchStart2),
            ),
          ),
          TextButton(
            onPressed: () => fhcGo(context, FhcRoutes.hub),
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.ink,
              minimumSize: const Size(88, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
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
            'Step 1 of 4',
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

class _LivingRoomPhoto extends StatelessWidget {
  const _LivingRoomPhoto();

  static const _primary = 'assets/images/home_church_living.png';
  static const _fallback = 'assets/images/multiply_home.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FhcRadius.lg),
      child: Image.asset(
        _primary,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.12),
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            _fallback,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.12),
            errorBuilder:
                (context, error, stackTrace) =>
                    const ColoredBox(color: Color(0xFF4A3428)),
          );
        },
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

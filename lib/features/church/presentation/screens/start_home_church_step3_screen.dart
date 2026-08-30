import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/home_church_repository.dart';

class StartHomeChurchStep3Screen extends StatefulWidget {
  const StartHomeChurchStep3Screen({super.key});

  @override
  State<StartHomeChurchStep3Screen> createState() =>
      _StartHomeChurchStep3ScreenState();
}

class _StartHomeChurchStep3ScreenState
    extends State<StartHomeChurchStep3Screen> {
  static const _hearOptions = <String>[
    'A Friend / Member',
    'Church / Pastor',
    'Social Media',
    'Online Search',
    'Event or Crusade',
    'Other',
  ];

  late final TextEditingController _whyController;
  bool _hasMinistryExperience = true;
  String _heardFrom = 'A Friend / Member';
  bool _whySeeded = false;

  @override
  void initState() {
    super.initState();
    _whyController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_whySeeded) {
      _whySeeded = true;
      _whyController.text = fhcT(
        context,
        'homeChurch.whyStartDefault',
        fallback:
            'I have a burden to see my family, friends and neighbors '
            'come to know Jesus Christ and grow in His word.',
      );
    }
  }

  @override
  void dispose() {
    _whyController.dispose();
    super.dispose();
  }

  void _pop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.homeChurchStart2);
    }
  }

  void _continue() {
    final draft = HomeChurchApplicationSession.draft;
    if (draft.churchId == null ||
        draft.locationId == null ||
        draft.administrativeUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'homeChurch.returnToStep1',
              fallback: 'Return to step 1 and select a parent church.',
            ),
          ),
        ),
      );
      return;
    }
    if (draft.meetingDay == null ||
        draft.meetingTime == null ||
        draft.expectedParticipants == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'homeChurch.returnToStep2',
              fallback: 'Return to step 2 and set meeting details.',
            ),
          ),
        ),
      );
      return;
    }

    // Narrative fields are not part of the public API payload; keep local only.
    draft.preferredName ??= draft.churchName;
    fhcPush(context, FhcRoutes.homeChurchStart4);
  }

  String _hearLabel(BuildContext context, String value) {
    return switch (value) {
      'A Friend / Member' => fhcT(
        context,
        'homeChurch.hearFriend',
        fallback: 'A Friend / Member',
      ),
      'Church / Pastor' => fhcT(
        context,
        'homeChurch.hearChurch',
        fallback: 'Church / Pastor',
      ),
      'Social Media' => fhcT(
        context,
        'homeChurch.hearSocial',
        fallback: 'Social Media',
      ),
      'Online Search' => fhcT(
        context,
        'homeChurch.hearSearch',
        fallback: 'Online Search',
      ),
      'Event or Crusade' => fhcT(
        context,
        'homeChurch.hearEvent',
        fallback: 'Event or Crusade',
      ),
      'Other' => fhcT(context, 'homeChurch.hearOther', fallback: 'Other'),
      _ => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'homeChurch.startTitleInline',
              fallback: 'Start a Church in Your Home',
            ),
            onBack: _pop,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _StepBanner(step: 3),
                        const SizedBox(height: 10),
                        const _StepProgress(step: 3),
                        const SizedBox(height: 22),
                        Text(
                          fhcT(
                            context,
                            'homeChurch.tellUsAboutHeart',
                            fallback: 'Tell us about your heart',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: FhcColors.ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _WhyField(controller: _whyController),
                        const SizedBox(height: 18),
                        Text(
                          fhcT(
                            context,
                            'homeChurch.ministryExperience',
                            fallback: 'Do you have any experience in ministry?',
                          ),
                          style: FhcTypography.label,
                        ),
                        const SizedBox(height: 10),
                        _ExperienceOption(
                          label: fhcT(
                            context,
                            'homeChurch.servedBefore',
                            fallback: 'Yes, I have served before',
                          ),
                          selected: _hasMinistryExperience,
                          onTap:
                              () =>
                                  setState(() => _hasMinistryExperience = true),
                        ),
                        const SizedBox(height: 10),
                        _ExperienceOption(
                          label: fhcT(
                            context,
                            'homeChurch.newToMinistry',
                            fallback: "No, I'm new to ministry",
                          ),
                          selected: !_hasMinistryExperience,
                          onTap:
                              () => setState(
                                () => _hasMinistryExperience = false,
                              ),
                        ),
                        const SizedBox(height: 18),
                        _HearDropdown(
                          value: _heardFrom,
                          options: _hearOptions,
                          optionLabel: (value) => _hearLabel(context, value),
                          onChanged:
                              (value) => setState(() => _heardFrom = value),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(child: _BackButton(onPressed: _pop)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FhcPrimaryButton(
                                label: fhcT(
                                  context,
                                  'common.continue',
                                  fallback: 'Continue',
                                ),
                                onPressed: _continue,
                              ),
                            ),
                          ],
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
  const _StepBanner({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: FhcColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            fhcT(
              context,
              'homeChurch.stepOf',
              args: {'current': '$step', 'total': '4'},
              fallback: 'Step {current} of {total}',
            ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: FhcColors.muted,
            ),
          ),
        ),
        const Expanded(child: Divider(color: FhcColors.border, height: 1)),
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

class _WhyField extends StatelessWidget {
  const _WhyField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fhcT(
            context,
            'homeChurch.whyStart',
            fallback: 'Why do you want to start a home church?',
          ),
          style: FhcTypography.label,
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          minLines: 5,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          style: FhcTypography.body,
          decoration: InputDecoration(
            hintText: fhcT(
              context,
              'homeChurch.whyStartHint',
              fallback: 'Share why you want to start gathering in your home…',
            ),
            hintStyle: FhcTypography.hint,
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: FhcColors.border),
              borderRadius: radius,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: FhcColors.border),
              borderRadius: radius,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: FhcColors.green, width: 1.5),
              borderRadius: radius,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExperienceOption extends StatelessWidget {
  const _ExperienceOption({
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
        borderRadius: BorderRadius.circular(FhcRadius.field),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? FhcColors.green : Colors.transparent,
                  border: Border.all(
                    color: selected ? FhcColors.green : FhcColors.border,
                    width: 1.6,
                  ),
                ),
                child:
                    selected
                        ? const Icon(
                          Icons.check,
                          size: 14,
                          color: FhcColors.white,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: FhcColors.ink,
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

class _HearDropdown extends StatelessWidget {
  const _HearDropdown({
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final String Function(String value) optionLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fhcT(
            context,
            'homeChurch.howDidYouHear',
            fallback: 'How did you hear about Family House?',
          ),
          style: FhcTypography.label,
        ),
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
                  DropdownMenuItem<String>(
                    value: option,
                    child: Text(optionLabel(option)),
                  ),
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: FhcSizes.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: FhcColors.ink,
          side: const BorderSide(color: FhcColors.border),
          minimumSize: const Size(double.infinity, FhcSizes.buttonHeight),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FhcRadius.button),
          ),
        ),
        child: Text(
          fhcT(context, 'common.back', fallback: 'Back'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class StartHomeChurchStep4Screen extends StatefulWidget {
  const StartHomeChurchStep4Screen({super.key});

  @override
  State<StartHomeChurchStep4Screen> createState() =>
      _StartHomeChurchStep4ScreenState();
}

class _StartHomeChurchStep4ScreenState
    extends State<StartHomeChurchStep4Screen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  final List<bool> _commitments = [true, true, true];

  static const _commitmentCopy = <String>[
    'I will follow the guidelines and doctrine of Family House.',
    'I will pray and disciple others.',
    'I will submit regular reports and remain accountable.',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Chibuikem Beloved');
    _phoneController = TextEditingController(text: '+234 802 123 4567');
    _emailController = TextEditingController(text: 'chibuikem@example.com');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _popBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      fhcGo(context, FhcRoutes.homeChurchStart3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(title: 'Start a Church in Your Home', onBack: _popBack),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _StepBanner(),
                        const SizedBox(height: 10),
                        const _StepProgress(step: 4),
                        const SizedBox(height: 22),
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: FhcColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FhcField(
                          label: 'Full Name',
                          hint: 'Your full name',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 14),
                        FhcField(
                          label: 'Phone',
                          hint: '+234 000 000 0000',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        FhcField(
                          label: 'Email',
                          hint: 'you@example.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Ministry Commitment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: FhcColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < _commitmentCopy.length; i++)
                          _CommitmentTile(
                            label: _commitmentCopy[i],
                            checked: _commitments[i],
                            onTap:
                                () => setState(
                                  () => _commitments[i] = !_commitments[i],
                                ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                SizedBox(
                  height: FhcSizes.buttonHeight,
                  child: OutlinedButton(
                    onPressed: _popBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FhcColors.ink,
                      side: const BorderSide(color: FhcColors.border),
                      minimumSize: const Size(88, FhcSizes.buttonHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FhcRadius.button),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FhcPrimaryButton(
                    label: 'Submit Application',
                    onPressed:
                        () => fhcPush(context, FhcRoutes.homeChurchProgress),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Your application will be reviewed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: FhcColors.muted,
              ),
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
            'Step 4 of 4',
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

class _CommitmentTile extends StatelessWidget {
  const _CommitmentTile({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  checked ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 22,
                  color: checked ? FhcColors.green : FhcColors.hint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: FhcColors.ink,
                      ),
                    ),
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

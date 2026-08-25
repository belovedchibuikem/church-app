import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class StartHomeChurchProgressScreen extends StatelessWidget {
  const StartHomeChurchProgressScreen({super.key});

  static const _currentStep = 2;
  static const _totalSteps = 5;

  static const _steps = <_ProgressStep>[
    _ProgressStep(
      number: 1,
      title: 'Application Submitted',
      state: _StepState.done,
    ),
    _ProgressStep(
      number: 2,
      title: 'Interview / Orientation',
      state: _StepState.current,
    ),
    _ProgressStep(
      number: 3,
      title: 'Review & Approval',
      state: _StepState.pending,
    ),
    _ProgressStep(
      number: 4,
      title: 'Home Church ID',
      state: _StepState.pending,
    ),
    _ProgressStep(
      number: 5,
      title: 'Activation & Training',
      state: _StepState.pending,
    ),
  ];

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.homeChurchStart2);
    }
  }

  void _viewApplication(BuildContext context) {
    fhcPush(context, FhcRoutes.homeChurchApplications);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(title: '', onBack: () => _onBack(context)),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                const Text(
                  'START A CHURCH IN YOUR HOME',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: FhcColors.greenDark,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Application Progress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Text(
                      'Step $_currentStep of $_totalSteps',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FhcColors.muted,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _ProgressTrack(
                        current: _currentStep,
                        total: _totalSteps,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                for (var i = 0; i < _steps.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  _StepRow(step: _steps[i]),
                ],
                const SizedBox(height: 18),
                const _ReviewInfoBox(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FhcPrimaryButton(
              label: 'View Application',
              onPressed: () => _viewApplication(context),
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

enum _StepState { done, current, pending }

class _ProgressStep {
  const _ProgressStep({
    required this.number,
    required this.title,
    required this.state,
  });

  final int number;
  final String title;
  final _StepState state;
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            _TrackDot(filled: i < current, current: i == current - 1),
            if (i < total - 1)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < current - 1 ? FhcColors.green : FhcColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TrackDot extends StatelessWidget {
  const _TrackDot({required this.filled, required this.current});

  final bool filled;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final size = current ? 14.0 : 10.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? FhcColors.green : FhcColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? FhcColors.green : FhcColors.border,
          width: current ? 0 : 1.5,
        ),
      ),
      child:
          current
              ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: FhcColors.white,
                  shape: BoxShape.circle,
                ),
              )
              : null,
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final _ProgressStep step;

  @override
  Widget build(BuildContext context) {
    final pending = step.state == _StepState.pending;
    final current = step.state == _StepState.current;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _StepBadge(step: step),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                  height: 1.25,
                  color:
                      current
                          ? FhcColors.greenDark
                          : pending
                          ? FhcColors.muted
                          : FhcColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (step.state == _StepState.done)
              const Icon(Icons.check_circle, size: 20, color: FhcColors.green)
            else
              Text(
                'Pending',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: current ? FhcColors.muted : FhcColors.hint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.step});

  final _ProgressStep step;

  @override
  Widget build(BuildContext context) {
    final current = step.state == _StepState.current;

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: current ? FhcColors.green : FhcColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: current ? FhcColors.green : FhcColors.border,
          width: current ? 0 : 1.5,
        ),
      ),
      child: Text(
        '${step.number}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
          color: current ? FhcColors.white : FhcColors.hint,
        ),
      ),
    );
  }
}

class _ReviewInfoBox extends StatelessWidget {
  const _ReviewInfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: FhcColors.mint,
        borderRadius: BorderRadius.circular(FhcRadius.md),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: FhcColors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: FhcColors.green,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Our team is reviewing your application. You will be notified soon.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: FhcColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

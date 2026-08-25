import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class HomeChurchApplicationsScreen extends StatefulWidget {
  const HomeChurchApplicationsScreen({super.key});

  @override
  State<HomeChurchApplicationsScreen> createState() =>
      _HomeChurchApplicationsScreenState();
}

class _HomeChurchApplicationsScreenState
    extends State<HomeChurchApplicationsScreen> {
  int _tab = 0;

  static const _tabs = <String>['Home Church', 'Other Requests'];

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    fhcGo(context, FhcRoutes.homeChurch);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(title: 'My Applications', onBack: _goBack),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _AppTab(
                      label: _tabs[i],
                      active: i == _tab,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child:
                _tab == 0 ? const _HomeChurchTab() : const _OtherRequestsTab(),
          ),
          FhcBottomNavigation(
            selected: 0,
            onSelected: (i) => fhcTab(context, i),
          ),
        ],
      ),
    );
  }
}

class _AppTab extends StatelessWidget {
  const _AppTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? FhcColors.green : FhcColors.border,
                width: active ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: active ? FhcColors.green : FhcColors.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeChurchTab extends StatelessWidget {
  const _HomeChurchTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: const [_ApplicationCard()],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard();

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FhcCircleIcon(icon: Icons.home_work_outlined, size: 40),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: FhcColors.muted,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '#HC-2025-0456',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: FhcColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Under Review',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Next step',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: FhcColors.muted, height: 1.2),
          ),
          const SizedBox(height: 3),
          const Text(
            'Interview',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const _ProgressTimeline(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: FhcColors.green,
                foregroundColor: FhcColors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: const Size(0, 40),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.button),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressTimeline extends StatelessWidget {
  const _ProgressTimeline();

  static const _steps = <(String, _StepState)>[
    ('Submitted', _StepState.done),
    ('Under Review', _StepState.current),
    ('Interview', _StepState.upcoming),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 22,
          child: Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                _StepDot(state: _steps[i].$2),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color:
                          _steps[i].$2 == _StepState.done
                              ? FhcColors.green
                              : FhcColors.border,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < _steps.length; i++)
              Expanded(
                child: Text(
                  _steps[i].$1,
                  textAlign:
                      i == 0
                          ? TextAlign.left
                          : i == _steps.length - 1
                          ? TextAlign.right
                          : TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        _steps[i].$2 == _StepState.upcoming
                            ? FontWeight.w500
                            : FontWeight.w700,
                    color: switch (_steps[i].$2) {
                      _StepState.done => FhcColors.green,
                      _StepState.current => FhcColors.ink,
                      _StepState.upcoming => FhcColors.muted,
                    },
                    height: 1.2,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

enum _StepState { done, current, upcoming }

class _StepDot extends StatelessWidget {
  const _StepDot({required this.state});

  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => FhcColors.green,
      _StepState.current => FhcColors.gold,
      _StepState.upcoming => FhcColors.border,
    };

    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: state == _StepState.upcoming ? FhcColors.white : color,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: state == _StepState.upcoming ? 2 : 0,
        ),
      ),
      child:
          state == _StepState.done
              ? const Icon(Icons.check, size: 11, color: FhcColors.white)
              : state == _StepState.current
              ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: FhcColors.white,
                  shape: BoxShape.circle,
                ),
              )
              : null,
    );
  }
}

class _OtherRequestsTab extends StatelessWidget {
  const _OtherRequestsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FhcCircleIcon(icon: Icons.inbox_outlined, size: 56),
            SizedBox(height: 14),
            Text(
              'No other requests',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
                height: 1.2,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Membership and ministry requests will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: FhcColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

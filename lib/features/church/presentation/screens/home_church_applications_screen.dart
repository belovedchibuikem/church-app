import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/home_church_repository.dart';

class HomeChurchApplicationsScreen extends StatefulWidget {
  const HomeChurchApplicationsScreen({super.key});

  @override
  State<HomeChurchApplicationsScreen> createState() =>
      _HomeChurchApplicationsScreenState();
}

class _HomeChurchApplicationsScreenState
    extends State<HomeChurchApplicationsScreen> {
  int _tab = 0;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    fhcGo(context, FhcRoutes.homeChurch);
  }

  @override
  Widget build(BuildContext context) {
    final draft = HomeChurchApplicationSession.draft;
    final hasLocalSubmission =
        draft.lastApplicationId != null && draft.lastApplicationId!.isNotEmpty;
    final showFixtures =
        AppServicesScope.maybeOf(context)?.showUnboundFixtures ?? false;
    final tabs = <String>[
      fhcT(context, 'homeChurch.tabHomeChurch', fallback: 'Home Church'),
      fhcT(context, 'homeChurch.tabOtherRequests', fallback: 'Other Requests'),
    ];

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'homeChurch.myApplications',
              fallback: 'My Applications',
            ),
            onBack: _goBack,
          ),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _AppTab(
                      label: tabs[i],
                      active: i == _tab,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? _HomeChurchTab(
                    applicationId: draft.lastApplicationId,
                    status: draft.lastStatus,
                    hasLocalSubmission: hasLocalSubmission,
                    showFixtures: showFixtures,
                  )
                : _OtherRequestsTab(showFixtures: showFixtures),
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
  const _HomeChurchTab({
    required this.hasLocalSubmission,
    required this.showFixtures,
    this.applicationId,
    this.status,
  });

  final bool hasLocalSubmission;
  final bool showFixtures;
  final String? applicationId;
  final String? status;

  @override
  Widget build(BuildContext context) {
    if (!hasLocalSubmission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FhcUnavailableState(
                title: fhcT(
                  context,
                  'homeChurch.noApplicationsToList',
                  fallback: 'No applications to list',
                ),
                message: fhcT(
                  context,
                  'homeChurch.noApplicationsMessage',
                  fallback:
                      'There is no public or /user list API for home-church '
                      'applications. Only the latest submit receipt stored on '
                      'this device can be shown after you apply.',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton(
                  onPressed: () => fhcPush(context, FhcRoutes.homeChurchStart),
                  child: Text(
                    fhcT(
                      context,
                      'homeChurch.startApplication',
                      fallback: 'Start application',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        _ApplicationCard(
          applicationId: applicationId!,
          status: status ?? 'draft',
        ),
        if (!showFixtures) ...[
          const SizedBox(height: 12),
          Text(
            fhcT(
              context,
              'homeChurch.historyNotAvailable',
              fallback:
                  'Server-side application history is not available yet. '
                  'This card is the latest public submit receipt on this device.',
            ),
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              color: FhcColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.applicationId,
    required this.status,
  });

  final String applicationId;
  final String status;

  @override
  Widget build(BuildContext context) {
    final statusLabel = fhcT(
      context,
      'homeChurch.status.$status',
      fallback: status.replaceAll('_', ' '),
    );

    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FhcCircleIcon(icon: Icons.home_work_outlined, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fhcT(
                        context,
                        'homeChurch.applicationLabel',
                        fallback: 'Application',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: FhcColors.muted,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      applicationId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
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
                child: Text(
                  statusLabel,
                  style: const TextStyle(
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
          Text(
            fhcT(
              context,
              'homeChurch.latestServerResponse',
              fallback: 'Latest server response',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: FhcColors.muted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            fhcT(
              context,
              'homeChurch.storedFromSubmit',
              fallback:
                  'Stored from the most recent public submit on this device. A list API is not available.',
            ),
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: FhcColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton(
              onPressed: () => fhcPush(context, FhcRoutes.homeChurchProgress),
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
              child: Text(
                fhcT(
                  context,
                  'homeChurch.viewDetails',
                  fallback: 'View Details',
                ),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () => fhcPush(context, FhcRoutes.homeChurchStart),
              child: Text(
                fhcT(
                  context,
                  'homeChurch.startAnother',
                  fallback: 'Start another application',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherRequestsTab extends StatelessWidget {
  const _OtherRequestsTab({required this.showFixtures});

  final bool showFixtures;

  @override
  Widget build(BuildContext context) {
    if (!showFixtures) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: FhcUnavailableState(
          title: fhcT(
            context,
            'homeChurch.otherRequestsUnavailable',
            fallback: 'Other requests unavailable',
          ),
          message: fhcT(
            context,
            'homeChurch.otherRequestsUnavailableMessage',
            fallback:
                'Membership and ministry request lists have no public or '
                '/user Laravel endpoints yet. Fixture rows are hidden.',
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FhcCircleIcon(icon: Icons.inbox_outlined, size: 56),
            const SizedBox(height: 14),
            Text(
              fhcT(
                context,
                'homeChurch.noOtherRequests',
                fallback: 'No other requests',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fhcT(
                context,
                'homeChurch.noOtherRequestsCopy',
                fallback:
                    'Membership and ministry requests will appear here when those APIs are available.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
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

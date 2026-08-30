import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../../mission/data/mission_repository.dart';

class MissionDashboardScreen extends StatefulWidget {
  const MissionDashboardScreen({super.key, this.missionRepository});

  final MissionRepository? missionRepository;

  @override
  State<MissionDashboardScreen> createState() => _MissionDashboardScreenState();
}

class _MissionDashboardScreenState extends State<MissionDashboardScreen> {
  FhcAsyncValue<_MissionDash> _state = const FhcAsyncValue.loading();
  bool _started = false;

  MissionRepository? get _repo =>
      widget.missionRepository ??
      AppServicesScope.maybeOf(context)?.missionRepository;

  bool get _showFixtures =>
      AppServicesScope.maybeOf(context)?.showUnboundFixtures ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_showFixtures || _started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'mission.dashboardRequiresCatalogue',
            fallback:
                'Mission dashboard requires the public crusade catalogue. '
                'No design fixtures are shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.getCrusades(const {});
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        setState(() => _state = FhcAsyncValue.data(_MissionDash(crusades: value)));
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showFixtures) {
      return const _MissionDashboardFixtureView();
    }

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      darkStatusBar: true,
      statusBarColor: FhcColors.navy,
      child: Column(
        children: [
          Expanded(
            child: FhcAsyncBody<_MissionDash>(
              value: _state,
              onRetry: _load,
              unavailableTitle: fhcT(
                context,
                'mission.dashboardUnavailable',
                fallback: 'Mission dashboard unavailable',
              ),
              emptyTitle: fhcT(
                context,
                'mission.noCrusadesYet',
                fallback: 'No crusades yet',
              ),
              builder: (context, dash) => _MissionDashboardLiveView(dash: dash),
            ),
          ),
          FhcBottomNavigation(
            selected: 1,
            onSelected: (i) => fhcTab(context, i),
          ),
        ],
      ),
    );
  }
}

class _MissionDash {
  const _MissionDash({required this.crusades});

  final List<JsonObject> crusades;

  int get activeCrusades => crusades.length;

  JsonObject? get featured => crusades.isEmpty ? null : crusades.first;
}

class _MissionDashboardLiveView extends StatefulWidget {
  const _MissionDashboardLiveView({required this.dash});

  final _MissionDash dash;

  @override
  State<_MissionDashboardLiveView> createState() =>
      _MissionDashboardLiveViewState();
}

class _MissionDashboardLiveViewState extends State<_MissionDashboardLiveView> {
  int _tab = 0;
  List<JsonObject>? _souls;
  String? _soulsError;
  bool _soulsLoading = false;

  _MissionDash get dash => widget.dash;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _ensureSouls() async {
    if (_souls != null || _soulsLoading) return;
    final repo = AppServicesScope.maybeOf(context)?.missionRepository;
    if (repo is! HttpMissionRepository) {
      setState(() {
        _soulsError = fhcT(
          context,
          'mission.soulsRequireAuth',
          fallback:
              'Sign in with mission permissions to load soul journeys.',
        );
      });
      return;
    }
    setState(() {
      _soulsLoading = true;
      _soulsError = null;
    });
    final result = await repo.listSouls(const {'per_page': '40'});
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _souls = value;
          _soulsLoading = false;
        });
      case AppError(:final failure):
        setState(() {
          _soulsError = failure.message;
          _soulsLoading = false;
        });
    }
  }

  void _onTab(int index) {
    setState(() => _tab = index);
    if (index == 1) {
      _ensureSouls();
    }
  }

  @override
  Widget build(BuildContext context) {
    final featured = dash.featured;
    final featuredName =
        (featured?['name'] as String?)?.trim().isNotEmpty == true
            ? (featured!['name'] as String).trim()
            : fhcT(context, 'nav.mission', fallback: 'Mission');
    final featuredLocation = featured != null && featured['location'] is Map
        ? Map<String, Object?>.from(
            (featured['location'] as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
        : null;
    final featuredSubtitle = featured == null
        ? fhcT(
            context,
            'mission.publishedCrusades',
            fallback: 'Published crusades from the public catalogue',
          )
        : '${formatMissionDateRange(startsAt: featured['starts_at'] as String?, endsAt: featured['ends_at'] as String?)} • ${formatMissionLocation(featuredLocation)}';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _LiveMissionHeader(
            title: featuredName,
            subtitle: featuredSubtitle,
            onTitleTap: featured == null
                ? null
                : () {
                    final id = (featured['id'] as String?)?.trim();
                    if (id != null && id.isNotEmpty) {
                      fhcPush(context, '${FhcRoutes.crusade}/$id');
                    } else {
                      fhcPush(context, FhcRoutes.crusade);
                    }
                  },
          ),
        ),
        SliverToBoxAdapter(
          child: _MissionTabs(active: _tab, onSelected: _onTab),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          sliver: SliverList.list(
            children: switch (_tab) {
              1 => _soulsTab(context),
              2 => _scheduleTab(context),
              3 => _teamTab(context),
              _ => _overviewTab(context),
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _overviewTab(BuildContext context) {
    return [
      Row(
        children: [
          Expanded(
            child: _MissionMetric(
              label: fhcT(
                context,
                'mission.activeCrusades',
                fallback: 'Active Crusades',
              ),
              value: '${dash.activeCrusades}',
              note: fhcT(
                context,
                'mission.publicCatalogue',
                fallback: 'Public catalogue',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        fhcT(context, 'mission.quickActions', fallback: 'Quick Actions'),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: FhcColors.ink,
        ),
      ),
      const SizedBox(height: 9),
      Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.person_add_alt,
              label: fhcT(context, 'mission.addSoul', fallback: 'Add Soul'),
              onTap: () => fhcPush(context, FhcRoutes.soulAdd),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _QuickAction(
              icon: Icons.waving_hand_outlined,
              label: fhcT(context, 'mission.followUp', fallback: 'Follow-up'),
              onTap: () => fhcPush(context, FhcRoutes.souls),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _QuickAction(
              icon: Icons.groups_outlined,
              label: fhcT(context, 'mission.mentors', fallback: 'Mentors'),
              onTap: () => fhcPush(context, FhcRoutes.mentorAssignment),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _QuickAction(
              icon: Icons.description_outlined,
              label: fhcT(context, 'mission.reports', fallback: 'Reports'),
              onTap: () => fhcPush(context, FhcRoutes.missionPartners),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        fhcT(context, 'mission.recentCrusades', fallback: 'Recent Crusades'),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: FhcColors.ink,
        ),
      ),
      const SizedBox(height: 8),
      if (dash.crusades.isEmpty)
        FhcSurfaceCard(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          child: Text(
            fhcT(
              context,
              'mission.noPublishedCrusades',
              fallback: 'No published crusades in the public catalogue.',
            ),
            style: const TextStyle(fontSize: 12, color: FhcColors.muted),
          ),
        )
      else
        FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (var i = 0; i < dash.crusades.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: FhcColors.border),
                _LiveCrusadeRow(crusade: dash.crusades[i]),
              ],
            ],
          ),
        ),
    ];
  }

  List<Widget> _soulsTab(BuildContext context) {
    if (_soulsLoading) {
      return const [
        SizedBox(height: 48, child: Center(child: CircularProgressIndicator.adaptive())),
      ];
    }
    if (_soulsError != null) {
      return [
        FhcSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fhcT(context, 'mission.souls', fallback: 'Souls'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _soulsError!,
                style: const TextStyle(fontSize: 12, color: FhcColors.muted),
              ),
              const SizedBox(height: 12),
              FhcPrimaryButton(
                label: fhcT(
                  context,
                  'mission.openFollowUp',
                  fallback: 'Open follow-up list',
                ),
                onPressed: () => fhcPush(context, FhcRoutes.souls),
              ),
            ],
          ),
        ),
      ];
    }
    final souls = _souls ?? const <JsonObject>[];
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              fhcT(
                context,
                'mission.soulJourneys',
                fallback: 'Soul journeys',
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
              ),
            ),
          ),
          TextButton(
            onPressed: () => fhcPush(context, FhcRoutes.souls),
            child: Text(fhcT(context, 'common.viewAll', fallback: 'View all')),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (souls.isEmpty)
        FhcSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fhcT(
                  context,
                  'mission.noSoulsYet',
                  fallback: 'No soul journeys yet',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fhcT(
                  context,
                  'mission.noSoulsYetCopy',
                  fallback:
                      'Capture a new soul against a published crusade to start follow-up.',
                ),
                style: const TextStyle(fontSize: 12, color: FhcColors.muted),
              ),
              const SizedBox(height: 12),
              FhcPrimaryButton(
                label: fhcT(context, 'mission.addSoul', fallback: 'Add Soul'),
                onPressed: () => fhcPush(context, FhcRoutes.soulAdd),
              ),
            ],
          ),
        )
      else
        FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (var i = 0; i < souls.length && i < 12; i++) ...[
                if (i > 0) const Divider(height: 1, color: FhcColors.border),
                _SoulSummaryRow(soul: souls[i]),
              ],
            ],
          ),
        ),
      const SizedBox(height: 12),
      FhcPrimaryButton(
        label: fhcT(context, 'mission.addSoul', fallback: 'Add Soul'),
        onPressed: () => fhcPush(context, FhcRoutes.soulAdd),
      ),
    ];
  }

  List<Widget> _scheduleTab(BuildContext context) {
    final crusades = dash.crusades;
    return [
      Text(
        fhcT(context, 'mission.upcomingSchedule', fallback: 'Upcoming schedule'),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: FhcColors.ink,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        fhcT(
          context,
          'mission.scheduleFromCatalogue',
          fallback:
              'Dates and venues from published crusades. Day-by-day agendas appear when organizers publish them.',
        ),
        style: const TextStyle(fontSize: 12, color: FhcColors.muted),
      ),
      const SizedBox(height: 12),
      if (crusades.isEmpty)
        FhcSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Text(
            fhcT(
              context,
              'mission.noScheduleYet',
              fallback: 'No crusade dates are published yet.',
            ),
            style: const TextStyle(fontSize: 12, color: FhcColors.muted),
          ),
        )
      else
        FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (var i = 0; i < crusades.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: FhcColors.border),
                _ScheduleRow(crusade: crusades[i]),
              ],
            ],
          ),
        ),
    ];
  }

  List<Widget> _teamTab(BuildContext context) {
    return [
      Text(
        fhcT(context, 'mission.teamAndSupport', fallback: 'Team & support'),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: FhcColors.ink,
        ),
      ),
      const SizedBox(height: 8),
      FhcSurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _TeamLinkRow(
              icon: Icons.groups_outlined,
              title: fhcT(
                context,
                'mission.mentorAssignment',
                fallback: 'Mentor assignment',
              ),
              subtitle: fhcT(
                context,
                'mission.mentorAssignmentCopy',
                fallback: 'Assign mentors to soul journeys',
              ),
              onTap: () => fhcPush(context, FhcRoutes.mentorAssignment),
            ),
            const Divider(height: 1),
            _TeamLinkRow(
              icon: Icons.handshake_outlined,
              title: fhcT(context, 'mission.teams', fallback: 'Mission teams'),
              subtitle: fhcT(
                context,
                'mission.teamsCopy',
                fallback: 'Volunteer teams and field assignments',
              ),
              onTap: () => fhcPush(context, FhcRoutes.missionTeams),
            ),
            const Divider(height: 1),
            _TeamLinkRow(
              icon: Icons.mail_outline,
              title: fhcT(
                context,
                'mission.invitations',
                fallback: 'Invitations',
              ),
              subtitle: fhcT(
                context,
                'mission.invitationsCopy',
                fallback: 'Invite partners and responders',
              ),
              onTap: () => fhcPush(context, FhcRoutes.missionInvite),
            ),
            const Divider(height: 1),
            _TeamLinkRow(
              icon: Icons.public_outlined,
              title: fhcT(
                context,
                'mission.partners',
                fallback: 'Mission partners',
              ),
              subtitle: fhcT(
                context,
                'mission.partnersCopy',
                fallback: 'Partner network and support',
              ),
              onTap: () => fhcPush(context, FhcRoutes.missionPartners),
            ),
          ],
        ),
      ),
    ];
  }
}

class _SoulSummaryRow extends StatelessWidget {
  const _SoulSummaryRow({required this.soul});

  final JsonObject soul;

  @override
  Widget build(BuildContext context) {
    final status = (soul['status'] as String?)?.trim() ??
        (soul['journey_status'] as String?)?.trim() ??
        'Open';
    final person = soul['person'];
    String title = (soul['person_id'] as String?)?.trim() ??
        fhcT(context, 'mission.soul', fallback: 'Soul');
    if (person is Map) {
      final given = person['given_name'] as String?;
      final family = person['family_name'] as String?;
      final parts = [
        if (given != null && given.isNotEmpty) given,
        if (family != null && family.isNotEmpty) family,
      ];
      if (parts.isNotEmpty) title = parts.join(' ');
    }
    final crusade = soul['crusade'];
    final subtitle = crusade is Map
        ? '${crusade['name'] ?? ''}'.trim()
        : (soul['crusade_id'] as String?)?.trim() ?? '';

    return InkWell(
      onTap: () => fhcPush(context, FhcRoutes.souls),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FhcColors.mint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.person_outline, color: FhcColors.green, size: 20),
            ),
            const SizedBox(width: 10),
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
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: FhcColors.muted),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: FhcColors.mint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.crusade});

  final JsonObject crusade;

  @override
  Widget build(BuildContext context) {
    final name = (crusade['name'] as String?)?.trim() ??
        fhcT(context, 'mission.crusade', fallback: 'Crusade');
    final location = crusade['location'] is Map
        ? Map<String, Object?>.from(
            (crusade['location'] as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
        : null;
    final dates = formatMissionDateRange(
      startsAt: crusade['starts_at'] as String?,
      endsAt: crusade['ends_at'] as String?,
    );
    final place = formatMissionLocation(location);
    final id = (crusade['id'] as String?)?.trim();

    return InkWell(
      onTap: () {
        if (id != null && id.isNotEmpty) {
          fhcPush(context, '${FhcRoutes.crusade}/$id');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, color: FhcColors.green, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                    ),
                  ),
                  Text(
                    '$dates · $place',
                    style: const TextStyle(fontSize: 11, color: FhcColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FhcColors.muted),
          ],
        ),
      ),
    );
  }
}

class _TeamLinkRow extends StatelessWidget {
  const _TeamLinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: FhcColors.green, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: FhcColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: FhcColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FhcColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LiveMissionHeader extends StatelessWidget {
  const _LiveMissionHeader({
    required this.title,
    required this.subtitle,
    this.onTitleTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FhcColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fhcT(context, 'nav.mission', fallback: 'Mission')
                      .toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => fhcPush(context, FhcRoutes.notifications),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: fhcT(
                  context,
                  'common.notifications',
                  fallback: 'Notifications',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTitleTap ?? () => fhcPush(context, FhcRoutes.crusade),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCrusadeRow extends StatelessWidget {
  const _LiveCrusadeRow({required this.crusade});

  final JsonObject crusade;

  @override
  Widget build(BuildContext context) {
    final name = (crusade['name'] as String?)?.trim();
    final location = crusade['location'] is Map
        ? Map<String, Object?>.from(
            (crusade['location'] as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
        : null;
    final subtitle =
        '${formatMissionDateRange(startsAt: crusade['starts_at'] as String?, endsAt: crusade['ends_at'] as String?)} • ${formatMissionLocation(location)}';
    final id = (crusade['id'] as String?)?.trim();

    return _CrusadeRow(
      title: (name == null || name.isEmpty)
          ? fhcT(context, 'mission.crusade', fallback: 'Crusade')
          : name,
      subtitle: subtitle,
      value: '',
      imageAsset: 'assets/images/mission_banner.png',
      onTap: () {
        if (id != null && id.isNotEmpty) {
          fhcPush(context, '${FhcRoutes.crusade}/$id');
        } else {
          fhcPush(context, FhcRoutes.crusade);
        }
      },
    );
  }
}

class _MissionDashboardFixtureView extends StatelessWidget {
  const _MissionDashboardFixtureView();

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      darkStatusBar: true,
      statusBarColor: FhcColors.navy,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _MissionHeader()),
                SliverToBoxAdapter(
                  child: _MissionTabs(
                    onSelected: (index) {
                      if (index == 1) {
                        fhcPush(context, FhcRoutes.souls);
                      } else if (index == 2) {
                        fhcPush(context, FhcRoutes.crusade);
                      } else if (index == 3) {
                        fhcPush(context, FhcRoutes.mentorAssignment);
                      }
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MissionMetric(
                              label: fhcT(
                                context,
                                'mission.activeCrusades',
                                fallback: 'Active Crusades',
                              ),
                              value: '8',
                              note: fhcT(
                                context,
                                'mission.thisMonth',
                                fallback: 'This Month',
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _MissionMetric(
                              label: fhcT(
                                context,
                                'mission.mentors',
                                fallback: 'Mentors',
                              ),
                              value: '12',
                              note: fhcT(
                                context,
                                'mission.active',
                                fallback: 'Active',
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _MissionMetric(
                              label: fhcT(
                                context,
                                'mission.followUps',
                                fallback: 'Follow-ups',
                              ),
                              value: '254',
                              note: fhcT(
                                context,
                                'mission.ongoing',
                                fallback: 'Ongoing',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fhcT(
                          context,
                          'mission.quickActions',
                          fallback: 'Quick Actions',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.person_add_alt,
                              label: fhcT(
                                context,
                                'mission.addSoul',
                                fallback: 'Add Soul',
                              ),
                              onTap: () => fhcPush(context, FhcRoutes.soulAdd),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.waving_hand_outlined,
                              label: fhcT(
                                context,
                                'mission.followUp',
                                fallback: 'Follow-up',
                              ),
                              onTap: () => fhcPush(context, FhcRoutes.souls),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.groups_outlined,
                              label: fhcT(
                                context,
                                'mission.mentors',
                                fallback: 'Mentors',
                              ),
                              onTap: () => fhcPush(
                                context,
                                FhcRoutes.mentorAssignment,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.description_outlined,
                              label: fhcT(
                                context,
                                'mission.reports',
                                fallback: 'Reports',
                              ),
                              onTap: () => fhcPush(
                                context,
                                FhcRoutes.missionPartners,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fhcT(
                          context,
                          'mission.recentCrusades',
                          fallback: 'Recent Crusades',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FhcSurfaceCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            _CrusadeRow(
                              title: 'Lagos Outreach Crusade',
                              subtitle: 'May 29 – Jun 1, 2025 • Lagos',
                              value: '1,250 Souls',
                              imageAsset:
                                  'assets/images/mission_lagos_thumb.png',
                              onTap: () => fhcPush(context, FhcRoutes.crusade),
                            ),
                            const Divider(height: 1, color: FhcColors.border),
                            _CrusadeRow(
                              title: 'Abuja City Crusade',
                              subtitle: 'May 20, 2025 • Abuja',
                              value: '86 Souls',
                              imageAsset: 'assets/images/mission_banner.png',
                              onTap: () => fhcPush(context, FhcRoutes.crusade),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FhcBottomNavigation(
            selected: 1,
            onSelected: (i) => fhcTab(context, i),
          ),
        ],
      ),
    );
  }
}

class _MissionHeader extends StatelessWidget {
  const _MissionHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FhcColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'MISSION',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              _NotificationBell(),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => fhcPush(context, FhcRoutes.crusade),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lagos Outreach Crusade',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'May 29 – Jun 1, 2025 • Lagos, Nigeria',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _HeaderMetric(label: 'Souls Reached', value: '1,250'),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _HeaderMetric(label: 'New Conversions', value: '124'),
              ),
              SizedBox(width: 6),
              Expanded(child: _HeaderMetric(label: 'Volunteers', value: '36')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              color: FhcColors.muted,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_none, color: Colors.white, size: 22),
          Positioned(
            right: 2,
            top: 4,
            child: Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: FhcColors.red,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionTabs extends StatelessWidget {
  const _MissionTabs({this.active = 0, this.onSelected});

  final int active;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = [
      fhcT(context, 'common.overview', fallback: 'Overview'),
      fhcT(context, 'mission.souls', fallback: 'Souls'),
      fhcT(context, 'mission.schedule', fallback: 'Schedule'),
      fhcT(context, 'mission.team', fallback: 'Team'),
    ];
    return ColoredBox(
      color: Colors.white,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _TabLabel(
                labels[i],
                i == active,
                onTap: onSelected == null ? null : () => onSelected!(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel(this.text, this.active, {this.onTap});

  final String text;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: active ? FhcColors.green : FhcColors.ink,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _MissionMetric extends StatelessWidget {
  const _MissionMetric({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              color: FhcColors.muted,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                color: FhcColors.greenDark,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8,
              color: FhcColors.muted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: FhcColors.green, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.ink,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrusadeRow extends StatelessWidget {
  const _CrusadeRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String value;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => ColoredBox(
                        color: FhcColors.mint,
                        child: const Icon(
                          Icons.campaign_outlined,
                          color: FhcColors.green,
                          size: 20,
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: FhcColors.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: FhcColors.green,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

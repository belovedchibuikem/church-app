import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class HomeChurchDashboardScreen extends StatefulWidget {
  const HomeChurchDashboardScreen({
    super.key,
    this.homeChurchId,
    this.repository,
  });

  final String? homeChurchId;
  final HomeChurchRepository? repository;

  @override
  State<HomeChurchDashboardScreen> createState() =>
      _HomeChurchDashboardScreenState();
}

class _HomeChurchDashboardScreenState extends State<HomeChurchDashboardScreen> {
  FhcAsyncValue<_HomeChurchDash> _state = const FhcAsyncValue.loading();
  bool _started = false;
  bool _useFixtures = false;

  HomeChurchRepository? get _repository =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.homeChurchRepository;

  bool get _showUnboundFixtures =>
      AppServicesScope.maybeOf(context)?.showUnboundFixtures ?? false;

  String? _resolveId() {
    final fromProp = widget.homeChurchId?.trim();
    if (fromProp != null && fromProp.isNotEmpty) return fromProp;
    return FhcRouteArgs.entityIdOf(context)?.trim();
  }

  Future<String?> _resolveIdFromMemberships() async {
    final churchRepo = AppServicesScope.maybeOf(context)?.churchRepository;
    if (churchRepo == null) return null;
    final result = await churchRepo.listMemberships();
    if (result case AppSuccess(:final value)) {
      for (final item in value) {
        final id = (item['home_church_id'] as String?)?.trim();
        if (id != null && id.isNotEmpty) return id;
      }
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    var id = _resolveId();
    if (id == null || id.isEmpty) {
      id = await _resolveIdFromMemberships();
    }
    if (id == null || id.isEmpty) {
      if (_showUnboundFixtures) {
        setState(() => _useFixtures = true);
        return;
      }
      setState(() {
        _useFixtures = false;
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'errors.homeChurchIdRequired',
            fallback:
                'No home church is linked to your memberships yet. '
                'Join a church with a home fellowship or start a home church.',
          ),
        );
      });
      return;
    }

    final repo = _repository;
    if (repo == null) {
      if (_showUnboundFixtures) {
        setState(() => _useFixtures = true);
        return;
      }
      setState(() {
        _useFixtures = false;
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'errors.homeChurchDashboardWaiting',
            fallback:
                'Home church dashboard requires AppServices.homeChurchRepository. '
                'No fixture metrics are shown.',
          ),
        );
      });
      return;
    }

    setState(() {
      _useFixtures = false;
      _state = const FhcAsyncValue.loading();
    });

    final result = await repo.getDashboard(id);
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        setState(() => _state = FhcAsyncValue.data(_HomeChurchDash.fromJson(value)));
      case AppError(:final failure):
        if (failure is IntegrationUnavailableFailure) {
          if (_showUnboundFixtures) {
            setState(() => _useFixtures = true);
            return;
          }
          setState(() {
            _state = FhcAsyncValue.unavailable(message: failure.message);
          });
          return;
        }
        if (failure is NotFoundFailure) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'errors.homeChurchNotMember',
                fallback:
                    'This home church is unavailable, or you are not an '
                    'active member or leader.',
              ),
            );
          });
          return;
        }
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  void _onMore(String value) {
    switch (value) {
      case 'settings':
        fhcPush(context, FhcRoutes.churchSettings);
      case 'profile':
        fhcPush(context, FhcRoutes.churchDetail);
    }
  }

  void _pushWithId(String route, {String? id}) {
    final trimmed = (id ?? _resolveId())?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      fhcPush(context, '$route?id=${Uri.encodeQueryComponent(trimmed)}');
    } else {
      fhcPush(context, route);
    }
  }

  void _onQuickAction(_HomeChurchDash? dash, String label) {
    switch (label) {
      case 'Members':
        fhcPush(context, FhcRoutes.homeChurchMembers);
      case 'Attendance':
        fhcPush(context, FhcRoutes.homeChurchAttendance);
      case 'Activities':
        fhcPush(context, FhcRoutes.homeChurchActivities);
      case 'Prayer':
        fhcPush(context, FhcRoutes.prayer);
      case 'Messages':
        fhcPush(context, FhcRoutes.messages);
      case 'Report':
        _pushWithId(FhcRoutes.homeChurchReports, id: dash?.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'homeChurch.myHomeChurch',
              fallback: 'MY HOME CHURCH',
            ),
            onBack: _goBack,
            trailing: PopupMenuButton<String>(
              tooltip: fhcT(context, 'common.more', fallback: 'More'),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, size: 22, color: FhcColors.ink),
              onSelected: _onMore,
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'settings',
                      child: Text(
                        fhcT(
                          context,
                          'common.settings',
                          fallback: 'Settings',
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'profile',
                      child: Text(
                        fhcT(
                          context,
                          'homeChurch.viewProfile',
                          fallback: 'View Profile',
                        ),
                      ),
                    ),
                  ],
            ),
          ),
          Expanded(
            child: _useFixtures
                ? _FixtureDashboardBody(
                    onChurchTap: () => fhcPush(context, FhcRoutes.churchDetail),
                    onReports: () => fhcPush(context, FhcRoutes.homeChurchReports),
                    onQuickAction: (label) => _onQuickAction(null, label),
                    onMeetingTap: () => fhcPush(context, FhcRoutes.eventDetail),
                  )
                : FhcAsyncBody<_HomeChurchDash>(
                    value: _state,
                    onRetry: _load,
                    unavailableTitle: fhcT(
                      context,
                      'errors.homeChurchUnavailable',
                      fallback: 'Home church unavailable',
                    ),
                    emptyTitle: fhcT(
                      context,
                      'errors.homeChurchNotFound',
                      fallback: 'Home church not found',
                    ),
                    builder: (context, dash) {
                      return RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                          children: [
                            _ChurchCard(
                              name: dash.name,
                              subtitle: dash.subtitleOf(context),
                              statusLabel: dash.statusLabelOf(context),
                              onTap: () {
                                final churchId = dash.churchId;
                                if (churchId != null && churchId.isNotEmpty) {
                                  fhcPush(
                                    context,
                                    '/discover/church/${Uri.encodeComponent(churchId)}',
                                  );
                                } else {
                                  fhcPush(context, FhcRoutes.churchDetail);
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            Text(
                              fhcT(
                                context,
                                'homeChurch.thisHomeChurch',
                                fallback: 'This home church',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FhcColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _StatusCard(
                                    label: fhcT(
                                      context,
                                      'homeChurch.membership',
                                      fallback: 'Membership',
                                    ),
                                    value: dash.membershipLabelOf(context),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ReportsDueCard(
                                    countLabel: null,
                                    onView: () => _pushWithId(
                                      FhcRoutes.homeChurchReports,
                                      id: dash.id,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              fhcT(
                                context,
                                'homeChurch.quickActions',
                                fallback: 'Quick Actions',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FhcColors.ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _QuickActionsGrid(
                              onTap: (label) => _onQuickAction(dash, label),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const FhcBottomNavigation(selected: 0),
        ],
      ),
    );
  }
}

class _HomeChurchDash {
  const _HomeChurchDash({
    required this.id,
    required this.name,
    this.churchId,
    this.churchName,
    this.status,
    this.membershipStatus,
  });

  final String id;
  final String name;
  final String? churchId;
  final String? churchName;
  final String? status;
  final String? membershipStatus;

  String subtitleOf(BuildContext context) {
    final church = churchName?.trim();
    if (church != null && church.isNotEmpty) {
      return fhcT(
        context,
        'homeChurch.subtitleWithChurch',
        args: {'church': church},
        fallback: 'Home Church • {church}',
      );
    }
    return fhcT(context, 'member.homeChurch', fallback: 'Home Church');
  }

  String statusLabelOf(BuildContext context) {
    final raw = status?.trim();
    if (raw != null && raw.isNotEmpty) {
      return '${raw[0].toUpperCase()}${raw.substring(1)}';
    }
    return fhcT(context, 'homeChurch.record', fallback: 'Record');
  }

  String membershipLabelOf(BuildContext context) {
    final raw = membershipStatus?.trim();
    if (raw != null && raw.isNotEmpty) {
      return '${raw[0].toUpperCase()}${raw.substring(1)}';
    }
    return fhcT(context, 'homeChurch.leader', fallback: 'Leader');
  }

  factory _HomeChurchDash.fromJson(JsonObject json) {
    String? text(Object? value) {
      if (value == null) return null;
      final trimmed = '$value'.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return _HomeChurchDash(
      id: text(json['id']) ?? '',
      name: text(json['name']) ?? 'Home church',
      churchId: text(json['church_id']),
      churchName: text(json['church_name']),
      status: text(json['status']),
      membershipStatus: text(json['membership_status']),
    );
  }
}

class _FixtureDashboardBody extends StatelessWidget {
  const _FixtureDashboardBody({
    required this.onChurchTap,
    required this.onReports,
    required this.onQuickAction,
    required this.onMeetingTap,
  });

  final VoidCallback onChurchTap;
  final VoidCallback onReports;
  final ValueChanged<String> onQuickAction;
  final VoidCallback onMeetingTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      children: [
        _ChurchCard(onTap: onChurchTap),
        const SizedBox(height: 14),
        Text(
          fhcT(context, 'homeChurch.thisMonth', fallback: 'This Month'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: _AttendanceCard()),
            const SizedBox(width: 8),
            Expanded(child: _ReportsDueCard(onView: onReports)),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          fhcT(context, 'homeChurch.quickActions', fallback: 'Quick Actions'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        _QuickActionsGrid(onTap: onQuickAction),
        const SizedBox(height: 18),
        Text(
          fhcT(
            context,
            'homeChurch.upcomingActivity',
            fallback: 'Upcoming Activity',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        _MeetingCard(onTap: onMeetingTap),
      ],
    );
  }
}

class _ChurchCard extends StatelessWidget {
  const _ChurchCard({
    required this.onTap,
    this.name,
    this.subtitle,
    this.statusLabel,
  });

  final VoidCallback onTap;
  final String? name;
  final String? subtitle;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final title = name ??
        fhcT(
          context,
          'homeChurch.graceHomeChurch',
          fallback: 'Grace Home Church',
        );
    final line = subtitle ??
        fhcT(
          context,
          'homeChurch.graceLocation',
          fallback: 'Home Church • Lagos, Nigeria',
        );
    final badge = statusLabel ??
        fhcT(context, 'homeChurch.active', fallback: 'Active');

    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.card),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                const _AssetPhoto(
                  primary: 'assets/images/grace_home_church.png',
                  fallback: 'assets/images/home_church_grace.png',
                  size: 56,
                  icon: Icons.church_outlined,
                ),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatusBadge(label: badge),
                    ],
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FhcColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label ?? fhcT(context, 'homeChurch.active', fallback: 'Active'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: FhcColors.green,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: FhcColors.muted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
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

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard();

  @override
  Widget build(BuildContext context) {
    return const FhcSurfaceCard(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: FhcColors.muted, height: 1.2),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '23',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6),
              _MiniBars(),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '+12%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: FhcColors.green,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars();

  static const _heights = <double>[8, 12, 16, 20, 26];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _heights.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 4,
              height: _heights[i],
              decoration: BoxDecoration(
                color: FhcColors.green,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportsDueCard extends StatelessWidget {
  const _ReportsDueCard({required this.onView, this.countLabel = '2'});

  final VoidCallback onView;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            countLabel == null ? 'Report' : 'Reports Due',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: FhcColors.muted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 18,
                color: FhcColors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    countLabel ?? 'Submit',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            child: FilledButton(
              onPressed: onView,
              style: FilledButton.styleFrom(
                backgroundColor: FhcColors.green,
                foregroundColor: FhcColors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.button),
                ),
              ),
              child: Text(
                countLabel == null ? 'Write' : 'View',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.onTap});

  final ValueChanged<String> onTap;

  static const _items = <(IconData, String)>[
    (Icons.how_to_reg_outlined, 'Attendance'),
    (Icons.assignment_turned_in_outlined, 'Report'),
    (Icons.groups_outlined, 'Members'),
    (Icons.workspace_premium_outlined, 'Activities'),
    (Icons.volunteer_activism_outlined, 'Prayer'),
    (Icons.forum_outlined, 'Messages'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: _items[i].$1,
                  label: _items[i].$2,
                  onTap: () => onTap(_items[i].$2),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 3; i < 6; i++) ...[
              if (i > 3) const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: _items[i].$1,
                  label: _items[i].$2,
                  onTap: () => onTap(_items[i].$2),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.card),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                children: [
                  Icon(icon, color: FhcColors.green, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: FhcColors.ink,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.card),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                _AssetPhoto(
                  primary: 'assets/images/home_church_meeting.png',
                  fallback: 'assets/images/church_house.png',
                  size: 52,
                  icon: Icons.home_work_outlined,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home Church Meeting',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'May 24, 2025 • 6:00 PM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20, color: FhcColors.hint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetPhoto extends StatelessWidget {
  const _AssetPhoto({
    required this.primary,
    required this.fallback,
    required this.size,
    required this.icon,
  });

  final String primary;
  final String fallback;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FhcRadius.sm),
      child: Image.asset(
        primary,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Image.asset(
              fallback,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => ColoredBox(
                    color: FhcColors.mint,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Icon(
                        icon,
                        color: FhcColors.green,
                        size: size * 0.45,
                      ),
                    ),
                  ),
            ),
      ),
    );
  }
}

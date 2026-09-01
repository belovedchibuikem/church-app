import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchAdminDashboardScreen extends StatefulWidget {
  const ChurchAdminDashboardScreen({super.key, this.profileRepository});

  final ProfileRepository? profileRepository;

  @override
  State<ChurchAdminDashboardScreen> createState() =>
      _ChurchAdminDashboardScreenState();
}

class _ChurchAdminDashboardScreenState
    extends State<ChurchAdminDashboardScreen> {
  FhcAsyncValue<_AdminDash> _state = const FhcAsyncValue.loading();
  bool _started = false;

  ProfileRepository? get _repo =>
      widget.profileRepository ??
      AppServicesScope.maybeOf(context)?.profileRepository;

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
            'errors.churchAdminWaiting',
            fallback:
                'Church admin dashboard requires GET /user/dashboard. '
                'There is no member church-stats endpoint. '
                'No design fixtures are shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.getDashboard();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        setState(() => _state = FhcAsyncValue.data(_AdminDash.fromJson(value)));
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showFixtures) {
      return const _ChurchAdminFixtureView();
    }

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      darkStatusBar: true,
      statusBarColor: FhcColors.greenDeep,
      child: Column(
        children: [
          Expanded(
            child: FhcAsyncBody<_AdminDash>(
              value: _state,
              onRetry: _load,
              unavailableTitle: fhcT(
                context,
                'errors.churchAdminUnavailable',
                fallback: 'Church admin unavailable',
              ),
              emptyTitle: fhcT(
                context,
                'errors.noDashboardData',
                fallback: 'No dashboard data',
              ),
              builder: (context, dash) => _ChurchAdminLiveView(dash: dash),
            ),
          ),
          FhcBottomNavigation(
            selected: 1,
            onSelected: (index) => fhcTab(context, index),
          ),
        ],
      ),
    );
  }
}

class _AdminDash {
  const _AdminDash({
    required this.displayName,
    required this.unreadNotificationCount,
    required this.openPrayerCount,
    required this.upcomingNote,
    required this.recentPaymentIntents,
  });

  factory _AdminDash.fromJson(Map<String, Object?> json) {
    return _AdminDash(
      displayName: _displayName(json['profile']),
      unreadNotificationCount: _asInt(json['unread_notification_count']),
      openPrayerCount: _asInt(json['open_prayer_count']),
      upcomingNote: _asNote(json['upcoming_note']),
      recentPaymentIntents: _asObjectList(json['recent_payment_intents']),
    );
  }

  final String displayName;
  final int unreadNotificationCount;
  final int openPrayerCount;
  final String? upcomingNote;
  final List<JsonObject> recentPaymentIntents;

  static String _displayName(Object? profileNode) {
    if (profileNode is! Map) return '';
    final inner = profileNode['profile'];
    final source = inner is Map ? inner : profileNode;
    final preferred = '${source['preferred_name'] ?? ''}'.trim();
    if (preferred.isNotEmpty) return preferred;
    final given = '${source['given_name'] ?? ''}'.trim();
    final family = '${source['family_name'] ?? ''}'.trim();
    return [given, family].where((part) => part.isNotEmpty).join(' ');
  }

  static String? _asNote(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static List<JsonObject> _asObjectList(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map)
          Map<String, Object?>.from(
            item.map((key, nested) => MapEntry('$key', nested)),
          ),
    ];
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }
}

class _ChurchAdminLiveView extends StatelessWidget {
  const _ChurchAdminLiveView({required this.dash});

  final _AdminDash dash;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _LiveAdminHeader(
            name: dash.displayName,
            unreadCount: dash.unreadNotificationCount,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          sliver: SliverList.list(
            children: [
              const _BuildingHero(),
              const SizedBox(height: 10),
              _LiveStatsCard(dash: dash),
              const SizedBox(height: 16),
              Text(
                fhcT(
                  context,
                  'church.quickActions',
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
                        'church.addMember',
                        fallback: 'Add Member',
                      ),
                      onTap: () => fhcPush(context, FhcRoutes.churchMembers),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.account_tree_outlined,
                      label: fhcT(
                        context,
                        'church.departments',
                        fallback: 'Departments',
                      ),
                      onTap: () => fhcPush(context, FhcRoutes.churchMinistries),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.groups_outlined,
                      label: fhcT(
                        context,
                        'church.smallGroups',
                        fallback: 'Small Groups',
                      ),
                      onTap: () => fhcPush(context, FhcRoutes.churchGroups),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.event_available_outlined,
                      label: fhcT(
                        context,
                        'church.attendance',
                        fallback: 'Attendance',
                      ),
                      onTap: () => fhcPush(context, FhcRoutes.churchAttendance),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                fhcT(
                  context,
                  'church.fromYourDashboard',
                  fallback: 'From your dashboard',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.ink,
                ),
              ),
              const SizedBox(height: 9),
              FhcSurfaceCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _OverviewRow(
                      icon: Icons.volunteer_activism_outlined,
                      title: fhcT(
                        context,
                        'church.openPrayers',
                        fallback: 'Open prayers',
                      ),
                      value: '${dash.openPrayerCount}',
                      valueColor: FhcColors.green,
                      onTap: () => fhcPush(context, FhcRoutes.prayer),
                    ),
                    const Divider(height: 1, color: FhcColors.border),
                    _OverviewRow(
                      icon: Icons.chat_bubble_outline,
                      title: fhcT(
                        context,
                        'common.messages',
                        fallback: 'Messages',
                      ),
                      value: fhcT(context, 'church.open', fallback: 'Open'),
                      onTap: () => fhcPush(context, FhcRoutes.messages),
                    ),
                    if (dash.upcomingNote != null) ...[
                      const Divider(height: 1, color: FhcColors.border),
                      _OverviewRow(
                        icon: Icons.event_outlined,
                        title: fhcT(
                          context,
                          'church.upcoming',
                          fallback: 'Upcoming',
                        ),
                        value: dash.upcomingNote!,
                      ),
                    ],
                    ..._intentRows(context, dash.recentPaymentIntents),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FhcPrimaryButton(
                label: fhcT(
                  context,
                  'church.viewFullDashboard',
                  fallback: 'View Full Church Dashboard',
                ),
                onPressed: () => fhcGo(context, FhcRoutes.church),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _intentRows(BuildContext context, List<JsonObject> intents) {
    if (intents.isEmpty) return const [];
    final shown = intents.take(3).toList();
    return [
      for (final intent in shown) ...[
        const Divider(height: 1, color: FhcColors.border),
        _OverviewRow(
          icon: Icons.payments_outlined,
          title:
              '${intent['purpose_code'] ?? fhcT(context, 'member.giving', fallback: 'Giving')}',
          value: _formatIntent(context, intent),
          valueColor: FhcColors.green,
        ),
      ],
    ];
  }

  static String _formatIntent(BuildContext context, JsonObject intent) {
    final status = '${intent['status'] ?? ''}'.trim();
    final currency = '${intent['currency'] ?? ''}'.trim();
    final minor = intent['amount_minor'];
    final amount = minor is num
        ? (minor / 100).toStringAsFixed(0)
        : '';
    final parts = <String>[
      if (currency.isNotEmpty && amount.isNotEmpty) '$currency $amount',
      if (status.isNotEmpty) status,
    ];
    return parts.isEmpty
        ? fhcT(context, 'church.intent', fallback: 'Intent')
        : parts.join(' • ');
  }
}

class _LiveAdminHeader extends StatelessWidget {
  const _LiveAdminHeader({required this.name, required this.unreadCount});

  final String name;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FhcColors.greenDeep,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fhcT(context, 'nav.church', fallback: 'Church'),
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
              _LiveNotificationBell(count: unreadCount),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name.isEmpty
                ? fhcT(
                    context,
                    'church.adminDashboard',
                    fallback: 'Admin Dashboard',
                  )
                : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fhcT(
              context,
              'church.adminDashboard',
              fallback: 'Admin Dashboard',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _LiveNotificationBell extends StatelessWidget {
  const _LiveNotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => fhcPush(context, FhcRoutes.notifications),
      padding: EdgeInsets.zero,
      tooltip: fhcT(
        context,
        'common.notifications',
        fallback: 'Notifications',
      ),
      icon: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none, color: Colors.white, size: 22),
            if (count > 0)
              Positioned(
                right: 2,
                top: 4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: FhcColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
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
      ),
    );
  }
}

class _LiveStatsCard extends StatelessWidget {
  const _LiveStatsCard({required this.dash});

  final _AdminDash dash;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const FhcCircleIcon(icon: Icons.notifications_outlined, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fhcT(
                    context,
                    'church.unreadNotifications',
                    fallback: 'Unread notifications',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FhcColors.muted,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${dash.unreadNotificationCount}',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurchAdminFixtureView extends StatelessWidget {
  const _ChurchAdminFixtureView();

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      darkStatusBar: true,
      statusBarColor: FhcColors.greenDeep,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _ChurchHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  sliver: SliverList.list(
                    children: [
                      const _BuildingHero(),
                      const SizedBox(height: 10),
                      const _MembersCard(),
                      const SizedBox(height: 16),
                      Text(
                        fhcT(
                          context,
                          'church.quickActions',
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
                                'church.addMember',
                                fallback: 'Add Member',
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.account_tree_outlined,
                              label: fhcT(
                                context,
                                'church.departments',
                                fallback: 'Departments',
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.groups_outlined,
                              label: fhcT(
                                context,
                                'church.smallGroups',
                                fallback: 'Small Groups',
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.event_available_outlined,
                              label: fhcT(
                                context,
                                'church.attendance',
                                fallback: 'Attendance',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fhcT(
                          context,
                          'church.ministryOverview',
                          fallback: 'Ministry Overview',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 9),
                      FhcSurfaceCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            _OverviewRow(
                              icon: Icons.church_outlined,
                              title: fhcT(
                                context,
                                'church.sundayService',
                                fallback: 'Sunday Service',
                              ),
                              value: fhcT(
                                context,
                                'church.sundayServiceTime',
                                fallback: 'Sundays • 9:00 AM',
                              ),
                            ),
                            const Divider(height: 1, color: FhcColors.border),
                            _OverviewRow(
                              icon: Icons.menu_book_outlined,
                              title: fhcT(
                                context,
                                'church.bibleStudy',
                                fallback: 'Study Manuals',
                              ),
                              value: fhcT(
                                context,
                                'church.bibleStudyTime',
                                fallback: 'Wednesdays • 6:00 PM',
                              ),
                            ),
                            const Divider(height: 1, color: FhcColors.border),
                            _OverviewRow(
                              icon: Icons.home_work_outlined,
                              title: fhcT(
                                context,
                                'church.homeChurches',
                                fallback: 'Home Churches',
                              ),
                              value: fhcT(
                                context,
                                'church.homeChurchesActive',
                                fallback: '12 Active',
                              ),
                              valueColor: FhcColors.green,
                            ),
                            const Divider(height: 1, color: FhcColors.border),
                            _OverviewRow(
                              icon: Icons.payments_outlined,
                              title: fhcT(
                                context,
                                'church.tithes',
                                fallback: 'Tithes',
                              ),
                              value: '₦2,450,000',
                              valueColor: FhcColors.green,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FhcPrimaryButton(
                        label: fhcT(
                          context,
                          'church.viewFullDashboard',
                          fallback: 'View Full Church Dashboard',
                        ),
                        onPressed: () => fhcGo(context, FhcRoutes.church),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FhcBottomNavigation(
            selected: 1,
            onSelected: (index) => fhcTab(context, index),
          ),
        ],
      ),
    );
  }
}

class _ChurchHeader extends StatelessWidget {
  const _ChurchHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FhcColors.greenDeep,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fhcT(context, 'nav.church', fallback: 'Church'),
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
              const _NotificationBell(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fhcT(
              context,
              'church.fixtureName',
              fallback: 'Family House Church, Ikeja',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fhcT(
              context,
              'church.adminDashboard',
              fallback: 'Admin Dashboard',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.2),
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

class _BuildingHero extends StatelessWidget {
  const _BuildingHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FhcRadius.md),
      child: const SizedBox(
        height: 132,
        width: double.infinity,
        child: _BuildingPhoto(),
      ),
    );
  }
}

class _BuildingPhoto extends StatelessWidget {
  const _BuildingPhoto();

  static const _fallback = ColoredBox(
    color: FhcColors.mint,
    child: Center(
      child: Icon(Icons.church_outlined, color: FhcColors.green, size: 48),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/church_building.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/church_hero.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/church_live.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => _fallback,
            );
          },
        );
      },
    );
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard();

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const FhcCircleIcon(icon: Icons.groups_outlined, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fhcT(
                    context,
                    'church.totalMembers',
                    fallback: 'Total Members',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FhcColors.muted,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '1,248',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            fhcT(
              context,
              'church.membersThisWeek',
              fallback: '+58 this week',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
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

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor = FhcColors.muted,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FhcColors.mint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: FhcColors.green, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.ink,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

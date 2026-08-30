import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchDashboardScreen extends StatefulWidget {
  const ChurchDashboardScreen({super.key, this.profileRepository});

  final ProfileRepository? profileRepository;

  @override
  State<ChurchDashboardScreen> createState() => _ChurchDashboardScreenState();
}

class _ChurchDashboardScreenState extends State<ChurchDashboardScreen> {
  FhcAsyncValue<_MemberDash> _state = const FhcAsyncValue.loading();
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
            'errors.churchDashboardRequiresApi',
            fallback:
                'Member dashboard requires GET /user/dashboard. '
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
        setState(() => _state = FhcAsyncValue.data(_MemberDash.fromJson(value)));
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showFixtures) {
      return const _ChurchDashboardFixtureView();
    }

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          Expanded(
            child: FhcAsyncBody<_MemberDash>(
              value: _state,
              onRetry: _load,
              unavailableTitle: fhcT(
                context,
                'errors.churchDashboardUnavailable',
                fallback: 'Church dashboard unavailable',
              ),
              emptyTitle: fhcT(
                context,
                'errors.noDashboardData',
                fallback: 'No dashboard data',
              ),
              builder: (context, dash) => _ChurchDashboardLiveView(dash: dash),
            ),
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

class _MemberDash {
  const _MemberDash({
    required this.displayName,
    required this.unreadNotificationCount,
    required this.openPrayerCount,
    required this.upcomingNote,
    required this.recentPaymentIntents,
  });

  factory _MemberDash.fromJson(Map<String, Object?> json) {
    return _MemberDash(
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

class _ChurchDashboardLiveView extends StatelessWidget {
  const _ChurchDashboardLiveView({required this.dash});

  final _MemberDash dash;

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? fhcT(context, 'member.goodMorning', fallback: 'Good morning')
        : hour < 17
        ? fhcT(context, 'member.goodAfternoon', fallback: 'Good afternoon')
        : fhcT(context, 'member.goodEvening', fallback: 'Good evening');
    if (dash.displayName.isEmpty) return part;
    return fhcT(
      context,
      'member.greetingName',
      args: {'greeting': part, 'name': dash.displayName},
      fallback: '$part, ${dash.displayName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      children: [
        _LiveHeader(
          greeting: _greeting(context),
          unreadCount: dash.unreadNotificationCount,
        ),
        const SizedBox(height: 14),
        const _JoinLiveCard(fixtureSchedule: false),
        const SizedBox(height: 18),
        Text(
          fhcT(context, 'member.yourActivity', fallback: 'Your activity'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FhcMetricCard(
                label: fhcT(
                  context,
                  'member.openPrayers',
                  fallback: 'Open prayers',
                ),
                value: '${dash.openPrayerCount}',
                note: fhcT(
                  context,
                  'member.fromUserDashboard',
                  fallback: 'From /user/dashboard',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FhcMetricCard(
                label: fhcT(context, 'member.unread', fallback: 'Unread'),
                value: '${dash.unreadNotificationCount}',
                note: fhcT(
                  context,
                  'member.notifications',
                  fallback: 'Notifications',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FhcMetricCard(
                label: fhcT(
                  context,
                  'member.givingIntents',
                  fallback: 'Giving intents',
                ),
                value: '${dash.recentPaymentIntents.length}',
                note: dash.recentPaymentIntents.isEmpty
                    ? fhcT(
                        context,
                        'member.noneRecent',
                        fallback: 'None recent',
                      )
                    : fhcT(context, 'member.recent', fallback: 'Recent'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          fhcT(context, 'member.shortcuts', fallback: 'Shortcuts'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              _ActivityRow(
                icon: Icons.volunteer_activism_outlined,
                title: fhcT(context, 'member.prayer', fallback: 'Prayer'),
                subtitle: dash.openPrayerCount == 0
                    ? fhcT(
                        context,
                        'member.noOpenRequests',
                        fallback: 'No open requests',
                      )
                    : dash.openPrayerCount == 1
                    ? fhcT(
                        context,
                        'member.openRequestOne',
                        fallback: '1 open request',
                      )
                    : fhcT(
                        context,
                        'member.openRequestMany',
                        args: {'count': '${dash.openPrayerCount}'},
                        fallback:
                            '${dash.openPrayerCount} open requests',
                      ),
                onTap: () => fhcPush(context, FhcRoutes.prayer),
              ),
              const Divider(height: 1, color: FhcColors.border),
              _ActivityRow(
                icon: Icons.chat_bubble_outline,
                title: fhcT(context, 'member.messages', fallback: 'Messages'),
                subtitle: fhcT(
                  context,
                  'member.openConversations',
                  fallback: 'Open conversations',
                ),
                onTap: () => fhcPush(context, FhcRoutes.messages),
              ),
              if (dash.upcomingNote != null) ...[
                const Divider(height: 1, color: FhcColors.border),
                _ActivityRow(
                  icon: Icons.event_outlined,
                  title: fhcT(context, 'member.upcoming', fallback: 'Upcoming'),
                  subtitle: dash.upcomingNote!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader({required this.greeting, required this.unreadCount});

  final String greeting;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                fhcT(context, 'nav.churchBanner', fallback: 'CHURCH'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FhcColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const _HeaderAvatar(),
            const SizedBox(width: 4),
            FhcNotificationBell(
              count: unreadCount,
              onTap: () => fhcPush(context, FhcRoutes.notifications),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          greeting,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FhcColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => fhcPush(context, FhcRoutes.churchDetail),
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  fhcT(
                    context,
                    'member.churchProfile',
                    fallback: 'Church profile',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FhcColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: FhcColors.ink,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChurchDashboardFixtureView extends StatelessWidget {
  const _ChurchDashboardFixtureView();

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              children: [
                const _ChurchHeader(),
                const SizedBox(height: 14),
                const _JoinLiveCard(fixtureSchedule: true),
                const SizedBox(height: 18),
                Text(
                  fhcT(
                    context,
                    'member.ministryOverview',
                    fallback: 'Ministry Overview',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FhcMetricCard(
                        label: fhcT(
                          context,
                          'member.members',
                          fallback: 'Members',
                        ),
                        value: '1,248',
                        note: fhcT(
                          context,
                          'member.plusThisWeek',
                          fallback: '+36 this week',
                        ),
                        noteColor: FhcColors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FhcMetricCard(
                        label: fhcT(
                          context,
                          'member.smallGroups',
                          fallback: 'Small Groups',
                        ),
                        value: '24',
                        note: fhcT(context, 'member.active', fallback: 'Active'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FhcMetricCard(
                        label: fhcT(
                          context,
                          'member.firstTimers',
                          fallback: 'First Timers',
                        ),
                        value: '18',
                        note: fhcT(context, 'member.newLabel', fallback: 'New'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  fhcT(
                    context,
                    'member.upcomingActivities',
                    fallback: 'Upcoming Activities',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                FhcSurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _ActivityRow(
                        icon: Icons.calendar_today_outlined,
                        title: fhcT(
                          context,
                          'member.prayerMeeting',
                          fallback: 'Prayer Meeting',
                        ),
                        subtitle: 'May 20, 2025 • 6:00 PM',
                        onTap: () => fhcPush(context, FhcRoutes.prayer),
                      ),
                      const Divider(height: 1, color: FhcColors.border),
                      _ActivityRow(
                        icon: Icons.music_note_outlined,
                        title: fhcT(
                          context,
                          'member.choirPractice',
                          fallback: 'Choir Practice',
                        ),
                        subtitle: 'May 27, 2025 • 5:00 PM',
                        onTap: () => fhcPush(context, FhcRoutes.events),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

class _ChurchHeader extends StatelessWidget {
  const _ChurchHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                fhcT(context, 'nav.churchBanner', fallback: 'CHURCH'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FhcColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const _HeaderAvatar(),
            const SizedBox(width: 4),
            FhcNotificationBell(
              count: 2,
              onTap: () => fhcPush(context, FhcRoutes.notifications),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          fhcT(
            context,
            'member.greetingName',
            args: {
              'greeting': fhcT(
                context,
                'member.goodMorning',
                fallback: 'Good morning',
              ),
              'name': 'Chibukem',
            },
            fallback: 'Good morning, Chibukem',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FhcColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => fhcPush(context, FhcRoutes.churchDetail),
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  fhcT(
                    context,
                    'member.familyHouseIkeja',
                    fallback: 'Family House Church, Ikeja',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FhcColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: FhcColors.ink,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: FhcColors.mint,
      child: ClipOval(
        child: Image.asset(
          'assets/images/member_avatar.png',
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) =>
                  const Icon(Icons.person, color: FhcColors.green, size: 18),
        ),
      ),
    );
  }
}

class _JoinLiveCard extends StatelessWidget {
  const _JoinLiveCard({required this.fixtureSchedule});

  final bool fixtureSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: FhcColors.white,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        border: Border.all(color: FhcColors.border),
        boxShadow: FhcElevation.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 168,
            child: _LivePhoto(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 132, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fhcT(
                    context,
                    'member.joinLiveService',
                    fallback: 'Join Live Service',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fixtureSchedule
                      ? fhcT(
                          context,
                          'member.sundayWorship',
                          fallback: 'Sunday Worship',
                        )
                      : fhcT(
                          context,
                          'member.liveFellowship',
                          fallback: 'Live fellowship',
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                Text(
                  fixtureSchedule
                      ? fhcT(
                          context,
                          'member.todayAtNine',
                          fallback: 'Today • 9:00 AM',
                        )
                      : fhcT(
                          context,
                          'member.noPublishedSchedule',
                          fallback: 'No published schedule',
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: FhcColors.muted,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 30,
                  child: FilledButton(
                    onPressed: () => fhcPush(context, FhcRoutes.live),
                    style: FilledButton.styleFrom(
                      backgroundColor: FhcColors.green,
                      foregroundColor: FhcColors.white,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FhcRadius.button),
                      ),
                    ),
                    child: Text(
                      fhcT(context, 'member.joinNow', fallback: 'Join Now'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

class _LivePhoto extends StatelessWidget {
  const _LivePhoto();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000)],
          stops: [0.0, 0.28, 1.0],
        ).createShader(bounds);
      },
      child: Image.asset(
        'assets/images/live_worship.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder:
            (_, __, ___) => Image.asset(
              'assets/images/church_live.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder:
                  (_, __, ___) => const ColoredBox(color: FhcColors.mint),
            ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FhcColors.mint,
                borderRadius: BorderRadius.circular(FhcRadius.sm),
              ),
              child: Icon(icon, color: FhcColors.green, size: 18),
            ),
            const SizedBox(width: 12),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
                      fontSize: 10,
                      color: FhcColors.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: FhcColors.muted),
          ],
        ),
      ),
    );
  }
}

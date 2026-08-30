import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchModuleHomeScreen extends StatelessWidget {
  const ChurchModuleHomeScreen({super.key});

  static List<_MenuSpec> _overviewOf(BuildContext context) => [
    _MenuSpec(
      icon: Icons.church_outlined,
      title: fhcT(context, 'member.myChurch', fallback: 'My Church'),
      subtitle: fhcT(
        context,
        'member.myChurchCopy',
        fallback: 'Churches and home churches you belong to',
      ),
      route: FhcRoutes.myChurch,
    ),
    _MenuSpec(
      icon: Icons.explore_outlined,
      title: fhcT(context, 'member.findChurches', fallback: 'Find Churches'),
      subtitle: fhcT(
        context,
        'member.findChurchesCopy',
        fallback: 'Discover Family House churches',
      ),
      route: FhcRoutes.discover,
    ),
    _MenuSpec(
      icon: Icons.home_work_outlined,
      title: fhcT(context, 'member.homeChurch', fallback: 'Home Church'),
      subtitle: fhcT(
        context,
        'member.homeChurchManageCopy',
        fallback: 'Open your home church or start one',
      ),
      route: FhcRoutes.homeChurch,
    ),
  ];

  static List<_MenuSpec> _mediaOf(BuildContext context) => [
    _MenuSpec(
      icon: Icons.play_circle_outline,
      title: fhcT(context, 'member.media', fallback: 'Media'),
      subtitle: fhcT(
        context,
        'member.mediaCopy',
        fallback: 'Watch, listen, and read',
      ),
      route: FhcRoutes.media,
    ),
    _MenuSpec(
      icon: Icons.menu_book_outlined,
      title: fhcT(context, 'online.sermons', fallback: 'Sermons'),
      subtitle: fhcT(
        context,
        'online.sermonsCopy',
        fallback: 'Messages and teaching',
      ),
      route: FhcRoutes.sermons,
    ),
    _MenuSpec(
      icon: Icons.live_tv_outlined,
      title: fhcT(context, 'member.liveFellowship', fallback: 'Live Fellowship'),
      subtitle: fhcT(
        context,
        'member.liveFellowshipCopy',
        fallback: 'Join the live service',
      ),
      route: FhcRoutes.live,
    ),
  ];

  static List<_MenuSpec> _communityOf(BuildContext context) => [
    _MenuSpec(
      icon: Icons.event_outlined,
      title: fhcT(context, 'member.events', fallback: 'Events'),
      subtitle: fhcT(
        context,
        'member.eventsCopy',
        fallback: 'Upcoming gatherings',
      ),
      route: FhcRoutes.events,
    ),
    _MenuSpec(
      icon: Icons.groups_outlined,
      title: fhcT(context, 'member.groups', fallback: 'Groups'),
      subtitle: fhcT(
        context,
        'member.groupsCopy',
        fallback: 'Fellowship groups',
      ),
      route: FhcRoutes.groups,
    ),
    _MenuSpec(
      icon: Icons.favorite_border,
      title: fhcT(context, 'nav.give', fallback: 'Give'),
      subtitle: fhcT(
        context,
        'member.giveCopy',
        fallback: 'Support the work',
      ),
      route: FhcRoutes.give,
    ),
    _MenuSpec(
      icon: Icons.volunteer_activism_outlined,
      title: fhcT(context, 'nav.prayer', fallback: 'Prayer'),
      subtitle: fhcT(
        context,
        'member.prayerCopy',
        fallback: 'Share and join prayer',
      ),
      route: FhcRoutes.prayer,
    ),
  ];

  static List<_MenuSpec> _opsOf(BuildContext context) => [
    _MenuSpec(
      icon: Icons.groups_outlined,
      title: fhcT(context, 'member.members', fallback: 'Members'),
      subtitle: fhcT(
        context,
        'member.membersCopy',
        fallback: 'Manage church members',
      ),
      route: FhcRoutes.churchMembers,
    ),
    _MenuSpec(
      icon: Icons.workspaces_outlined,
      title: fhcT(context, 'member.smallGroupsTitle', fallback: 'Small Groups'),
      subtitle: fhcT(
        context,
        'member.smallGroupsCopy',
        fallback: 'Fellowship in small groups',
      ),
      route: FhcRoutes.churchGroups,
    ),
    _MenuSpec(
      icon: Icons.campaign_outlined,
      title: fhcT(context, 'member.announcements', fallback: 'Announcements'),
      subtitle: fhcT(
        context,
        'member.announcementsCopy',
        fallback: 'Church announcements',
      ),
      route: FhcRoutes.churchAnnouncements,
    ),
    _MenuSpec(
      icon: Icons.settings_outlined,
      title: fhcT(context, 'common.settings', fallback: 'Settings'),
      subtitle: fhcT(
        context,
        'member.churchSettingsCopy',
        fallback: 'Church module settings',
      ),
      route: FhcRoutes.churchSettings,
    ),
  ];

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.modules);
    }
  }

  static List<Widget> _tiles(BuildContext context, List<_MenuSpec> items) {
    return [
      for (var i = 0; i < items.length; i++)
        FhcMenuTile(
          icon: items[i].icon,
          title: items[i].title,
          subtitle: items[i].subtitle,
          showDivider: i < items.length - 1,
          onTap: () => fhcPush(context, items[i].route),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'nav.church', fallback: 'Church'),
            onBack: () => _goBack(context),
            trailing: FhcNotificationBell(
              count: 0,
              onTap: () => fhcPush(context, FhcRoutes.notifications),
            ),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                Text(
                  fhcT(
                    context,
                    'member.churchHomeCopy',
                    fallback:
                        'Find churches, media, events, and your home church.',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: FhcColors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                FhcMenuGroup(
                  title: fhcT(context, 'common.overview', fallback: 'Overview'),
                  children: _tiles(context, _overviewOf(context)),
                ),
                const SizedBox(height: 14),
                FhcMenuGroup(
                  title: fhcT(context, 'member.media', fallback: 'Media'),
                  children: _tiles(context, _mediaOf(context)),
                ),
                const SizedBox(height: 14),
                FhcMenuGroup(
                  title: fhcT(
                    context,
                    'member.community',
                    fallback: 'Community',
                  ),
                  children: _tiles(context, _communityOf(context)),
                ),
                const SizedBox(height: 14),
                FhcMenuGroup(
                  title: fhcT(
                    context,
                    'member.operations',
                    fallback: 'Operations',
                  ),
                  children: _tiles(context, _opsOf(context)),
                ),
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _MenuSpec {
  const _MenuSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

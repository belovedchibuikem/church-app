import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchSettingsScreen extends StatelessWidget {
  const ChurchSettingsScreen({super.key});

  static List<_SettingItem> _profileOf(BuildContext context) => [
    _SettingItem(
      icon: Icons.person_outline,
      title: fhcT(
        context,
        'settings.churchProfile',
        fallback: 'Church Profile',
      ),
      subtitle: fhcT(
        context,
        'settings.churchProfileCopy',
        fallback: 'Update church information',
      ),
      route: FhcRoutes.churchDetail,
    ),
    _SettingItem(
      icon: Icons.schedule_outlined,
      title: fhcT(context, 'settings.serviceTimes', fallback: 'Service Times'),
      subtitle: fhcT(
        context,
        'settings.serviceTimesCopy',
        fallback: 'Manage service schedules',
      ),
    ),
    _SettingItem(
      icon: Icons.location_on_outlined,
      title: fhcT(
        context,
        'settings.churchLocation',
        fallback: 'Church Location',
      ),
      subtitle: fhcT(
        context,
        'settings.churchLocationCopy',
        fallback: 'Manage church address',
      ),
      route: FhcRoutes.churchDetail,
    ),
  ];

  static List<_SettingItem> _accessOf(BuildContext context) => [
    _SettingItem(
      icon: Icons.notifications_outlined,
      title: fhcT(
        context,
        'settings.notificationSettings',
        fallback: 'Notification Settings',
      ),
      subtitle: fhcT(
        context,
        'settings.notificationSettingsCopy',
        fallback: 'Manage notifications',
      ),
      route: FhcRoutes.notifications,
    ),
    _SettingItem(
      icon: Icons.lock_outline,
      title: fhcT(
        context,
        'settings.privacySettings',
        fallback: 'Privacy Settings',
      ),
      subtitle: fhcT(
        context,
        'settings.privacySettingsCopy',
        fallback: 'Manage privacy options',
      ),
      route: FhcRoutes.settings,
    ),
    _SettingItem(
      icon: Icons.people_outline,
      title: fhcT(context, 'settings.usersRoles', fallback: 'Users & Roles'),
      subtitle: fhcT(
        context,
        'settings.usersRolesCopy',
        fallback: 'Manage access & permissions',
      ),
      route: FhcRoutes.churchMembers,
    ),
  ];

  static List<_SettingItem> _dataOf(BuildContext context) => [
    _SettingItem(
      icon: Icons.cloud_upload_outlined,
      title: fhcT(context, 'settings.backupExport', fallback: 'Backup & Export'),
      subtitle: fhcT(
        context,
        'settings.backupExportCopy',
        fallback: 'Backup church data',
      ),
    ),
  ];

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.churchHome);
    }
  }

  static void _open(BuildContext context, String? route) {
    if (route == null) {
      fhcApiUnavailable(
        context,
        action: fhcT(
          context,
          'settings.thisChurchSetting',
          fallback: 'This church setting',
        ),
      );
      return;
    }
    fhcPush(context, route);
  }

  static List<Widget> _tiles(BuildContext context, List<_SettingItem> items) {
    return [
      for (var i = 0; i < items.length; i++)
        FhcMenuTile(
          icon: items[i].icon,
          title: items[i].title,
          subtitle: items[i].subtitle,
          showDivider: i < items.length - 1,
          onTap: () => _open(context, items[i].route),
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
            title: fhcT(
              context,
              'settings.churchSettings',
              fallback: 'Church Settings',
            ),
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                FhcMenuGroup(
                  title: fhcT(context, 'common.profile', fallback: 'Profile'),
                  children: _tiles(context, _profileOf(context)),
                ),
                const SizedBox(height: 14),
                FhcMenuGroup(
                  title: fhcT(context, 'settings.access', fallback: 'Access'),
                  children: _tiles(context, _accessOf(context)),
                ),
                const SizedBox(height: 14),
                FhcMenuGroup(
                  title: fhcT(context, 'settings.data', fallback: 'Data'),
                  children: _tiles(context, _dataOf(context)),
                ),
                const SizedBox(height: 28),
                Text(
                  fhcT(
                    context,
                    'settings.copyright',
                    fallback:
                        '© 2025 Family House Church. All rights reserved.',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: FhcColors.muted,
                  ),
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

class _SettingItem {
  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;
}

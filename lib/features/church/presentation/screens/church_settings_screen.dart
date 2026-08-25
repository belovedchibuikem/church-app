import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchSettingsScreen extends StatelessWidget {
  const ChurchSettingsScreen({super.key});

  static const _items = <_SettingItem>[
    _SettingItem(
      icon: Icons.person_outline,
      title: 'Church Profile',
      subtitle: 'Update church information',
      route: FhcRoutes.churchDetail,
    ),
    _SettingItem(
      icon: Icons.schedule_outlined,
      title: 'Service Times',
      subtitle: 'Manage service schedules',
    ),
    _SettingItem(
      icon: Icons.location_on_outlined,
      title: 'Church Location',
      subtitle: 'Manage church address',
      route: FhcRoutes.churchDetail,
    ),
    _SettingItem(
      icon: Icons.notifications_outlined,
      title: 'Notification Settings',
      subtitle: 'Manage notifications',
      route: FhcRoutes.notifications,
    ),
    _SettingItem(
      icon: Icons.lock_outline,
      title: 'Privacy Settings',
      subtitle: 'Manage privacy options',
    ),
    _SettingItem(
      icon: Icons.people_outline,
      title: 'Users & Roles',
      subtitle: 'Manage access & permissions',
      route: FhcRoutes.churchMembers,
    ),
    _SettingItem(
      icon: Icons.cloud_upload_outlined,
      title: 'Backup & Export',
      subtitle: 'Backup church data',
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
    if (route == null) return;
    fhcPush(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(title: 'Church Settings', onBack: () => _goBack(context)),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: FhcColors.border),
                  _SettingRow(
                    item: _items[i],
                    onTap: () => _open(context, _items[i].route),
                  ),
                ],
                const SizedBox(height: 28),
                const Text(
                  '© 2025 Family House Church. All rights reserved.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.item, required this.onTap});

  final _SettingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.title}, ${item.subtitle}',
      child: InkWell(
        onTap: item.route == null ? null : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                FhcCircleIcon(icon: item.icon, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: FhcColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: FhcColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

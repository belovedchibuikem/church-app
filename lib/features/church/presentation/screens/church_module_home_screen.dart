import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchModuleHomeScreen extends StatelessWidget {
  const ChurchModuleHomeScreen({super.key});

  static const _items = <_MenuSpec>[
    _MenuSpec(
      icon: Icons.church_outlined,
      title: 'Church Dashboard',
      subtitle: 'Overview & Status',
      route: FhcRoutes.church,
    ),
    _MenuSpec(
      icon: Icons.groups_outlined,
      title: 'Members',
      subtitle: 'Manage church members',
      route: FhcRoutes.churchMembers,
    ),
    _MenuSpec(
      icon: Icons.workspaces_outlined,
      title: 'Small Groups',
      subtitle: 'Fellowship in small groups',
      route: FhcRoutes.churchGroups,
    ),
    _MenuSpec(
      icon: Icons.record_voice_over_outlined,
      title: 'Ministries',
      subtitle: 'Manage church ministries',
      route: FhcRoutes.churchMinistries,
    ),
    _MenuSpec(
      icon: Icons.calendar_today_outlined,
      title: 'Events',
      subtitle: 'Plan & manage events',
      route: FhcRoutes.events,
    ),
    _MenuSpec(
      icon: Icons.fact_check_outlined,
      title: 'Attendance',
      subtitle: 'Track attendance',
      route: FhcRoutes.homeChurch,
    ),
    _MenuSpec(
      icon: Icons.campaign_outlined,
      title: 'Announcements',
      subtitle: 'Church announcements',
      route: FhcRoutes.churchAnnouncements,
    ),
    _MenuSpec(
      icon: Icons.insert_drive_file_outlined,
      title: 'Documents',
      subtitle: 'Church documents',
      route: FhcRoutes.churchDocuments,
    ),
    _MenuSpec(
      icon: Icons.settings_outlined,
      title: 'Settings',
      subtitle: 'Church module settings',
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

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: 'CHURCH',
            onBack: () => _goBack(context),
            trailing: IconButton(
              onPressed: () => fhcPush(context, FhcRoutes.notifications),
              padding: EdgeInsets.zero,
              icon: const _BellBadge(),
              color: FhcColors.ink,
              tooltip: 'Notifications',
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 4),
              child: Column(
                children: [
                  for (final item in _items)
                    Expanded(
                      child: _MenuRow(
                        item: item,
                        onTap: () => fhcPush(context, item.route),
                      ),
                    ),
                ],
              ),
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

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onTap});

  final _MenuSpec item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.title}. ${item.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Icon(item.icon, size: 24, color: FhcColors.green),
                  ),
                  const SizedBox(width: 16),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: FhcColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: FhcColors.muted,
                          ),
                        ),
                      ],
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

class _BellBadge extends StatelessWidget {
  const _BellBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_none, size: 22, color: FhcColors.ink),
          Positioned(
            right: -2,
            top: 0,
            child: Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: FhcColors.red,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '2',
                style: TextStyle(
                  color: FhcColors.white,
                  fontSize: 8,
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

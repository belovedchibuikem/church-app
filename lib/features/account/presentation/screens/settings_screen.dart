import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(title: 'Settings', onBack: () => _goBack(context)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: const ClampingScrollPhysics(),
                      children: [
                        _MenuList(
                          items: [
                            _MenuItem(
                              icon: Icons.person_outline,
                              label: 'Account Settings',
                              onTap: () =>
                                  fhcPush(context, FhcRoutes.profile),
                            ),
                            _MenuItem(
                              icon: Icons.notifications_outlined,
                              label: 'Notification Preferences',
                              onTap: () =>
                                  fhcPush(context, FhcRoutes.notifications),
                            ),
                            const _MenuItem(
                              icon: Icons.security,
                              label: 'Privacy & Security',
                            ),
                            const _MenuItem(
                              icon: Icons.language,
                              label: 'Language',
                              trailing: 'English',
                            ),
                            const _MenuItem(
                              icon: Icons.dark_mode_outlined,
                              label: 'Theme',
                              trailing: 'System Default',
                            ),
                            const _MenuItem(
                              icon: Icons.info_outline,
                              label: 'About Family House Connect',
                              trailing: 'Version 1.0.0',
                              showChevron: false,
                            ),
                            const _MenuItem(
                              icon: Icons.help_outline,
                              label: 'Help & Support',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FhcPrimaryButton(
                    label: 'Log Out',
                    color: FhcColors.red,
                    onPressed: () => fhcGo(context, '/sign-in'),
                  ),
                ],
              ),
            ),
          ),
          const FhcBottomNavigation(selected: 4),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
}

class _MenuList extends StatelessWidget {
  const _MenuList({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: FhcColors.border),
            _MenuRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: item.onTap != null || item.showChevron,
      label:
          item.trailing == null
              ? item.label
              : '${item.label}, ${item.trailing}',
      child: InkWell(
        onTap: item.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                FhcCircleIcon(icon: item.icon, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: FhcColors.ink,
                    ),
                  ),
                ),
                if (item.trailing != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    item.trailing!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: FhcColors.muted,
                    ),
                  ),
                ],
                if (item.showChevron) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: FhcColors.muted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

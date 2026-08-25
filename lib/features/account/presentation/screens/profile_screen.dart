import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: 'My Profile',
            onBack: () => _goBack(context),
            trailing: IconButton(
              onPressed: () => fhcPush(context, FhcRoutes.settings),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.settings_outlined, size: 22),
              color: FhcColors.ink,
              tooltip: 'Settings',
            ),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              children: [
                const _ProfileHero(),
                const SizedBox(height: 20),
                _MenuList(
                  items: [
                    const _MenuItem(
                      icon: Icons.person_outline,
                      label: 'Personal Information',
                    ),
                    _MenuItem(
                      icon: Icons.currency_exchange,
                      label: 'My Giving History',
                      onTap: () => fhcPush(context, FhcRoutes.giveHistory),
                    ),
                    _MenuItem(
                      icon: Icons.volunteer_activism_outlined,
                      label: 'My Prayer Requests',
                      onTap: () => fhcPush(context, FhcRoutes.prayer),
                    ),
                    _MenuItem(
                      icon: Icons.groups_outlined,
                      label: 'My Groups',
                      onTap: () => fhcPush(context, FhcRoutes.groups),
                    ),
                    _MenuItem(
                      icon: Icons.settings_outlined,
                      label: 'App Settings',
                      onTap: () => fhcPush(context, FhcRoutes.settings),
                    ),
                    const _MenuItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                    ),
                    _MenuItem(
                      icon: Icons.logout,
                      label: 'Sign Out',
                      onTap: () => fhcGo(context, '/sign-in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          FhcBottomNavigation(
            selected: 4,
            onSelected: (i) => fhcTab(context, i),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ProfileAvatar(),
        const SizedBox(height: 12),
        const Text(
          'Chibuikem Beloved',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'beloved.chibuikem@email.com',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, height: 1.3, color: FhcColors.muted),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: FhcColors.green,
              foregroundColor: FhcColors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FhcRadius.button),
              ),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 44,
      backgroundColor: FhcColors.mint,
      child: ClipOval(
        child: Image.asset(
          'assets/images/profile_chibuikem.png',
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => Image.asset(
                'assets/images/profile_avatar.png',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Image.asset(
                      'assets/images/member_avatar.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => const Icon(
                            Icons.person,
                            size: 44,
                            color: FhcColors.green,
                          ),
                    ),
              ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
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
      button: item.onTap != null,
      label: item.label,
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
                const SizedBox(width: 4),
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

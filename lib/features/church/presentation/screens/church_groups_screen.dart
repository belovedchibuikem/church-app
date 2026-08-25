import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchGroupsScreen extends StatelessWidget {
  const ChurchGroupsScreen({super.key});

  static const _groups = <_GroupSpec>[
    _GroupSpec(
      name: 'Faith Builders',
      leader: 'Pastor John',
      members: 12,
      asset: 'assets/images/member_avatar.png',
    ),
    _GroupSpec(
      name: 'Young Adults',
      leader: 'Sarah Okafor',
      members: 18,
      asset: 'assets/images/kca_avatar.png',
    ),
    _GroupSpec(
      name: 'Men of Valor',
      leader: 'David Okoro',
      members: 22,
      asset: 'assets/images/profile_chibuikem.png',
    ),
    _GroupSpec(
      name: 'Women of Purpose',
      leader: 'Blessing Uche',
      members: 15,
      asset: 'assets/images/prayer_avatar.png',
    ),
    _GroupSpec(
      name: 'Teens Connect',
      leader: 'Michael Johnson',
      members: 20,
      asset: 'assets/images/member_avatar.png',
    ),
  ];

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    fhcGo(context, FhcRoutes.churchHome);
  }

  static void _openGroup(BuildContext context) {
    fhcPush(context, FhcRoutes.groups);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: 'SMALL GROUPS',
            onBack: () => _goBack(context),
            trailing: IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.search, size: 22),
              color: FhcColors.ink,
              tooltip: 'Search',
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _SearchAddRow(),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
              itemCount: _groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _GroupCard(
                  group: _groups[index],
                  onTap: () => _openGroup(context),
                );
              },
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _GroupSpec {
  const _GroupSpec({
    required this.name,
    required this.leader,
    required this.members,
    required this.asset,
  });

  final String name;
  final String leader;
  final int members;
  final String asset;
}

class _SearchAddRow extends StatelessWidget {
  const _SearchAddRow();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              style: FhcTypography.body,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                hintStyle: FhcTypography.hint,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: FhcColors.muted,
                ),
                isDense: true,
                filled: true,
                fillColor: FhcColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: FhcColors.border),
                  borderRadius: radius,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: FhcColors.border),
                  borderRadius: radius,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: FhcColors.green,
                    width: 1.5,
                  ),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'Add group',
          child: Container(
            width: FhcSizes.minTap,
            height: FhcSizes.minTap,
            decoration: BoxDecoration(
              color: FhcColors.white,
              borderRadius: radius,
              border: Border.all(color: FhcColors.border),
            ),
            child: const Icon(Icons.add, size: 22, color: FhcColors.ink),
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});

  final _GroupSpec group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              _GroupAvatar(asset: group.asset),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Leader: ${group.leader}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FhcTypography.body.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${group.members} Members',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FhcTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _ActiveBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        asset,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => const ColoredBox(
              color: FhcColors.mint,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.groups_outlined,
                  size: 22,
                  color: FhcColors.green,
                ),
              ),
            ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: FhcColors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Active',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: FhcColors.white,
          height: 1.1,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class MissionDashboardScreen extends StatelessWidget {
  const MissionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      darkStatusBar: true,
      statusBarColor: FhcColors.navy,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _MissionHeader()),
                const SliverToBoxAdapter(child: _MissionTabs()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  sliver: SliverList.list(
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            child: _MissionMetric(
                              label: 'Active Crusades',
                              value: '8',
                              note: 'This Month',
                            ),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: _MissionMetric(
                              label: 'Mentors',
                              value: '12',
                              note: 'Active',
                            ),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: _MissionMetric(
                              label: 'Follow-ups',
                              value: '254',
                              note: 'Ongoing',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
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
                              label: 'Add Soul',
                              onTap: () => fhcPush(context, FhcRoutes.souls),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.waving_hand_outlined,
                              label: 'Follow-up',
                              onTap: () => fhcPush(context, FhcRoutes.souls),
                            ),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.groups_outlined,
                              label: 'Mentors',
                            ),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.description_outlined,
                              label: 'Reports',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Recent Crusades',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FhcSurfaceCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            _CrusadeRow(
                              title: 'Lagos Outreach Crusade',
                              subtitle: 'May 29 – Jun 1, 2025 • Lagos',
                              value: '1,250 Souls',
                              imageAsset:
                                  'assets/images/mission_lagos_thumb.png',
                              onTap: () => fhcPush(context, FhcRoutes.crusade),
                            ),
                            const Divider(height: 1, color: FhcColors.border),
                            _CrusadeRow(
                              title: 'Abuja City Crusade',
                              subtitle: 'May 20, 2025 • Abuja',
                              value: '86 Souls',
                              imageAsset: 'assets/images/mission_banner.png',
                              onTap: () => fhcPush(context, FhcRoutes.crusade),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FhcBottomNavigation(
            selected: 1,
            onSelected: (i) => fhcTab(context, i),
          ),
        ],
      ),
    );
  }
}

class _MissionHeader extends StatelessWidget {
  const _MissionHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FhcColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'MISSION',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              _NotificationBell(),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => fhcPush(context, FhcRoutes.crusade),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lagos Outreach Crusade',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'May 29 – Jun 1, 2025 • Lagos, Nigeria',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _HeaderMetric(label: 'Souls Reached', value: '1,250'),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _HeaderMetric(label: 'New Conversions', value: '124'),
              ),
              SizedBox(width: 6),
              Expanded(child: _HeaderMetric(label: 'Volunteers', value: '36')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              color: FhcColors.muted,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
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

class _MissionTabs extends StatelessWidget {
  const _MissionTabs();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _TabLabel('Overview', true)),
          Expanded(child: _TabLabel('Souls', false)),
          Expanded(child: _TabLabel('Schedule', false)),
          Expanded(child: _TabLabel('Team', false)),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel(this.text, this.active);

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? FhcColors.green : FhcColors.border,
            width: active ? 2 : 1,
          ),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: active ? FhcColors.green : FhcColors.ink,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }
}

class _MissionMetric extends StatelessWidget {
  const _MissionMetric({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              color: FhcColors.muted,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                color: FhcColors.greenDark,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8,
              color: FhcColors.muted,
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

class _CrusadeRow extends StatelessWidget {
  const _CrusadeRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String value;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => ColoredBox(
                        color: FhcColors.mint,
                        child: const Icon(
                          Icons.campaign_outlined,
                          color: FhcColors.green,
                          size: 20,
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
                      fontSize: 9,
                      color: FhcColors.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: FhcColors.green,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

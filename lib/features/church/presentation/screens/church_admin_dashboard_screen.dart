import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchAdminDashboardScreen extends StatelessWidget {
  const ChurchAdminDashboardScreen({super.key});

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
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.person_add_alt,
                              label: 'Add Member',
                            ),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.account_tree_outlined,
                              label: 'Departments',
                            ),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.groups_outlined,
                              label: 'Small Groups',
                            ),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.event_available_outlined,
                              label: 'Attendance',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ministry Overview',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const FhcSurfaceCard(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            _OverviewRow(
                              icon: Icons.church_outlined,
                              title: 'Sunday Service',
                              value: 'Sundays • 9:00 AM',
                            ),
                            Divider(height: 1, color: FhcColors.border),
                            _OverviewRow(
                              icon: Icons.menu_book_outlined,
                              title: 'Bible Study',
                              value: 'Wednesdays • 6:00 PM',
                            ),
                            Divider(height: 1, color: FhcColors.border),
                            _OverviewRow(
                              icon: Icons.home_work_outlined,
                              title: 'Home Churches',
                              value: '12 Active',
                              valueColor: FhcColors.green,
                            ),
                            Divider(height: 1, color: FhcColors.border),
                            _OverviewRow(
                              icon: Icons.payments_outlined,
                              title: 'Tithes',
                              value: '₦2,450,000',
                              valueColor: FhcColors.green,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FhcPrimaryButton(
                        label: 'View Full Church Dashboard',
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Church',
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
          SizedBox(height: 8),
          Text(
            'Family House Church, Ikeja',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Admin Dashboard',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 11, height: 1.2),
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
    return const FhcSurfaceCard(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          FhcCircleIcon(icon: Icons.groups_outlined, size: 44),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Members',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: FhcColors.muted,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                FittedBox(
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
          SizedBox(width: 8),
          Text(
            '+58 this week',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
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
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
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
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor = FhcColors.muted,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}

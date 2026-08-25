import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class HomeChurchDashboardScreen extends StatelessWidget {
  const HomeChurchDashboardScreen({super.key});

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  static void _onMore(BuildContext context, String value) {
    switch (value) {
      case 'settings':
        fhcPush(context, FhcRoutes.churchSettings);
      case 'profile':
        fhcPush(context, FhcRoutes.churchDetail);
    }
  }

  static void _onQuickAction(BuildContext context, String label) {
    switch (label) {
      case 'Members':
        fhcPush(context, FhcRoutes.churchMembers);
      case 'Activities':
        fhcPush(context, FhcRoutes.events);
      case 'Prayer':
        fhcPush(context, FhcRoutes.prayer);
      case 'Messages':
        fhcPush(context, FhcRoutes.messages);
      case 'Report':
        fhcPush(context, FhcRoutes.churchDocuments);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: 'MY HOME CHURCH',
            onBack: () => _goBack(context),
            trailing: PopupMenuButton<String>(
              tooltip: 'More',
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, size: 22, color: FhcColors.ink),
              onSelected: (value) => _onMore(context, value),
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(value: 'settings', child: Text('Settings')),
                    PopupMenuItem(
                      value: 'profile',
                      child: Text('View Profile'),
                    ),
                  ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              children: [
                _ChurchCard(
                  onTap: () => fhcPush(context, FhcRoutes.churchDetail),
                ),
                const SizedBox(height: 14),
                const Text(
                  'This Month',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: _AttendanceCard()),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReportsDueCard(
                        onView:
                            () => fhcPush(context, FhcRoutes.churchDocuments),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Quick Actions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                _QuickActionsGrid(
                  onTap: (label) => _onQuickAction(context, label),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Upcoming Activity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                _MeetingCard(
                  onTap: () => fhcPush(context, FhcRoutes.eventDetail),
                ),
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 0),
        ],
      ),
    );
  }
}

class _ChurchCard extends StatelessWidget {
  const _ChurchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.card),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                _AssetPhoto(
                  primary: 'assets/images/grace_home_church.png',
                  fallback: 'assets/images/home_church_grace.png',
                  size: 56,
                  icon: Icons.church_outlined,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grace Home Church',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Home Church • Lagos, Nigeria',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      _ActiveBadge(),
                    ],
                  ),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FhcColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Active',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: FhcColors.green,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard();

  @override
  Widget build(BuildContext context) {
    return const FhcSurfaceCard(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: FhcColors.muted, height: 1.2),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '23',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6),
              _MiniBars(),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '+12%',
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

class _MiniBars extends StatelessWidget {
  const _MiniBars();

  static const _heights = <double>[8, 12, 16, 20, 26];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _heights.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 4,
              height: _heights[i],
              decoration: BoxDecoration(
                color: FhcColors.green,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportsDueCard extends StatelessWidget {
  const _ReportsDueCard({required this.onView});

  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reports Due',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: FhcColors.muted, height: 1.2),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.assignment_outlined, size: 18, color: FhcColors.green),
              SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '2',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            child: FilledButton(
              onPressed: onView,
              style: FilledButton.styleFrom(
                backgroundColor: FhcColors.green,
                foregroundColor: FhcColors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.button),
                ),
              ),
              child: const Text(
                'View',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.onTap});

  final ValueChanged<String> onTap;

  static const _items = <(IconData, String)>[
    (Icons.how_to_reg_outlined, 'Attendance'),
    (Icons.assignment_turned_in_outlined, 'Report'),
    (Icons.groups_outlined, 'Members'),
    (Icons.workspace_premium_outlined, 'Activities'),
    (Icons.volunteer_activism_outlined, 'Prayer'),
    (Icons.forum_outlined, 'Messages'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: _items[i].$1,
                  label: _items[i].$2,
                  onTap: () => onTap(_items[i].$2),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 3; i < 6; i++) ...[
              if (i > 3) const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: _items[i].$1,
                  label: _items[i].$2,
                  onTap: () => onTap(_items[i].$2),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.card),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                children: [
                  Icon(icon, color: FhcColors.green, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: FhcColors.ink,
                      height: 1.2,
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

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.card),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                _AssetPhoto(
                  primary: 'assets/images/home_church_meeting.png',
                  fallback: 'assets/images/church_house.png',
                  size: 52,
                  icon: Icons.home_work_outlined,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home Church Meeting',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'May 24, 2025 • 6:00 PM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20, color: FhcColors.hint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetPhoto extends StatelessWidget {
  const _AssetPhoto({
    required this.primary,
    required this.fallback,
    required this.size,
    required this.icon,
  });

  final String primary;
  final String fallback;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FhcRadius.sm),
      child: Image.asset(
        primary,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Image.asset(
              fallback,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => ColoredBox(
                    color: FhcColors.mint,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Icon(
                        icon,
                        color: FhcColors.green,
                        size: size * 0.45,
                      ),
                    ),
                  ),
            ),
      ),
    );
  }
}

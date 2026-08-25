import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class CrusadeDetailScreen extends StatefulWidget {
  const CrusadeDetailScreen({super.key});

  @override
  State<CrusadeDetailScreen> createState() => _CrusadeDetailScreenState();
}

class _CrusadeDetailScreenState extends State<CrusadeDetailScreen> {
  int _tab = 0;

  static const _tabs = ['Overview', 'Souls', 'Schedule', 'Team'];

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.mission);
    }
  }

  void _openSouls() => fhcPush(context, FhcRoutes.souls);

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: 'ABUJA CITY CRUSADE',
            onBack: _onBack,
            trailing: IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.share_outlined, size: 22),
              color: FhcColors.ink,
              tooltip: 'Share',
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const _CrusadeHero(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _TitleBlock(),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _StatsRow(),
                ),
                ColoredBox(
                  color: FhcColors.white,
                  child: Row(
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _TabLabel(
                            label: _tabs[i],
                            active: _tab == i,
                            onTap: () => setState(() => _tab = i),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (_tab) {
                    1 => _SoulsTab(onViewSouls: _openSouls),
                    2 => const _ScheduleTab(),
                    3 => const _TeamTab(),
                    _ => const _OverviewTab(),
                  },
                ),
              ],
            ),
          ),
          _FooterActions(
            onAddSoul: () {},
            onFollowUp: _openSouls,
            onViewSouls: _openSouls,
            onShare: () {},
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _CrusadeHero extends StatelessWidget {
  const _CrusadeHero();

  static const _fallback = ColoredBox(
    color: FhcColors.greenDeep,
    child: Center(
      child: Icon(Icons.campaign_outlined, size: 56, color: FhcColors.white),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: SizedBox(
          height: 132,
          width: double.infinity,
          child: Image.asset(
            'assets/images/abuja_crusade.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/crusade_crowd.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => _fallback,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Abuja City Crusade',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: FhcColors.ink,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'May 20 – 23, 2025  •  Eagle Square, Abuja',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            height: 1.3,
            color: FhcColors.muted,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Souls Reached', value: '1,250'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StatCard(label: 'New Conversions', value: '124'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StatCard(label: 'Volunteers', value: '85'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
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

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: active ? FhcColors.green : FhcColors.ink,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        const Text(
          'Description',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'A city-wide evangelism outreach in Abuja focused on winning souls and raising strong disciples.',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: FhcColors.muted,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Location',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Eagle Square, Abuja',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: FhcColors.muted,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Lead Pastor',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pastor John David',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: FhcColors.muted,
          ),
        ),
      ],
    );
  }
}

class _SoulsTab extends StatelessWidget {
  const _SoulsTab({required this.onViewSouls});

  final VoidCallback onViewSouls;

  static const _souls = <(String, String, String)>[
    ('Mary A. Okafor', 'New convert', 'May 23'),
    ('Daniel Dandeli', 'Follow-up', 'May 22'),
    ('Joy Naro', 'New convert', 'May 21'),
    ('Tunde Adeboyo', 'Mentor assigned', 'May 20'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (var i = 0; i < _souls.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: FhcColors.border),
                _PersonRow(
                  title: _souls[i].$1,
                  subtitle: _souls[i].$2,
                  value: _souls[i].$3,
                  icon: Icons.favorite_outline,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        FhcPrimaryButton(label: 'View Souls', onPressed: onViewSouls),
      ],
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab();

  static const _days = <(String, String, String)>[
    ('Day 1 • Opening Rally', 'May 20, 2025 • 6:00 PM', 'Eagle Square, Abuja'),
    ('Day 2 • City Outreach', 'May 21, 2025 • 6:00 PM', 'Garki & Wuse'),
    (
      'Day 3 • Healing Service',
      'May 22, 2025 • 6:00 PM',
      'Eagle Square, Abuja',
    ),
    ('Day 4 • Thanksgiving', 'May 23, 2025 • 5:00 PM', 'Eagle Square, Abuja'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (var i = 0; i < _days.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: FhcColors.border),
                _PersonRow(
                  title: _days[i].$1,
                  subtitle: '${_days[i].$2} • ${_days[i].$3}',
                  value: i == 0 ? 'Next' : '',
                  icon: Icons.event_outlined,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamTab extends StatelessWidget {
  const _TeamTab();

  static const _team = <(String, String, String)>[
    ('Pastor John David', 'Crusade Lead', 'Lead'),
    ('Sister Mary', 'Follow-up', 'Mentor'),
    ('Bro John', 'Soul capture', 'Worker'),
    ('Pastor Grace', 'Counselling', 'Lead'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '85 volunteers serving this crusade',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: FhcColors.muted, height: 1.2),
          ),
        ),
        FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (var i = 0; i < _team.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: FhcColors.border),
                _PersonRow(
                  title: _team[i].$1,
                  subtitle: _team[i].$2,
                  value: _team[i].$3,
                  icon: Icons.groups_outlined,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FhcColors.mint,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: FhcColors.green, size: 20),
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
          if (value.isNotEmpty) ...[
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
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.onAddSoul,
    required this.onFollowUp,
    required this.onViewSouls,
    required this.onShare,
  });

  final VoidCallback onAddSoul;
  final VoidCallback onFollowUp;
  final VoidCallback onViewSouls;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FhcColors.white,
        border: Border(top: BorderSide(color: FhcColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _OutlinedAction(
                    icon: Icons.person_add_alt_1,
                    label: 'Add Soul',
                    onTap: onAddSoul,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OutlinedAction(
                    icon: Icons.assignment_outlined,
                    label: 'Follow-up',
                    onTap: onFollowUp,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OutlinedAction(
                    icon: Icons.groups_outlined,
                    label: 'View Souls',
                    onTap: onViewSouls,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OutlinedAction(
                    icon: Icons.ios_share,
                    label: 'Share',
                    onTap: onShare,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FhcPrimaryButton(label: 'Create Report', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FhcColors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.sm),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FhcRadius.sm),
            border: Border.all(color: FhcColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: FhcColors.green, size: 20),
                const SizedBox(height: 4),
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
      ),
    );
  }
}

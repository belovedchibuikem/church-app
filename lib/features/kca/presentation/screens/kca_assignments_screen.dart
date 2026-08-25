import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

enum _Priority { high, medium, low }

class KcaAssignmentsScreen extends StatefulWidget {
  const KcaAssignmentsScreen({super.key});

  @override
  State<KcaAssignmentsScreen> createState() => _KcaAssignmentsScreenState();
}

class _KcaAssignmentsScreenState extends State<KcaAssignmentsScreen> {
  int _tab = 0;

  static const _tabs = <(String, int)>[
    ('Pending', 2),
    ('Submitted', 4),
    ('Completed', 6),
  ];

  static const _pending = <_Assignment>[
    _Assignment(
      title: 'Leadership Reflection',
      module: 8,
      dateLabel: 'Due May 30, 2025',
      priority: _Priority.high,
      icon: Icons.description_outlined,
      iconColor: FhcColors.orange,
    ),
    _Assignment(
      title: 'Ministry Project Plan',
      module: 9,
      dateLabel: 'Due Jun 2, 2025',
      priority: _Priority.medium,
      icon: Icons.assignment_outlined,
      iconColor: FhcColors.greenDark,
    ),
    _Assignment(
      title: 'Community Outreach Report',
      module: 7,
      dateLabel: 'Due Jun 5, 2025',
      priority: _Priority.low,
      icon: Icons.work_outline,
      iconColor: FhcColors.green,
    ),
  ];

  static const _submitted = <_Assignment>[
    _Assignment(
      title: 'Discipleship Journal',
      module: 6,
      dateLabel: 'Submitted May 22, 2025',
      priority: _Priority.medium,
      icon: Icons.menu_book_outlined,
      iconColor: FhcColors.purple,
    ),
    _Assignment(
      title: 'Prayer Walk Evidence',
      module: 7,
      dateLabel: 'Submitted May 20, 2025',
      priority: _Priority.high,
      icon: Icons.directions_walk_outlined,
      iconColor: FhcColors.orange,
    ),
    _Assignment(
      title: 'Servant Leadership Essay',
      module: 6,
      dateLabel: 'Submitted May 18, 2025',
      priority: _Priority.low,
      icon: Icons.description_outlined,
      iconColor: FhcColors.blue,
    ),
    _Assignment(
      title: 'Home Visit Notes',
      module: 5,
      dateLabel: 'Submitted May 16, 2025',
      priority: _Priority.medium,
      icon: Icons.home_work_outlined,
      iconColor: FhcColors.green,
    ),
  ];

  static const _completed = <_Assignment>[
    _Assignment(
      title: 'Identity Statement',
      module: 5,
      dateLabel: 'Completed May 10, 2025',
      priority: _Priority.high,
      icon: Icons.check_circle_outline,
      iconColor: FhcColors.green,
    ),
    _Assignment(
      title: 'Calling Map',
      module: 5,
      dateLabel: 'Completed May 8, 2025',
      priority: _Priority.medium,
      icon: Icons.map_outlined,
      iconColor: FhcColors.blue,
    ),
    _Assignment(
      title: 'Spiritual Gifts Inventory',
      module: 4,
      dateLabel: 'Completed May 4, 2025',
      priority: _Priority.low,
      icon: Icons.card_giftcard_outlined,
      iconColor: FhcColors.purple,
    ),
    _Assignment(
      title: 'Testimony Script',
      module: 4,
      dateLabel: 'Completed May 1, 2025',
      priority: _Priority.medium,
      icon: Icons.record_voice_over_outlined,
      iconColor: FhcColors.orange,
    ),
    _Assignment(
      title: 'Kingdom Values Reflection',
      module: 3,
      dateLabel: 'Completed Apr 24, 2025',
      priority: _Priority.low,
      icon: Icons.favorite_border,
      iconColor: FhcColors.green,
    ),
    _Assignment(
      title: 'Mentoring Agreement',
      module: 2,
      dateLabel: 'Completed Apr 18, 2025',
      priority: _Priority.high,
      icon: Icons.handshake_outlined,
      iconColor: FhcColors.blue,
    ),
  ];

  List<_Assignment> get _items => switch (_tab) {
    1 => _submitted,
    2 => _completed,
    _ => _pending,
  };

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.kca);
    }
  }

  void _openLesson() => fhcPush(context, FhcRoutes.kcaLesson);

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(title: 'MY ASSIGNMENTS', onBack: _back),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _StatusTab(
                      label: '${_tabs[i].$1} (${_tabs[i].$2})',
                      active: _tab == i,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _AssignmentCard(
                  assignment: items[index],
                  onTap: _openLesson,
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

class _Assignment {
  const _Assignment({
    required this.title,
    required this.module,
    required this.dateLabel,
    required this.priority,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final int module;
  final String dateLabel;
  final _Priority priority;
  final IconData icon;
  final Color iconColor;
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.sm),
          child: Ink(
            height: 36,
            decoration: BoxDecoration(
              color: active ? FhcColors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(FhcRadius.sm),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? FhcColors.white : FhcColors.muted,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment, required this.onTap});

  final _Assignment assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = 'Module ${assignment.module} • ${assignment.dateLabel}';

    return Semantics(
      button: true,
      label: '${assignment.title}, $meta',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.card),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: FhcColors.white,
              borderRadius: BorderRadius.circular(FhcRadius.card),
              border: Border.all(color: FhcColors.border),
              boxShadow: FhcElevation.card,
            ),
            child: Row(
              children: [
                _ColorIcon(icon: assignment.icon, color: assignment.iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PriorityPill(priority: assignment.priority),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorIcon extends StatelessWidget {
  const _ColorIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(FhcRadius.sm),
      ),
      child: Icon(icon, size: 20, color: FhcColors.white),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final _Priority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      _Priority.high => ('High', FhcColors.red),
      _Priority.medium => ('Medium', FhcColors.gold),
      _Priority.low => ('Low', FhcColors.green),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

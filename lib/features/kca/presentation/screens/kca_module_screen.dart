import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

enum _LessonState { completed, inProgress, locked }

class KcaModuleScreen extends StatefulWidget {
  const KcaModuleScreen({super.key});

  @override
  State<KcaModuleScreen> createState() => _KcaModuleScreenState();
}

class _KcaModuleScreenState extends State<KcaModuleScreen> {
  int _tab = 0;

  static const _tabs = ['Lessons', 'Resources', 'Assignments'];

  static const _lessons = <_LessonSpec>[
    _LessonSpec(1, "Created in God's Image", _LessonState.completed),
    _LessonSpec(2, 'Who You Are in Christ', _LessonState.completed),
    _LessonSpec(3, 'Discovering Your Calling', _LessonState.completed),
    _LessonSpec(4, 'Walking in Purpose', _LessonState.inProgress),
    _LessonSpec(5, 'Spiritual Gifts', _LessonState.locked),
    _LessonSpec(6, 'Kingdom Identity', _LessonState.locked),
    _LessonSpec(7, 'False Identities', _LessonState.locked),
    _LessonSpec(8, 'Purpose in Community', _LessonState.locked),
    _LessonSpec(9, 'Stewarding Your Call', _LessonState.locked),
    _LessonSpec(10, 'Living on Mission', _LessonState.locked),
  ];

  static const _resources = <(IconData, String, String)>[
    (Icons.picture_as_pdf_outlined, 'Identity Workbook', 'PDF · 18 pages'),
    (Icons.menu_book_outlined, 'Key Scriptures', 'Study notes'),
    (Icons.headphones_outlined, 'Session Audio', '42 min'),
    (Icons.person_outline, 'Mentor Guide', 'PDF · 6 pages'),
  ];

  static const _assignments = <(String, String, String)>[
    ('Practical Assignment', 'Share your testimony this week', 'Due Fri'),
    ('Written Assessment', 'Write your identity statement', 'Due Sun'),
    ('Spiritual Assignment', 'Pray through Module 5 scriptures', 'Due Sun'),
  ];

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.kcaModules);
    }
  }

  void _openLesson() => fhcPush(context, FhcRoutes.kcaLesson);

  void _openAssignments() => fhcPush(context, FhcRoutes.kcaAssignments);

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(title: 'Module 5', onBack: _back),
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _ModuleProgressCard(),
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
                    1 => _ResourcesTab(items: _resources),
                    2 => _AssignmentsTab(
                      items: _assignments,
                      onOpen: _openAssignments,
                    ),
                    _ => _LessonsTab(
                      lessons: _lessons,
                      onContinue: _openLesson,
                    ),
                  },
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

class _ModuleProgressCard extends StatelessWidget {
  const _ModuleProgressCard();

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Identity & Purpose',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Module 5',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: FhcColors.muted, height: 1.2),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Text(
                '60%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.greenDark,
                  height: 1,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '6 of 10 lessons',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: FhcColors.muted,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.6,
              minHeight: 8,
              backgroundColor: FhcColors.border,
              valueColor: AlwaysStoppedAnimation(FhcColors.green),
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
            fontSize: 12,
            color: active ? FhcColors.green : FhcColors.muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _LessonSpec {
  const _LessonSpec(this.number, this.title, this.state);

  final int number;
  final String title;
  final _LessonState state;
}

class _LessonsTab extends StatelessWidget {
  const _LessonsTab({required this.lessons, required this.onContinue});

  final List<_LessonSpec> lessons;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return _LessonRow(
                lesson: lesson,
                onTap:
                    lesson.state == _LessonState.inProgress ? onContinue : null,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: FhcPrimaryButton(
            label: 'Continue Lesson 4',
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, this.onTap});

  final _LessonSpec lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = lesson.state == _LessonState.locked;
    final inProgress = lesson.state == _LessonState.inProgress;
    final icon = switch (lesson.state) {
      _LessonState.completed => Icons.check_circle,
      _LessonState.inProgress => Icons.play_circle_fill,
      _LessonState.locked => Icons.lock_outline,
    };
    final iconColor = switch (lesson.state) {
      _LessonState.completed => FhcColors.green,
      _LessonState.inProgress => FhcColors.gold,
      _LessonState.locked => FhcColors.hint,
    };
    final status = switch (lesson.state) {
      _LessonState.completed => 'Completed',
      _LessonState.inProgress => 'In Progress',
      _LessonState.locked => 'Locked',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: FhcColors.white,
            borderRadius: BorderRadius.circular(FhcRadius.card),
            border: Border.all(
              color: inProgress ? FhcColors.green : FhcColors.border,
            ),
            boxShadow: FhcElevation.card,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lesson ${lesson.number}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: locked ? FhcColors.hint : FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: locked ? FhcColors.hint : FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color:
                        inProgress
                            ? FhcColors.green
                            : locked
                            ? FhcColors.hint
                            : FhcColors.muted,
                    height: 1.2,
                  ),
                ),
                if (inProgress)
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
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

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab({required this.items});

  final List<(IconData, String, String)> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return FhcSurfaceCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              FhcCircleIcon(icon: item.$1, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
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
                      item.$3,
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
              const Icon(Icons.chevron_right, size: 18, color: FhcColors.muted),
            ],
          ),
        );
      },
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({required this.items, required this.onOpen});

  final List<(String, String, String)> items;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpen,
                  borderRadius: BorderRadius.circular(FhcRadius.card),
                  child: FhcSurfaceCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                    child: Row(
                      children: [
                        const FhcCircleIcon(
                          icon: Icons.assignment_outlined,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$1,
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
                                item.$2,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: FhcColors.muted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: FhcColors.green,
                            height: 1.2,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: FhcColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: FhcPrimaryButton(label: 'View Assignments', onPressed: onOpen),
        ),
      ],
    );
  }
}

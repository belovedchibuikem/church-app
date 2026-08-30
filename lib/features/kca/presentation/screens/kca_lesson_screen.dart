import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class KcaLessonScreen extends StatelessWidget {
  const KcaLessonScreen({super.key});

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.kcaModule);
    }
  }

  void _onContinue(BuildContext context) {
    fhcPush(context, FhcRoutes.kcaAssignments);
  }

  @override
  Widget build(BuildContext context) {
    final items = <_LessonItem>[
      _LessonItem(
        icon: Icons.play_arrow_rounded,
        label: fhcT(
          context,
          'member.kca.videoLesson',
          fallback: 'Video Lesson',
        ),
        done: true,
      ),
      _LessonItem(
        icon: Icons.description_outlined,
        label: fhcT(context, 'member.kca.studyNotes', fallback: 'Study Notes'),
        done: true,
      ),
      _LessonItem(
        icon: Icons.menu_book_outlined,
        label: fhcT(
          context,
          'member.kca.keyScriptures',
          fallback: 'Key Scriptures',
        ),
        done: true,
      ),
      _LessonItem(
        icon: Icons.assignment_outlined,
        label: fhcT(
          context,
          'member.kca.practicalAssignment',
          fallback: 'Practical Assignment',
        ),
        done: false,
      ),
      _LessonItem(
        icon: Icons.quiz_outlined,
        label: fhcT(context, 'member.kca.quiz', fallback: 'Quiz'),
        done: false,
      ),
    ];

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'member.kca.leadershipInfluence',
              fallback: 'LEADERSHIP & INFLUENCE',
            ),
            onBack: () => _onBack(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                Text(
                  fhcT(
                    context,
                    'member.kca.moduleOf',
                    args: {'current': '8', 'total': '12'},
                    fallback: 'Module {current} of {total}',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: FhcColors.muted,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const _VideoPlayer(),
                const SizedBox(height: 18),
                Text(
                  fhcT(
                    context,
                    'member.kca.lessonContent',
                    fallback: 'Lesson Content',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                FhcSurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: FhcColors.border),
                        _ChecklistRow(item: items[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: FhcPrimaryButton(
              label: fhcT(context, 'common.continue', fallback: 'Continue'),
              onPressed: () => _onContinue(context),
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _LessonItem {
  const _LessonItem({
    required this.icon,
    required this.label,
    required this.done,
  });

  final IconData icon;
  final String label;
  final bool done;
}

class _VideoPlayer extends StatelessWidget {
  const _VideoPlayer();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FhcRadius.card),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _LessonPhoto(),
            const ColoredBox(color: Color(0x40000000)),
            const Center(child: _PlayOverlay()),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '18:45',
                    style: TextStyle(
                      color: FhcColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const LinearProgressIndicator(
                      value: 0.38,
                      minHeight: 3,
                      backgroundColor: Color(0x66FFFFFF),
                      valueColor: AlwaysStoppedAnimation(FhcColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonPhoto extends StatelessWidget {
  const _LessonPhoto();

  static const _fallback = ColoredBox(color: FhcColors.navy);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/kca_teacher.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/lesson_video.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/live_pastor.png',
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

class _PlayOverlay extends StatelessWidget {
  const _PlayOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: FhcColors.white.withValues(alpha: 0.94),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 36,
        color: FhcColors.green,
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item});

  final _LessonItem item;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FhcColors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(item.icon, size: 16, color: FhcColors.white),
            ),
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
            const SizedBox(width: 8),
            if (item.done)
              const Icon(Icons.check_circle, size: 20, color: FhcColors.green)
            else
              Text(
                fhcT(context, 'member.kca.pending', fallback: 'Pending'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: FhcColors.hint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

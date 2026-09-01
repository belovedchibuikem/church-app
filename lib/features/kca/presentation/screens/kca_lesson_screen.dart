import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class KcaLessonScreen extends StatefulWidget {
  const KcaLessonScreen({super.key, this.lessonId, this.kcaRepository, this.chapter = false});

  final String? lessonId;
  final KcaRepository? kcaRepository;
  final bool chapter;

  @override
  State<KcaLessonScreen> createState() => _KcaLessonScreenState();
}

class _KcaLessonScreenState extends State<KcaLessonScreen> {
  bool _busy = false;
  bool _loading = true;
  bool _started = false;
  String? _error;
  JsonObject? _lesson;

  KcaRepository? get _repo =>
      widget.kcaRepository ??
      AppServicesScope.maybeOf(context)?.kcaRepository;

  String? get _lessonId {
    final explicit = widget.lessonId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return FhcRouteArgs.entityIdOf(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final id = _lessonId;
    final repo = _repo;
    if (id == null || id.isEmpty || repo == null) {
      setState(() {
        _loading = false;
        _error = 'Lesson id is required.';
      });
      return;
    }
    await repo.syncQueuedCompletions();
    final result = widget.chapter
        ? await repo.getChapter(id)
        : await repo.getLesson(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _lesson = value;
          _loading = false;
        });
      case AppError(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.kcaModule);
    }
  }

  Future<void> _onContinue(BuildContext context) async {
    final id = _lessonId;
    final repo = _repo;
    if (id == null || id.isEmpty || repo == null) {
      fhcPush(context, FhcRoutes.kcaAssignments);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = widget.chapter
        ? await repo.completeChapter(
            id,
            acknowledged: true,
            unlockToken: '${_lesson?['unlock_token'] ?? ''}',
          )
        : await repo.completeLesson(
      id,
      acknowledged: true,
      unlockToken: '${_lesson?['unlock_token'] ?? ''}',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case AppSuccess():
        fhcPush(context, FhcRoutes.kcaAssignments);
      case AppError(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = '${_lesson?['title'] ?? ''}'.trim();
    final body = '${_lesson?['body'] ?? _lesson?['summary'] ?? ''}'.trim();
    final contentUrl = '${_lesson?['content_url'] ?? ''}'.trim();
    final chaptersRaw = _lesson?['chapters'];
    final chapters = <Map<String, Object?>>[];
    if (chaptersRaw is List) {
      for (final item in chaptersRaw) {
        if (item is Map) {
          chapters.add(Map<String, Object?>.from(item.map((k, v) => MapEntry('$k', v))));
        }
      }
    }

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: title.isEmpty
                ? fhcT(context, 'member.kca.lessonContent', fallback: 'Lesson')
                : title,
            onBack: () => _onBack(context),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      if (contentUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const _VideoPlayer(),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        body.isEmpty
                            ? fhcT(
                                context,
                                'member.kca.lessonContent',
                                fallback: 'Lesson body is empty.',
                              )
                            : body,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: FhcColors.ink,
                        ),
                      ),
                      if (chapters.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          fhcT(context, 'member.kca.chapters', fallback: 'Chapters'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: FhcColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final chapter in chapters)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${chapter['title'] ?? 'Chapter'}'),
                            subtitle: Text(
                              chapter['completed'] == true
                                  ? 'Completed'
                                  : chapter['unlocked'] == false
                                  ? 'Locked'
                                  : 'Open',
                            ),
                            onTap: '${chapter['id'] ?? ''}'.isEmpty
                                ? null
                                : () => Navigator.of(context).pushNamed(
                                    '/kca/chapter/${chapter['id']}',
                                  ),
                          ),
                      ],
                    ],
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _error!,
                style: const TextStyle(color: FhcColors.muted, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: FhcPrimaryButton(
              label: _busy
                  ? fhcT(context, 'common.saving', fallback: 'Saving…')
                  : fhcT(context, 'common.continue', fallback: 'Continue'),
              onPressed: _busy ? null : () => _onContinue(context),
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

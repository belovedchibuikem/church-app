import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/offline/offline_policy.dart';
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
  AppFailure? _failure;
  JsonObject? _lesson;
  double _fontScale = 1;

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
        _failure = const ValidationFailure('Lesson id is required.');
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
          _failure = null;
        });
      case AppError(:final failure):
        setState(() {
          _failure = failure;
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
      _failure = null;
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
        setState(() => _failure = failure);
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
                : _lesson == null
                ? FhcErrorState(
                    title:
                        _failure is OfflineFailure
                            ? fhcT(
                              context,
                              'account.youreOfflineHeadline',
                              fallback: 'You’re offline',
                            )
                            : fhcT(
                              context,
                              'errors.somethingWentWrong',
                              fallback: 'Something went wrong',
                            ),
                    message:
                        _failure?.message ??
                        OfflinePolicy.notDownloadedMessage,
                    onRetry: _load,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Zoom out',
                            onPressed: () => setState(() {
                              _fontScale = (_fontScale - 0.1).clamp(0.85, 1.6);
                            }),
                            icon: const Icon(Icons.text_decrease),
                          ),
                          Text('${(_fontScale * 100).round()}%'),
                          IconButton(
                            tooltip: 'Zoom in',
                            onPressed: () => setState(() {
                              _fontScale = (_fontScale + 0.1).clamp(0.85, 1.6);
                            }),
                            icon: const Icon(Icons.text_increase),
                          ),
                        ],
                      ),
                      if (contentUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _LessonMediaCard(contentUrl: contentUrl),
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
                        style: TextStyle(
                          fontSize: 15 * _fontScale,
                          height: 1.7,
                          color: FhcColors.ink,
                          letterSpacing: 0.1,
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
                                  ? fhcT(
                                      context,
                                      'member.kca.completed',
                                      fallback: 'Completed',
                                    )
                                  : chapter['unlocked'] == false
                                  ? fhcT(
                                      context,
                                      'member.kca.locked',
                                      fallback: 'Locked',
                                    )
                                  : fhcT(
                                      context,
                                      'member.kca.open',
                                      fallback: 'Open',
                                    ),
                            ),
                            onTap: '${chapter['id'] ?? ''}'.isEmpty ||
                                chapter['unlocked'] == false
                                ? null
                                : () => Navigator.of(context).pushNamed(
                                    '/kca/chapter/${chapter['id']}',
                                  ),
                          ),
                      ],
                    ],
                  ),
          ),
          if (_failure != null && _lesson != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _failure!.message,
                style: const TextStyle(color: FhcColors.muted, fontSize: 12),
              ),
            ),
          if (_lesson != null)
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

class _LessonMediaCard extends StatelessWidget {
  const _LessonMediaCard({required this.contentUrl});

  final String contentUrl;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(contentUrl);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'member.kca.resourceOpenFailed',
              fallback: 'Could not open the lesson resource.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FhcRadius.card),
            border: Border.all(color: FhcColors.border),
            boxShadow: FhcElevation.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(FhcRadius.card),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _LessonPhoto(),
                  const ColoredBox(color: Color(0x40000000)),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _PlayOverlay(),
                        const SizedBox(height: 10),
                        Text(
                          fhcT(
                            context,
                            'member.kca.openLessonResource',
                            fallback: 'Open lesson resource',
                          ),
                          style: const TextStyle(
                            color: FhcColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
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

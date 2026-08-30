import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class KcaModuleScreen extends StatefulWidget {
  const KcaModuleScreen({super.key, this.moduleId, this.kcaRepository});

  final String? moduleId;
  final KcaRepository? kcaRepository;

  @override
  State<KcaModuleScreen> createState() => _KcaModuleScreenState();
}

class _KcaModuleScreenState extends State<KcaModuleScreen> {
  int _tab = 0;
  FhcAsyncValue<_ModuleDetail> _state = const FhcAsyncValue.loading();

  KcaRepository? get _repo =>
      widget.kcaRepository ??
      AppServicesScope.maybeOf(context)?.kcaRepository;

  String? get _resolvedId {
    final explicit = widget.moduleId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final fromArgs = FhcRouteArgs.entityIdOf(context);
    if (fromArgs != null && fromArgs.trim().isNotEmpty) return fromArgs.trim();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is FhcRouteArgs && args.extra is String) {
      final extra = (args.extra as String).trim();
      if (extra.isNotEmpty) return extra;
    }
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final id = args['id'] ?? args['moduleId'] ?? args['entityId'];
      if (id is String && id.trim().isNotEmpty) return id.trim();
    }

    final name = ModalRoute.of(context)?.settings.name ?? '';
    final uri = Uri.tryParse(name);
    final queryId = uri?.queryParameters['id'];
    if (queryId != null && queryId.trim().isNotEmpty) return queryId.trim();

    final parts = name.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 3 && parts[0] == 'kca' && parts[1] == 'module') {
      return parts[2].split('?').first;
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) {
      _load();
    }
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.kca.moduleRequireApi',
            fallback:
                'KCA module detail requires the member curriculum API. '
                'No design fixtures are shown.',
          ),
        );
      });
      return;
    }

    final id = _resolvedId;
    if (id == null || id.isEmpty) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.kca.openModuleFromList',
            fallback:
                'Open a module from the KCA modules list so its public id can be loaded.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.getModule(id);
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        setState(() => _state = FhcAsyncValue.data(_ModuleDetail.fromJson(value)));
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.kcaModules);
    }
  }

  void _openAssignments() => fhcPush(context, FhcRoutes.kcaAssignments);

  @override
  Widget build(BuildContext context) {
    final moduleLabel = fhcT(
      context,
      'member.kca.module',
      fallback: 'Module',
    );
    final tabs = [
      fhcT(context, 'member.kca.lessons', fallback: 'Lessons'),
      fhcT(context, 'member.kca.resources', fallback: 'Resources'),
      fhcT(context, 'member.kca.assignments', fallback: 'Assignments'),
    ];

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: switch (_state) {
              FhcAsyncData(:final value) =>
                value.sequence == null
                    ? moduleLabel
                    : fhcT(
                      context,
                      'member.kca.moduleN',
                      args: {'n': '${value.sequence}'},
                      fallback: 'Module {n}',
                    ),
              _ => moduleLabel,
            },
            onBack: _back,
          ),
          Expanded(
            child: FhcAsyncBody<_ModuleDetail>(
              value: _state,
              onRetry: _load,
              unavailableTitle: fhcT(
                context,
                'member.kca.moduleUnavailable',
                fallback: 'Module unavailable',
              ),
              emptyTitle: fhcT(
                context,
                'member.kca.moduleNotFound',
                fallback: 'Module not found',
              ),
              builder: (context, detail) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _ModuleProgressCard(detail: detail),
                    ),
                    ColoredBox(
                      color: FhcColors.white,
                      child: Row(
                        children: [
                          for (var i = 0; i < tabs.length; i++)
                            Expanded(
                              child: _TabLabel(
                                label: tabs[i],
                                active: _tab == i,
                                onTap: () => setState(() => _tab = i),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: switch (_tab) {
                        1 => const _ResourcesTab(),
                        2 => _AssignmentsTab(onOpen: _openAssignments),
                        _ => _LessonsTab(lessons: detail.lessons),
                      },
                    ),
                  ],
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

class _ModuleDetail {
  const _ModuleDetail({
    required this.id,
    required this.title,
    required this.code,
    required this.sequence,
    required this.lessons,
  });

  factory _ModuleDetail.fromJson(Map<String, Object?> json) {
    final lessonsRaw = json['lessons'];
    final lessons = <_LessonSpec>[];
    if (lessonsRaw is List) {
      for (var i = 0; i < lessonsRaw.length; i++) {
        final item = lessonsRaw[i];
        if (item is! Map) continue;
        final map = Map<String, Object?>.from(
          item.map((k, v) => MapEntry('$k', v)),
        );
        final sequence = map['sequence'];
        final number =
            sequence is int
                ? sequence
                : sequence is num
                ? sequence.round()
                : i + 1;
        lessons.add(
          _LessonSpec(
            id: '${map['id'] ?? ''}',
            number: number,
            title: '${map['title'] ?? map['code'] ?? 'Lesson'}',
          ),
        );
      }
    }
    final sequence = json['sequence'];
    return _ModuleDetail(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? json['code'] ?? 'Module'}',
      code: '${json['code'] ?? ''}',
      sequence:
          sequence is int
              ? sequence
              : sequence is num
              ? sequence.round()
              : null,
      lessons: lessons,
    );
  }

  final String id;
  final String title;
  final String code;
  final int? sequence;
  final List<_LessonSpec> lessons;
}

class _ModuleProgressCard extends StatelessWidget {
  const _ModuleProgressCard({required this.detail});

  final _ModuleDetail detail;

  @override
  Widget build(BuildContext context) {
    final count = detail.lessons.length;
    final sequenceLabel =
        detail.sequence == null
            ? (detail.code.isEmpty
                ? fhcT(
                  context,
                  'member.kca.publishedModule',
                  fallback: 'Published module',
                )
                : detail.code)
            : fhcT(
              context,
              'member.kca.moduleN',
              args: {'n': '${detail.sequence}'},
              fallback: 'Module {n}',
            );
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail.sequence == null
                ? sequenceLabel
                : '$sequenceLabel${detail.code.isEmpty ? '' : ' · ${detail.code}'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: FhcColors.muted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            count == 0
                ? fhcT(
                  context,
                  'member.kca.noLessonsPublished',
                  fallback: 'No lessons published yet',
                )
                : count == 1
                ? fhcT(
                  context,
                  'member.kca.lessonCountOne',
                  args: {'count': '$count'},
                  fallback: '{count} lesson',
                )
                : fhcT(
                  context,
                  'member.kca.lessonCount',
                  args: {'count': '$count'},
                  fallback: '{count} lessons',
                ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: FhcColors.greenDark,
              height: 1.2,
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
  const _LessonSpec({
    required this.id,
    required this.number,
    required this.title,
  });

  final String id;
  final int number;
  final String title;
}

class _LessonsTab extends StatelessWidget {
  const _LessonsTab({required this.lessons});

  final List<_LessonSpec> lessons;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return FhcEmptyState(
        title: fhcT(
          context,
          'member.kca.noLessonsYet',
          fallback: 'No lessons yet',
        ),
        message: fhcT(
          context,
          'member.kca.lessonsNotPublished',
          fallback: 'Lessons for this module have not been published.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return _LessonRow(lesson: lesson);
      },
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson});

  final _LessonSpec lesson;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: FhcColors.white,
          borderRadius: BorderRadius.circular(FhcRadius.card),
          border: Border.all(color: FhcColors.border),
          boxShadow: FhcElevation.card,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: FhcColors.green,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fhcT(
                        context,
                        'member.kca.lessonN',
                        args: {'n': '${lesson.number}'},
                        fallback: 'Lesson {n}',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: FhcColors.muted,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
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
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab();

  @override
  Widget build(BuildContext context) {
    return FhcUnavailableState(
      title: fhcT(
        context,
        'member.kca.resourcesUnavailable',
        fallback: 'Resources unavailable',
      ),
      message: fhcT(
        context,
        'member.kca.resourcesUnavailableCopy',
        fallback:
            'Module resources are not exposed on the member curriculum API yet. '
            'No design fixtures are shown.',
      ),
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            fhcT(
              context,
              'member.kca.assignmentsTabCopy',
              fallback:
                  'Enrollment assignments are listed on the assignments screen. '
                  'Per-module assignment filtering is not exposed yet.',
            ),
            style: const TextStyle(
              fontSize: 13,
              color: FhcColors.muted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FhcPrimaryButton(
            label: fhcT(
              context,
              'member.kca.viewAssignments',
              fallback: 'View Assignments',
            ),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

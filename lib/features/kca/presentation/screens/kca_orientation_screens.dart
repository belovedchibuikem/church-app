import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class KcaOrientationHubScreen extends StatefulWidget {
  const KcaOrientationHubScreen({super.key});

  @override
  State<KcaOrientationHubScreen> createState() =>
      _KcaOrientationHubScreenState();
}

class _KcaOrientationHubScreenState extends State<KcaOrientationHubScreen> {
  FhcAsyncValue<JsonObject> _state = const FhcAsyncValue.loading();

  KcaRepository? get _repo =>
      AppServicesScope.maybeOf(context)?.kcaRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.kca.orientationRequiresApi',
            fallback:
                'Orientation requires the authenticated KCA API. No fixture stages are shown.',
          ),
        );
      });
      return;
    }
    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.getOrientation();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() => _state = FhcAsyncValue.data(value));
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  Future<void> _completeOrientation() async {
    final repo = _repo;
    if (repo == null) return;
    final result = await repo.completeOrientation();
    if (!mounted) return;
    switch (result) {
      case AppSuccess():
        await _load();
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  List<JsonObject> _stages(JsonObject payload) {
    final raw = payload['stages'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, Object?>.from(item),
    ];
  }

  String _routeFor(String key) => switch (key) {
        'overview' => FhcRoutes.kcaOrientationOverview,
        'rules' => FhcRoutes.kcaOrientationRules,
        'path' => FhcRoutes.kcaOrientationPath,
        'mentors' => FhcRoutes.kcaOrientationMentors,
        _ => FhcRoutes.kcaOrientationOverview,
      };

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(context, 'member.kca.kcaOrientation', fallback: 'KCA Orientation'),
      domain: WorkflowDomain.kca,
      actionLabel: fhcT(
        context,
        'member.kca.startOrientation',
        fallback: 'Start Orientation',
      ),
      onAction: () {
        final data = _state is FhcAsyncData<JsonObject>
            ? (_state as FhcAsyncData<JsonObject>).value
            : null;
        final stages = data == null ? const <JsonObject>[] : _stages(data);
        final first = stages.isEmpty ? 'overview' : '${stages.first['key'] ?? 'overview'}';
        fhcPush(context, _routeFor(first));
      },
      children: [
        SizedBox(
          height: 520,
          child: FhcAsyncBody<JsonObject>(
            value: _state,
            onRetry: _load,
            emptyTitle: fhcT(
              context,
              'member.kca.orientationUnavailable',
              fallback: 'Orientation unavailable',
            ),
            unavailableTitle: fhcT(
              context,
              'member.kca.orientationUnavailable',
              fallback: 'Orientation unavailable',
            ),
            builder: (context, payload) {
              final welcome = '${payload['welcome'] ?? ''}'.trim();
              final stages = _stages(payload);
              final canComplete = payload['can_complete'] == true;
              final allComplete = stages.isNotEmpty &&
                  stages.every((stage) => stage['completed'] == true);
              final orientationDone = '${payload['orientation_completed_at'] ?? ''}'.trim().isNotEmpty;
              return ListView(
                children: [
                  WorkflowSummary(
                    title: fhcT(
                      context,
                      'member.kca.orientationProgram',
                      fallback: 'Orientation Program',
                    ),
                    subtitle: welcome.isEmpty
                        ? fhcT(
                            context,
                            'member.kca.orientationWelcome',
                            fallback:
                                'Welcome to KCA! Get started with your orientation.',
                          )
                        : welcome,
                    metrics: const [],
                    imageAsset: 'assets/images/connect_people.png',
                  ),
                  const SizedBox(height: 12),
                  WorkflowCard(
                    child: Column(
                      children: [
                        for (final stage in stages)
                          WorkflowRow(
                            title: '${stage['completed'] == true ? '✓ ' : ''}${stage['title'] ?? ''}',
                            subtitle: '${stage['subtitle'] ?? ''}',
                            leading: stage['completed'] == true
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: FhcColors.muted,
                            ),
                            onTap: () => fhcPush(
                              context,
                              _routeFor('${stage['key'] ?? ''}'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (canComplete && allComplete && !orientationDone) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _completeOrientation,
                      child: Text(
                        fhcT(
                          context,
                          'member.kca.submitOrientation',
                          fallback: 'Submit orientation',
                        ),
                      ),
                    ),
                  ],
                  if (orientationDone) ...[
                    const SizedBox(height: 16),
                    Text(
                      fhcT(
                        context,
                        'member.kca.orientationSubmitted',
                        fallback:
                            'Orientation submitted. Track your admission progress from the application status screen.',
                      ),
                      style: FhcTypography.caption,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class KcaOrientationStageScreen extends StatefulWidget {
  const KcaOrientationStageScreen({super.key, required this.stageKey});

  final String stageKey;

  @override
  State<KcaOrientationStageScreen> createState() =>
      _KcaOrientationStageScreenState();
}

class _KcaOrientationStageScreenState extends State<KcaOrientationStageScreen> {
  FhcAsyncValue<JsonObject> _state = const FhcAsyncValue.loading();

  KcaRepository? get _repo =>
      AppServicesScope.maybeOf(context)?.kcaRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message:
              'This orientation stage requires the authenticated KCA API.',
        );
      });
      return;
    }
    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.getOrientation();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() => _state = FhcAsyncValue.data(value));
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  Future<void> _markStageComplete() async {
    final repo = _repo;
    if (repo == null) return;
    final result = await repo.completeOrientationStage(widget.stageKey);
    if (!mounted) return;
    switch (result) {
      case AppSuccess():
        await _load();
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  JsonObject? _stageOf(JsonObject payload) {
    final raw = payload['stages'];
    if (raw is! List) return null;
    for (final item in raw) {
      if (item is Map && '${item['key']}' == widget.stageKey) {
        return Map<String, Object?>.from(item);
      }
    }
    return null;
  }

  void _openModule(String? id) {
    final trimmed = id?.trim() ?? '';
    if (trimmed.isEmpty) return;
    fhcPush(context, '${FhcRoutes.kcaModule}?id=${Uri.encodeComponent(trimmed)}');
  }

  void _openLesson(String? id) {
    final trimmed = id?.trim() ?? '';
    if (trimmed.isEmpty) return;
    fhcPush(context, '${FhcRoutes.kcaLesson}?id=${Uri.encodeComponent(trimmed)}');
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(context, 'member.kca.kcaOrientation', fallback: 'KCA Orientation'),
      domain: WorkflowDomain.kca,
      actionLabel: fhcT(context, 'common.continue', fallback: 'Continue'),
      onAction: () {
        final next = switch (widget.stageKey) {
          'overview' => FhcRoutes.kcaOrientationRules,
          'rules' => FhcRoutes.kcaOrientationPath,
          'path' => FhcRoutes.kcaOrientationMentors,
          _ => FhcRoutes.kcaPracticalService,
        };
        fhcPush(context, next);
      },
      children: [
        SizedBox(
          height: 520,
          child: FhcAsyncBody<JsonObject>(
            value: _state,
            onRetry: _load,
            builder: (context, payload) {
              final stage = _stageOf(payload);
              if (stage == null) {
                return Text(
                  fhcT(
                    context,
                    'member.kca.stageMissing',
                    fallback: 'This orientation stage is not available yet.',
                  ),
                );
              }
              final body = '${stage['body'] ?? ''}'.trim();
              final modules = stage['modules'];
              final mentor = stage['mentor'];
              final canComplete = payload['can_complete'] == true;
              final stageComplete = stage['completed'] == true;
              return ListView(
                children: [
                  Text(
                    '${stage['title'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${stage['subtitle'] ?? ''}',
                    style: FhcTypography.caption,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    WorkflowCard(child: Text(body, style: FhcTypography.body)),
                  ],
                  if (modules is List) ...[
                    const SizedBox(height: 16),
                    WorkflowCard(
                      child: Column(
                        children: [
                          for (final item in modules)
                            if (item is Map)
                              WorkflowRow(
                                title: '${item['title'] ?? item['code'] ?? 'Module'}',
                                subtitle:
                                    '${item['lessons_count'] ?? 0} lessons',
                                leading: Icons.menu_book_outlined,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openModule('${item['id'] ?? ''}'),
                              ),
                        ],
                      ),
                    ),
                  ],
                  if (mentor is Map) ...[
                    const SizedBox(height: 16),
                    WorkflowCard(
                      child: WorkflowRow(
                        title: [
                          '${mentor['preferred_name'] ?? ''}',
                          '${mentor['given_name'] ?? ''}',
                          '${mentor['family_name'] ?? ''}',
                        ].where((part) => part.trim().isNotEmpty).join(' '),
                        subtitle: fhcT(
                          context,
                          'member.kca.assignedMentor',
                          fallback: 'Assigned Mentor',
                        ),
                        leading: Icons.person_outline,
                        onTap: () => fhcPush(context, FhcRoutes.kcaMentor),
                      ),
                    ),
                  ],
                  if ('${stage['lesson_id'] ?? ''}'.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _openLesson('${stage['lesson_id']}'),
                      child: Text(
                        fhcT(
                          context,
                          'member.kca.openLesson',
                          fallback: 'Open this lesson',
                        ),
                      ),
                    ),
                  ] else if ('${stage['module_id'] ?? ''}'.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => _openModule('${stage['module_id']}'),
                      child: Text(
                        fhcT(
                          context,
                          'member.kca.openModule',
                          fallback: 'Open related module',
                        ),
                      ),
                    ),
                  ],
                  if (canComplete && !stageComplete) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _markStageComplete,
                      child: Text(
                        fhcT(
                          context,
                          'member.kca.markStageComplete',
                          fallback: 'Mark stage complete',
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class KcaPracticalServiceScreen extends StatefulWidget {
  const KcaPracticalServiceScreen({super.key});

  @override
  State<KcaPracticalServiceScreen> createState() =>
      _KcaPracticalServiceScreenState();
}

class _KcaPracticalServiceScreenState extends State<KcaPracticalServiceScreen> {
  FhcAsyncValue<JsonObject> _state = const FhcAsyncValue.loading();

  KcaRepository? get _repo =>
      AppServicesScope.maybeOf(context)?.kcaRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message:
              'Practical service requires the authenticated KCA API. '
              'No fixture departments are shown.',
        );
      });
      return;
    }
    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.getPracticalService();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() => _state = FhcAsyncValue.data(value));
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(
        context,
        'member.kca.practicalServiceTitle',
        fallback: 'KCA Practical Service',
      ),
      domain: WorkflowDomain.kca,
      actionLabel: fhcT(
        context,
        'member.kca.addAnotherDepartment',
        fallback: 'Add Another Department',
      ),
      onAction: () => fhcPush(context, FhcRoutes.kcaAssignments),
      children: [
        SizedBox(
          height: 520,
          child: FhcAsyncBody<JsonObject>(
            value: _state,
            onRetry: _load,
            emptyTitle: fhcT(
              context,
              'member.kca.noDepartments',
              fallback: 'No departments yet',
            ),
            unavailableTitle: fhcT(
              context,
              'member.kca.practicalUnavailable',
              fallback: 'Practical service unavailable',
            ),
            builder: (context, payload) {
              final departments = payload['departments'];
              final rows = departments is List
                  ? [
                      for (final item in departments)
                        if (item is Map) Map<String, Object?>.from(item),
                    ]
                  : const <JsonObject>[];
              final count = payload['departments_count'] ?? rows.length;
              final hours = payload['hours_served'] ?? 0;
              final onTrack = payload['on_track'] == true;
              return ListView(
                children: [
                  _heading(
                    fhcT(
                      context,
                      'member.kca.practicalService',
                      fallback: 'Practical Service',
                    ),
                    fhcT(
                      context,
                      'member.kca.practicalServiceCopy',
                      fallback: 'Serve in at least two departments.',
                    ),
                  ),
                  if (rows.isEmpty)
                    Text(
                      fhcT(
                        context,
                        'member.kca.noDepartmentsCopy',
                        fallback:
                            'Your assigned departments will appear here from KCA.',
                      ),
                      style: FhcTypography.caption,
                    )
                  else
                    WorkflowCard(
                      child: Column(
                        children: [
                          for (final row in rows)
                            WorkflowRow(
                              title: '${row['title'] ?? 'Department'}',
                              subtitle: [
                                if (row['module'] is Map)
                                  '${(row['module'] as Map)['title'] ?? ''}',
                                '${row['state'] ?? ''}',
                              ].where((part) => part.trim().isNotEmpty).join(' • '),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                final id = '${row['id'] ?? ''}'.trim();
                                if (id.isEmpty) {
                                  fhcPush(context, FhcRoutes.kcaAssignments);
                                  return;
                                }
                                fhcPush(
                                  context,
                                  '${FhcRoutes.kcaAssignments}?id=${Uri.encodeComponent(id)}',
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  WorkflowSectionTitle(
                    fhcT(
                      context,
                      'member.kca.serviceSummary',
                      fallback: 'Service Summary',
                    ),
                  ),
                  WorkflowSummary(
                    title: onTrack
                        ? fhcT(context, 'member.kca.onTrack', fallback: 'On Track')
                        : fhcT(
                            context,
                            'member.kca.keepServing',
                            fallback: 'Keep serving',
                          ),
                    metrics: [
                      (
                        '$count',
                        fhcT(
                          context,
                          'member.kca.departments',
                          fallback: 'Departments',
                        ),
                      ),
                      (
                        '$hours',
                        fhcT(
                          context,
                          'member.kca.hoursServed',
                          fallback: 'Hours Served',
                        ),
                      ),
                      (
                        onTrack ? '✓' : '—',
                        fhcT(context, 'member.kca.status', fallback: 'Status'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _heading(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: FhcTypography.caption),
          ],
        ),
      );
}

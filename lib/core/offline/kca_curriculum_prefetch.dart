import '../api/app_failure.dart';
import '../contracts/mobile_repository_contracts.dart';

/// Lesson and chapter ids nested in KCA module payloads.
typedef KcaCurriculumIds = ({
  List<String> moduleIds,
  List<String> lessonIds,
  List<String> chapterIds,
  List<String> assignmentIds,
});

String? _idOf(Map<String, Object?> map) {
  final id = '${map['id'] ?? map['public_id'] ?? ''}'.trim();
  return id.isEmpty ? null : id;
}

JsonObject _asObject(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final entry in raw.entries) '${entry.key}': entry.value,
  };
}

KcaCurriculumIds extractKcaCurriculumIds({
  List<JsonObject> modules = const [],
  JsonObject? moduleDetail,
  List<JsonObject> assignments = const [],
}) {
  final moduleIds = <String>{};
  final lessonIds = <String>{};
  final chapterIds = <String>{};
  final assignmentIds = <String>{};

  void collectModule(JsonObject module) {
    final moduleId = _idOf(module);
    if (moduleId != null) moduleIds.add(moduleId);
    final lessons = module['lessons'];
    if (lessons is! List) return;
    for (final lessonRaw in lessons) {
      final lesson = _asObject(lessonRaw);
      final lessonId = _idOf(lesson);
      if (lessonId != null) lessonIds.add(lessonId);
      final chapters = lesson['chapters'];
      if (chapters is! List) continue;
      for (final chapterRaw in chapters) {
        final chapterId = _idOf(_asObject(chapterRaw));
        if (chapterId != null) chapterIds.add(chapterId);
      }
    }
  }

  for (final module in modules) {
    collectModule(module);
  }
  if (moduleDetail != null) collectModule(moduleDetail);
  for (final assignment in assignments) {
    final id = _idOf(assignment);
    if (id != null) assignmentIds.add(id);
  }

  return (
    moduleIds: moduleIds.toList(growable: false),
    lessonIds: lessonIds.toList(growable: false),
    chapterIds: chapterIds.toList(growable: false),
    assignmentIds: assignmentIds.toList(growable: false),
  );
}

/// Downloads member KCA curriculum into the GET cache for offline study.
Future<void> prefetchKcaCurriculum(KcaRepository repo) async {
  Future<void> ignore(Future<AppResult<dynamic>> work) async {
    try {
      await work;
    } catch (_) {}
  }

  await ignore(repo.getAccess());
  await ignore(repo.getDashboard());
  await ignore(repo.getOrientation());
  await ignore(repo.getPracticalService());
  await ignore(repo.getMentor());
  await ignore(repo.listAttendance());
  await ignore(repo.getCurrentApplication());
  await ignore(repo.listFollowing());

  final modulesResult = await repo.listModules();
  final modules = switch (modulesResult) {
    AppSuccess(:final value) => value,
    AppError() => const <JsonObject>[],
  };

  final fromList = extractKcaCurriculumIds(modules: modules);
  for (final moduleId in fromList.moduleIds) {
    final detail = await repo.getModule(moduleId);
    if (detail case AppSuccess(:final value)) {
      final nested = extractKcaCurriculumIds(moduleDetail: value);
      for (final lessonId in nested.lessonIds) {
        await ignore(repo.getLesson(lessonId));
      }
      for (final chapterId in nested.chapterIds) {
        await ignore(repo.getChapter(chapterId));
      }
    }
  }

  final assignmentsResult = await repo.listAssignments();
  final assignments = switch (assignmentsResult) {
    AppSuccess(:final value) => value,
    AppError() => const <JsonObject>[],
  };
  for (final assignmentId in extractKcaCurriculumIds(
    assignments: assignments,
  ).assignmentIds) {
    await ignore(repo.getAssignment(assignmentId));
  }
}

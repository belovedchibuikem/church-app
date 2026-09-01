import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';
import 'kca_lesson_completion_queue.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// KCA member curriculum + public certificate verify.
final class HttpKcaRepository
    with TransportRepositoryHelpers
    implements KcaRepository {
  HttpKcaRepository({
    ApiTransport? transport,
    String? baseUrl,
    http.Client? httpClient,
    KcaLessonCompletionQueue? completionQueue,
  })  : _transport = transport,
        baseUrl = resolveFhcApiUrl(override: baseUrl),
        _http = httpClient ?? http.Client(),
        _completionQueue = completionQueue ?? KcaLessonCompletionQueue();

  final ApiTransport? _transport;
  final String baseUrl;
  final http.Client _http;
  final KcaLessonCompletionQueue _completionQueue;

  Uri get _root => Uri.parse(baseUrl.replaceAll(RegExp(r'/$'), ''));

  AppResult<T> _needsTransport<T>(String feature) {
    return AppError(
      IntegrationUnavailableFailure(
        '$feature requires an authenticated API transport.',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> getAccess() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA access'));
    }
    return sendObject(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/kca/me'),
    );
  }

  @override
  Future<AppResult<JsonObject>> getDashboard() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA dashboard'));
    }
    return sendObject(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/kca/dashboard'),
    );
  }

  @override
  Future<AppResult<JsonObject>> getOrientation() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA orientation'));
    }
    return sendObject(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/kca/orientation'),
    );
  }

  @override
  Future<AppResult<JsonObject>> getPracticalService() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA practical service'));
    }
    return sendObject(
      transport,
      const ApiRequest(
        method: ApiMethod.get,
        path: '/user/kca/practical-service',
      ),
    );
  }

  @override
  Future<AppResult<List<JsonObject>>> listModules() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA modules'));
    }
    return sendList(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/kca/modules'),
    );
  }

  @override
  Future<AppResult<JsonObject>> getModule(String moduleId) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA module detail'));
    }
    final id = moduleId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Module id is required.')),
      );
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/kca/modules/${encodeId(id)}',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> evaluateModulePrerequisites(String moduleId) {
    // Member curriculum has no separate prerequisites endpoint yet; module
    // detail is the authoritative read for published lessons/sequence.
    return getModule(moduleId);
  }

  @override
  Future<AppResult<List<JsonObject>>> listAssignments() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA assignments'));
    }
    return sendList(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/kca/assignments'),
    );
  }

  @override
  Future<AppResult<JsonObject>> getMentor() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA mentor'));
    }
    return sendObject(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/kca/mentor'),
    );
  }

  @override
  Future<AppResult<List<JsonObject>>> listAttendance() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA attendance'));
    }
    return sendList(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/kca/attendance'),
    );
  }

  @override
  Future<AppResult<JsonObject>> submitEvidence(JsonObject evidence) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA evidence'));
    }
    final assignmentId = '${evidence['assignment_id'] ?? evidence['id'] ?? ''}'.trim();
    final fileAssetId = '${evidence['file_asset_id'] ?? ''}'.trim();
    if (assignmentId.isEmpty || fileAssetId.isEmpty) {
      return Future.value(
        const AppError(
          ValidationFailure('assignment_id and file_asset_id are required.'),
        ),
      );
    }
    final key = '${evidence['idempotency_key'] ?? newIdempotencyKey('kca-evidence')}';
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/assignments/${encodeId(assignmentId)}/evidence',
        body: {
          'file_asset_id': fileAssetId,
          'idempotency_key': key,
        },
        idempotencyKey: key,
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> getLesson(String lessonId) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA lesson'));
    }
    final id = lessonId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Lesson id is required.')),
      );
    }
    return sendObject(
      transport,
      ApiRequest(method: ApiMethod.get, path: '/user/kca/lessons/${encodeId(id)}'),
    );
  }

  @override
  Future<AppResult<JsonObject>> completeLesson(
    String lessonId, {
    bool acknowledged = true,
    String? idempotencyKey,
    String? unlockToken,
  }) async {
    final transport = _transport;
    if (transport == null) {
      return _needsTransport('KCA lesson completion');
    }
    final id = lessonId.trim();
    if (id.isEmpty) {
      return const AppError(ValidationFailure('Lesson id is required.'));
    }
    final key = idempotencyKey ?? newIdempotencyKey('kca-lesson');
    final result = await sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/lessons/${encodeId(id)}/complete',
        body: {
          'acknowledged': acknowledged,
          'idempotency_key': key,
          if (unlockToken != null && unlockToken.isNotEmpty) 'unlock_token': unlockToken,
        },
        idempotencyKey: key,
      ),
    );
    switch (result) {
      case AppSuccess():
        await _completionQueue.remove(id);
        return result;
      case AppError(:final failure):
        if (failure is NetworkFailure) {
          await _completionQueue.enqueue(
            lessonId: id,
            idempotencyKey: key,
            unlockToken: unlockToken,
          );
        }
        return result;
    }
  }

  @override
  Future<AppResult<void>> syncQueuedCompletions() async {
    final pending = await _completionQueue.load();
    for (final item in pending) {
      final lessonId = item['lesson_id'];
      if (lessonId == null || lessonId.isEmpty) continue;
      final result = await completeLesson(
        lessonId,
        idempotencyKey: item['idempotency_key'],
        unlockToken: item['unlock_token'],
      );
      switch (result) {
        case AppSuccess():
          await _completionQueue.remove(lessonId);
        case AppError(:final failure):
          if (failure is ForbiddenFailure || failure is ValidationFailure) {
            await _completionQueue.remove(lessonId);
          }
      }
    }
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<JsonObject>> getCurrentApplication() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA current application'));
    }
    return sendObject(
      transport,
      const ApiRequest(
        method: ApiMethod.get,
        path: '/user/kca/applications/current',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> submitApplication(
    JsonObject applicationData, {
    bool finalize = true,
  }) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA application submission'));
    }
    if (applicationData.isEmpty) {
      return Future.value(
        const AppError(
          ValidationFailure('Application data is required.'),
        ),
      );
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/applications',
        body: {
          'application_data': applicationData,
          'finalize': finalize,
        },
        idempotencyKey: finalize
            ? newIdempotencyKey('kca-app-final')
            : newIdempotencyKey('kca-app-draft'),
      ),
    );
  }

  @override
  Future<AppResult<List<JsonObject>>> listDirectory(JsonObject filters) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA directory'));
    }
    final query = <String, Object?>{};
    for (final entry in filters.entries) {
      if (entry.value == null) continue;
      final key = entry.key;
      final value = entry.value;
      if (key == 'q' || key == 'search') {
        query['q'] = value;
      } else if (key.startsWith('filter[')) {
        query[key] = value;
      } else {
        query[key] = value;
      }
    }
    return sendList(
      transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/kca/directory',
        query: query,
      ),
    );
  }

  @override
  Future<AppResult<void>> follow(String personId) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA follow'));
    }
    final id = personId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Person id is required.')),
      );
    }
    return sendVoid(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/directory/${encodeId(id)}/follow',
        body: const <String, Object?>{},
        idempotencyKey: newIdempotencyKey('kca-follow'),
      ),
    );
  }

  @override
  Future<AppResult<void>> unfollow(String personId) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA unfollow'));
    }
    final id = personId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Person id is required.')),
      );
    }
    return sendVoid(
      transport,
      ApiRequest(
        method: ApiMethod.delete,
        path: '/user/kca/directory/${encodeId(id)}/follow',
      ),
    );
  }

  @override
  Future<AppResult<List<JsonObject>>> listFollowing() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA following'));
    }
    return sendList(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/kca/following'),
    );
  }

  @override
  Future<AppResult<JsonObject>> verifyCertificate(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return const AppError(
        ValidationFailure('Enter a certificate verification code.'),
      );
    }

    try {
      final uri = _root.replace(
        path: '${_root.path}/kca/certificates/verify',
        queryParameters: {'code': trimmed},
      );
      final response = await _http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      final decoded = response.body.isEmpty
          ? <String, Object?>{}
          : jsonDecode(response.body) as Map<String, Object?>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'];
        if (data is Map<String, Object?>) return AppSuccess(data);
        return AppSuccess(decoded);
      }
      final error = decoded['error'];
      final message = error is Map && error['message'] is String
          ? error['message'] as String
          : 'Certificate verification failed.';
      return AppError(
        mapHttpStatusToFailure(statusCode: response.statusCode, message: message),
      );
    } catch (error) {
      return AppError(NetworkFailure(error.toString()));
    }
  }
}

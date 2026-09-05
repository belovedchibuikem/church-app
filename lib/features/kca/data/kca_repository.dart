import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';
import 'kca_evidence_queue.dart';
import 'kca_lesson_completion_queue.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

String _readJsonErrorMessage(List<int> bodyBytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is Map) {
      final error = decoded['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
    }
  } catch (_) {
    /* ignore malformed error payloads */
  }
  return 'Admission letter download failed.';
}

bool _looksLikePdf(List<int> bytes) {
  return bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}

/// KCA member curriculum + public certificate verify.
final class HttpKcaRepository
    with TransportRepositoryHelpers
    implements KcaRepository {
  HttpKcaRepository({
    ApiTransport? transport,
    String? baseUrl,
    http.Client? httpClient,
    KcaLessonCompletionQueue? completionQueue,
    KcaEvidenceQueue? evidenceQueue,
    SessionTokenStore? tokenStore,
  })  : _transport = transport,
        baseUrl = resolveFhcApiUrl(override: baseUrl),
        _http = httpClient ?? http.Client(),
        _completionQueue = completionQueue ?? KcaLessonCompletionQueue(),
        _evidenceQueue = evidenceQueue ?? KcaEvidenceQueue(),
        _tokenStore = tokenStore;

  final ApiTransport? _transport;
  final String baseUrl;
  final http.Client _http;
  final KcaLessonCompletionQueue _completionQueue;
  final KcaEvidenceQueue _evidenceQueue;
  final SessionTokenStore? _tokenStore;

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
  Future<AppResult<JsonObject>> completeOrientationStage(String stage) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA orientation stage'));
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/orientation/stages/${Uri.encodeComponent(stage)}/complete',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> completeOrientation() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA orientation completion'));
    }
    return sendObject(
      transport,
      const ApiRequest(method: ApiMethod.post, path: '/user/kca/orientation/complete'),
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
  Future<AppResult<JsonObject>> submitEvidence(JsonObject evidence) async {
    final transport = _transport;
    if (transport == null) {
      return _needsTransport('KCA evidence');
    }
    final assignmentId =
        '${evidence['assignment_id'] ?? evidence['id'] ?? ''}'.trim();
    var fileAssetId = '${evidence['file_asset_id'] ?? ''}'.trim();
    final key =
        '${evidence['idempotency_key'] ?? newIdempotencyKey('kca-evidence')}';
    final filename = '${evidence['filename'] ?? 'kca-evidence.bin'}'.trim();
    final description = '${evidence['description'] ?? ''}'.trim();
    final bytes = _bytesOf(evidence['bytes']);

    if (assignmentId.isEmpty) {
      return const AppError(
        ValidationFailure('An assignment id is required to submit evidence.'),
      );
    }

    if (fileAssetId.isEmpty && bytes != null && bytes.isNotEmpty) {
      if (bytes.length > KcaEvidenceQueue.maxBytes) {
        return const AppError(
          ValidationFailure(
            'Evidence files larger than 1.5 MB cannot be stored offline. '
            'Compress the file or submit while online.',
          ),
        );
      }
      final uploaded = await _uploadEvidenceFile(
        bytes: bytes,
        filename: filename,
        idempotencyKey: key,
      );
      switch (uploaded) {
        case AppSuccess(:final value):
          fileAssetId = '${value['id'] ?? value['public_id'] ?? ''}'.trim();
        case AppError(:final failure):
          if (failure is NetworkFailure || failure is OfflineFailure) {
            await _evidenceQueue.enqueue(
              assignmentId: assignmentId,
              idempotencyKey: key,
              filename: filename,
              bytes: bytes,
              description: description,
            );
            return AppSuccess(<String, Object?>{
              'queued': true,
              'assignment_id': assignmentId,
              'sync_state': 'queued',
              'message':
                  'Evidence is saved on this device and will upload when a connection is available.',
            });
          }
          return AppError(failure);
      }
    }

    if (fileAssetId.isEmpty) {
      return const AppError(
        ValidationFailure(
          'Choose an evidence file, or provide assignment_id and file_asset_id.',
        ),
      );
    }

    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/assignments/${encodeId(assignmentId)}/evidence',
        body: {
          'file_asset_id': fileAssetId,
          'idempotency_key': key,
          if (description.isNotEmpty) 'description': description,
        },
        idempotencyKey: key,
      ),
    );
  }

  List<int>? _bytesOf(Object? raw) {
    if (raw is List<int>) return raw;
    if (raw is List) {
      return [
        for (final item in raw)
          if (item is num) item.toInt(),
      ];
    }
    return null;
  }

  Future<AppResult<JsonObject>> _uploadEvidenceFile({
    required List<int> bytes,
    required String filename,
    required String idempotencyKey,
  }) async {
    return _uploadUserFile(
      bytes: bytes,
      filename: filename,
      idempotencyKey: idempotencyKey,
      purpose: 'kca.evidence',
      classification: 'restricted',
      uploadFailureMessage: 'Unable to upload KCA evidence.',
      invalidSessionMessage: 'Sign in again to upload KCA evidence.',
      integrationUnavailableMessage:
          'Evidence upload requires a signed-in session.',
      unexpectedPayloadMessage:
          'Evidence upload returned an unexpected payload.',
    );
  }

  Future<AppResult<JsonObject>> _uploadUserFile({
    required List<int> bytes,
    required String filename,
    required String idempotencyKey,
    required String purpose,
    required String classification,
    required String uploadFailureMessage,
    required String invalidSessionMessage,
    required String integrationUnavailableMessage,
    required String unexpectedPayloadMessage,
  }) async {
    final store = _tokenStore;
    if (store == null) {
      return AppError(
        IntegrationUnavailableFailure(integrationUnavailableMessage),
      );
    }
    final access = await store.readAccessToken();
    final deviceId = await store.readDeviceIdentifier();
    if (access == null ||
        access.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty) {
      return AppError(
        UnauthorizedFailure(invalidSessionMessage),
      );
    }
    final safeName = filename.trim().isEmpty ? 'upload.bin' : filename.trim();
    final uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/$'), '')}/user/files',
    );
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $access',
        'X-Device-Identifier': deviceId,
        'Idempotency-Key': idempotencyKey,
      });
      request.fields['purpose'] = purpose;
      request.fields['classification'] = classification;
      request.fields['idempotency_key'] = idempotencyKey;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: safeName),
      );
      final streamed = await _http.send(request).timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 0) {
          return const AppError(NetworkFailure('Unable to upload evidence.'));
        }
        return AppError(
          mapHttpStatusToFailure(
            statusCode: response.statusCode,
            message: 'Evidence file upload failed (${response.statusCode}).',
          ),
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] is Map) {
        return AppSuccess(
          Map<String, Object?>.from(decoded['data'] as Map),
        );
      }
      return AppError(
        ServerFailure(unexpectedPayloadMessage),
      );
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure(uploadFailureMessage, cause: error),
      );
    } catch (error) {
      final name = error.runtimeType.toString();
      if (name == 'SocketException' || name.contains('Timeout')) {
        return AppError(
          NetworkFailure(uploadFailureMessage, cause: error),
        );
      }
      return AppError(
        UploadFailure(uploadFailureMessage, cause: error),
      );
    }
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
  Future<AppResult<JsonObject>> getChapter(String chapterId) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA chapter'));
    }
    final id = chapterId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Chapter id is required.')),
      );
    }
    return sendObject(
      transport,
      ApiRequest(method: ApiMethod.get, path: '/user/kca/chapters/${encodeId(id)}'),
    );
  }

  @override
  Future<AppResult<JsonObject>> completeChapter(
    String chapterId, {
    bool acknowledged = true,
    String? idempotencyKey,
    String? unlockToken,
  }) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA chapter completion'));
    }
    final id = chapterId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Chapter id is required.')),
      );
    }
    final key = idempotencyKey ?? newIdempotencyKey('kca-chapter');
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/chapters/${encodeId(id)}/complete',
        body: {
          'acknowledged': acknowledged,
          'idempotency_key': key,
          if (unlockToken != null && unlockToken.isNotEmpty) 'unlock_token': unlockToken,
        },
        idempotencyKey: key,
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> getAssignment(String assignmentId) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA assignment'));
    }
    final id = assignmentId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Assignment id is required.')),
      );
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/kca/assignments/${encodeId(id)}',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> recordSoulWin(
    String assignmentId,
    JsonObject body,
  ) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA soul winning'));
    }
    final id = assignmentId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Assignment id is required.')),
      );
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/assignments/${encodeId(id)}/souls',
        body: body,
      ),
    );
  }

  @override
  Future<AppResult<List<JsonObject>>> listMentees() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA mentees'));
    }
    return sendList(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/kca/mentees'),
    );
  }

  @override
  Future<AppResult<JsonObject>> getMentee(String enrollmentId) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA mentee report'));
    }
    final id = enrollmentId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Enrollment id is required.')),
      );
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/kca/mentees/${encodeId(id)}',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> createNote(JsonObject body) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA study notes'));
    }
    return sendObject(
      transport,
      ApiRequest(method: ApiMethod.post, path: '/user/kca/notes', body: body),
    );
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

    final evidence = await _evidenceQueue.load();
    for (final item in evidence) {
      final key = item['idempotency_key'] ?? '';
      final raw = item['bytes_b64'];
      if (key.isEmpty || raw == null || raw.isEmpty) continue;
      List<int> bytes;
      try {
        bytes = base64Decode(raw);
      } catch (_) {
        await _evidenceQueue.remove(key);
        continue;
      }
      final result = await submitEvidence({
        'assignment_id': item['assignment_id'],
        'idempotency_key': key,
        'filename': item['filename'] ?? 'kca-evidence.bin',
        'description': item['description'],
        'bytes': bytes,
      });
      switch (result) {
        case AppSuccess(:final value):
          if (value['queued'] == true) {
            break;
          }
          await _evidenceQueue.remove(key);
        case AppError(:final failure):
          if (failure is ForbiddenFailure ||
              failure is ValidationFailure ||
              failure is ConflictFailure) {
            await _evidenceQueue.remove(key);
          }
      }
    }
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<JsonObject>> getAdmissionLetter() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA admission letter'));
    }
    return sendObject(
      transport,
      const ApiRequest(
        method: ApiMethod.get,
        path: '/user/kca/admission-letter',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> acceptAdmissionLetter(JsonObject body) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('KCA admission letter acceptance'));
    }
    final signature = body['applicant_signature_name'];
    if (signature is! String || signature.trim().isEmpty) {
      return Future.value(
        const AppError(
          ValidationFailure('Applicant signature is required.'),
        ),
      );
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/admission-letter/accept',
        body: body,
      ),
    );
  }

  @override
  Future<AppResult<String>> uploadAdmissionSignature({
    required List<int> bytes,
    String filename = 'kca-admission-signature.png',
  }) async {
    final idempotencyKey = newIdempotencyKey('kca-admission-signature');
    final result = await _uploadUserFile(
      bytes: bytes,
      filename: filename,
      idempotencyKey: idempotencyKey,
      purpose: 'kca.admission_signature',
      classification: 'restricted',
      uploadFailureMessage: 'Unable to upload admission signature.',
      invalidSessionMessage: 'Sign in again to upload admission signature.',
      integrationUnavailableMessage:
          'Admission signature upload requires a signed-in session.',
      unexpectedPayloadMessage:
          'Admission signature upload returned an unexpected payload.',
    );
    switch (result) {
      case AppSuccess(:final value):
        final id = '${value['id'] ?? value['public_id'] ?? ''}'.trim();
        if (id.isEmpty) {
          return const AppError(
            ServerFailure('Admission signature upload did not return an asset id.'),
          );
        }
        return AppSuccess(id);
      case AppError(:final failure):
        return AppError(failure);
    }
  }

  @override
  Future<AppResult<JsonObject>> downloadAdmissionLetter() async {
    final tokenStore = _tokenStore;
    if (tokenStore == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'KCA admission letter download requires a session token store.',
        ),
      );
    }

    final access = await tokenStore.readAccessToken();
    final deviceId = await tokenStore.readDeviceIdentifier();
    if (access == null ||
        access.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty) {
      return const AppError(
        UnauthorizedFailure(
          'Sign in again. A mobile access token and device identifier are required.',
        ),
      );
    }

    final uri = _root.replace(path: '${_root.path}/user/kca/admission-letter/download');

    try {
      final response = await _http.get(
        uri,
        headers: {
          'Accept': 'application/pdf, application/json',
          'Authorization': 'Bearer $access',
          'X-Device-Identifier': deviceId,
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentType = response.headers['content-type'] ?? 'application/pdf';
        if (contentType.contains('application/json')) {
          return AppError(
            ServerFailure(_readJsonErrorMessage(response.bodyBytes)),
          );
        }
        if (response.bodyBytes.isEmpty || !_looksLikePdf(response.bodyBytes)) {
          return AppError(
            ServerFailure(
              response.bodyBytes.isEmpty
                  ? 'Admission letter download returned an empty file.'
                  : 'Admission letter download did not return a valid PDF.',
            ),
          );
        }
        return AppSuccess(<String, Object?>{
          'bytes': response.bodyBytes,
          'content_type': contentType,
          'filename': 'kca-admission-letter.pdf',
        });
      }

      if (response.statusCode == 404) {
        return const AppError(
          NotFoundFailure('Your admission letter has not been issued yet.'),
        );
      }

      final errorMessage = response.bodyBytes.isEmpty
          ? 'Admission letter download failed (${response.statusCode}).'
          : _readJsonErrorMessage(response.bodyBytes);
      return AppError(
        ServerFailure(errorMessage),
      );
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to reach KCA API.', cause: error),
      );
    } catch (error) {
      return AppError(
        UnknownFailure('Admission letter download failed.', cause: error),
      );
    }
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

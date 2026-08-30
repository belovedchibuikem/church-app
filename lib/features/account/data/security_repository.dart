import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';
import 'profile_repository.dart';
import 'user_api_client.dart';

/// Laravel-backed security sessions, devices, and consents (`/user/...`).
final class LaravelSecurityRepository implements SecurityRepository {
  LaravelSecurityRepository({required UserApiClient client}) : _client = client;

  factory LaravelSecurityRepository.fromTokenStore({
    required SessionTokenStore tokenStore,
    String? baseUrl,
  }) {
    return LaravelSecurityRepository(
      client: UserApiClient(tokenStore: tokenStore, baseUrl: baseUrl),
    );
  }

  final UserApiClient _client;

  @override
  Future<AppResult<List<JsonObject>>> sessions() =>
      _client.getList('/user/security/sessions');

  @override
  Future<AppResult<void>> revokeSession(String id) async {
    final result = await _client.deleteObject(
      '/user/security/sessions/${Uri.encodeComponent(id)}',
    );
    return switch (result) {
      AppSuccess() => const AppSuccess(null),
      AppError(:final failure) => AppError(failure),
    };
  }

  /// Withdraws when [granted] is false. Granting requires purpose + policy.
  @override
  Future<AppResult<void>> updateConsent(String id, bool granted) async {
    if (!granted) {
      final result = await _client.deleteObject(
        '/user/consents/${Uri.encodeComponent(id)}',
      );
      return switch (result) {
        AppSuccess() => const AppSuccess(null),
        AppError(:final failure) => AppError(failure),
      };
    }
    return const AppError(
      ValidationFailure(
        'Granting consent requires purpose and policy_version. Use grantConsent.',
      ),
    );
  }

  Future<AppResult<List<JsonObject>>> listConsents() =>
      _client.getList('/user/consents');

  Future<AppResult<JsonObject>> grantConsent({
    required String purpose,
    required String policyVersion,
  }) {
    return _client.postObject('/user/consents', {
      'purpose': purpose,
      'policy_version': policyVersion,
    });
  }

  Future<AppResult<List<JsonObject>>> devices() =>
      _client.getList('/user/security/devices');

  Future<AppResult<void>> revokeDevice(String id) async {
    final result = await _client.deleteObject(
      '/user/security/devices/${Uri.encodeComponent(id)}',
    );
    return switch (result) {
      AppSuccess() => const AppSuccess(null),
      AppError(:final failure) => AppError(failure),
    };
  }

  /// POST /user/privacy/data-subject-requests (recent MFA required).
  Future<AppResult<JsonObject>> submitDataSubjectRequest({
    required String requestType,
    String? notes,
    String? idempotencyKey,
  }) {
    final type = requestType.trim();
    const allowed = {'export', 'correction', 'deletion', 'restriction'};
    if (!allowed.contains(type)) {
      return Future.value(
        const AppError(
          ValidationFailure(
            'request_type must be export, correction, deletion, or restriction.',
          ),
        ),
      );
    }
    final key = (idempotencyKey ?? _newIdempotencyKey('dsr')).trim();
    if (key.length < 8 || key.length > 191) {
      return Future.value(
        const AppError(
          ValidationFailure('idempotency_key must be 8 to 191 characters.'),
        ),
      );
    }
    final trimmedNotes = notes?.trim();
    return _client.postObject('/user/privacy/data-subject-requests', {
      'request_type': type,
      'idempotency_key': key,
      if (trimmedNotes != null && trimmedNotes.isNotEmpty) 'notes': trimmedNotes,
    });
  }

  /// GET /user/files. Multipart POST /user/files upload is not wired.
  Future<AppResult<List<JsonObject>>> listFiles() =>
      _client.getList('/user/files');

  static String _newIdempotencyKey(String prefix) {
    final millis = DateTime.now().toUtc().millisecondsSinceEpoch;
    return '$prefix-$millis';
  }
}

SecurityRepository createSecurityRepository({
  SessionTokenStore? tokenStore,
  String? baseUrl,
}) {
  return LaravelSecurityRepository.fromTokenStore(
    tokenStore: sharedAccountTokenStore(tokenStore),
    baseUrl: baseUrl,
  );
}

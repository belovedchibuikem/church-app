import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/auth/session_token_store.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';
import 'user_api_client.dart';

/// Laravel-backed profile + preferences repository (`/user/me`, preferences).
final class LaravelProfileRepository implements ProfileRepository {
  LaravelProfileRepository({
    required UserApiClient client,
    required SessionTokenStore tokenStore,
    String? baseUrl,
    http.Client? httpClient,
  }) : _client = client,
       _tokenStore = tokenStore,
       baseUrl = resolveFhcApiUrl(override: baseUrl),
       _http = httpClient ?? http.Client();

  factory LaravelProfileRepository.fromTokenStore({
    required SessionTokenStore tokenStore,
    String? baseUrl,
    http.Client? httpClient,
    ApiTransport? transport,
  }) {
    return LaravelProfileRepository(
      client: UserApiClient(
        tokenStore: tokenStore,
        baseUrl: baseUrl,
        transport: transport,
      ),
      tokenStore: tokenStore,
      baseUrl: baseUrl,
      httpClient: httpClient,
    );
  }

  final UserApiClient _client;
  final SessionTokenStore _tokenStore;
  final String baseUrl;
  final http.Client _http;

  static const avatarPurpose = 'profile.avatar';

  @override
  Future<AppResult<JsonObject>> getProfile() => _client.getObject('/user/me');

  /// GET /user/dashboard — member aggregate (profile, prayers, notifications).
  @override
  Future<AppResult<JsonObject>> getDashboard() =>
      _client.getObject('/user/dashboard');

  /// Preferences → `PUT /user/preferences`. Name fields → `PUT /user/profile`
  /// (may require recent MFA; 403 is surfaced honestly).
  @override
  Future<AppResult<JsonObject>> updateProfile(JsonObject changes) async {
    if (changes.isEmpty) {
      return const AppError(
        ValidationFailure('Provide at least one profile field to update.'),
      );
    }

    final preferenceKeys = {'locale', 'timezone', 'notification_channels'};
    final onlyPreferences = changes.keys.every(preferenceKeys.contains);
    if (onlyPreferences) {
      return updatePreferences(changes);
    }

    final profileKeys = {
      'given_name',
      'middle_name',
      'family_name',
      'preferred_name',
      'display_name',
      'avatar_file_asset_id',
    };
    final profileBody = <String, Object?>{
      for (final entry in changes.entries)
        if (profileKeys.contains(entry.key) && entry.value != null)
          entry.key: entry.value,
    };
    if (changes.containsKey('avatar_file_asset_id') &&
        changes['avatar_file_asset_id'] == null) {
      profileBody['avatar_file_asset_id'] = null;
    }
    if (profileBody.isEmpty) {
      return const AppError(
        ValidationFailure(
          'Supported profile fields: given_name, family_name, preferred_name, '
          'avatar_file_asset_id. Use preferences for locale, timezone, and '
          'notification channels.',
        ),
      );
    }
    return _client.putObject('/user/profile', profileBody);
  }

  Future<AppResult<JsonObject>> getCapabilities() =>
      _client.getObject('/user/capabilities');

  Future<AppResult<JsonObject>> updatePreferences(JsonObject preferences) {
    final locale = preferences['locale'];
    final timezone = preferences['timezone'];
    final channels = preferences['notification_channels'];
    if (locale is! String ||
        timezone is! String ||
        channels is! List ||
        locale.isEmpty ||
        timezone.isEmpty) {
      return Future.value(
        const AppError(
          ValidationFailure(
            'locale, timezone, and notification_channels are required.',
          ),
        ),
      );
    }
    return _client.putObject('/user/preferences', {
      'locale': locale,
      'timezone': timezone,
      'notification_channels': [
        for (final channel in channels) '$channel',
      ],
    });
  }

  /// POST /user/files multipart — purpose `profile.avatar`.
  Future<AppResult<JsonObject>> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      return const AppError(ValidationFailure('Choose a photo to upload.'));
    }
    final access = await _tokenStore.readAccessToken();
    final deviceId = await _tokenStore.readDeviceIdentifier();
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

    final safeName =
        filename.trim().isEmpty ? 'avatar.jpg' : filename.trim();
    final idempotencyKey =
        'avatar-${DateTime.now().toUtc().millisecondsSinceEpoch}';
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
        'X-Correlation-ID': 'fhc-mobile-avatar-$idempotencyKey',
      });
      request.fields['purpose'] = avatarPurpose;
      request.fields['classification'] = 'internal';
      request.fields['idempotency_key'] = idempotencyKey;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: safeName),
      );

      final streamed = await _http.send(request).timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamed);
      return _decodeObjectEnvelope(response);
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to upload profile photo.', cause: error),
      );
    } catch (error) {
      return AppError(
        UploadFailure('Profile photo upload failed.', cause: error),
      );
    }
  }

  /// GET /user/files/{id} — authenticated image bytes for the avatar.
  Future<AppResult<Uint8List>> downloadAvatarBytes(String fileId) async {
    final trimmed = fileId.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Avatar file id is required.'));
    }
    final access = await _tokenStore.readAccessToken();
    final deviceId = await _tokenStore.readDeviceIdentifier();
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

    final uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/$'), '')}/user/files/${Uri.encodeComponent(trimmed)}',
    );

    try {
      final response = await _http.get(
        uri,
        headers: {
          'Accept': 'application/octet-stream, application/json',
          'Authorization': 'Bearer $access',
          'X-Device-Identifier': deviceId,
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AppSuccess(Uint8List.fromList(response.bodyBytes));
      }
      return AppError(
        _failureFromStatus(response.statusCode, response.body),
      );
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to load profile photo.', cause: error),
      );
    } catch (error) {
      return AppError(
        UnknownFailure('Profile photo download failed.', cause: error),
      );
    }
  }

  AppResult<JsonObject> _decodeObjectEnvelope(http.Response response) {
    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (error) {
        return AppError(
          ServerFailure(
            'Invalid JSON from server (${response.statusCode}).',
            cause: error,
          ),
        );
      }
    }
    final envelope =
        decoded is Map
            ? Map<String, Object?>.from(
              decoded.map((key, value) => MapEntry('$key', value)),
            )
            : <String, Object?>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = envelope['data'];
      if (data is Map) {
        return AppSuccess(
          Map<String, Object?>.from(
            data.map((key, value) => MapEntry('$key', value)),
          ),
        );
      }
      return const AppError(
        ServerFailure('Expected an object payload in data.'),
      );
    }

    final errorNode = envelope['error'];
    final errorMap =
        errorNode is Map
            ? Map<String, Object?>.from(
              errorNode.map((key, value) => MapEntry('$key', value)),
            )
            : const <String, Object?>{};
    final message =
        (errorMap['message'] as String?) ??
        'Request failed (${response.statusCode}).';
    return AppError(_failureFromStatus(response.statusCode, message));
  }

  AppFailure _failureFromStatus(int status, String message) {
    final lower = message.toLowerCase();
    final mfa =
        lower.contains('mfa') ||
        lower.contains('multi-factor') ||
        lower.contains('multifactor');
    return switch (status) {
      401 => UnauthorizedFailure(message),
      403 => ForbiddenFailure(
        message,
        code: mfa ? 'MFA_RECENT_REQUIRED' : null,
      ),
      404 => NotFoundFailure(message),
      409 => ConflictFailure(message),
      422 => ValidationFailure(message),
      429 => RateLimitFailure(message),
      >= 500 => ServerFailure(message),
      _ => UnknownFailure(message),
    };
  }
}

SessionTokenStore? _sharedAccountTokenStore;

/// Shared token store so profile/security screens and auth share credentials.
SessionTokenStore sharedAccountTokenStore([SessionTokenStore? override]) {
  if (override != null) {
    _sharedAccountTokenStore = override;
    return override;
  }
  return _sharedAccountTokenStore ??= createSessionTokenStore();
}

ProfileRepository createProfileRepository({
  SessionTokenStore? tokenStore,
  String? baseUrl,
}) {
  return LaravelProfileRepository.fromTokenStore(
    tokenStore: sharedAccountTokenStore(tokenStore),
    baseUrl: baseUrl,
  );
}

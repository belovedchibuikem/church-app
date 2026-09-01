import 'dart:convert';

import 'package:family_house_connect_public_api/protected_api.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/authorization.dart';
import '../../../core/auth/biometric_unlock.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// HTTP transport for the generated protected OpenAPI client.
final class HttpProtectedApiTransport implements ProtectedApiTransport {
  HttpProtectedApiTransport({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  @override
  Future<ProtectedApiTransportResponse> send(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    JsonMap? body,
    bool includeCredentials = true,
  }) async {
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) {
      request.headers.putIfAbsent('Content-Type', () => 'application/json');
      request.body = jsonEncode(body);
    }

    final streamed = await _http.send(request).timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamed);
    return ProtectedApiTransportResponse(
      statusCode: response.statusCode,
      body: _decodeBody(response.body),
    );
  }

  JsonMap _decodeBody(String raw) {
    if (raw.trim().isEmpty) return <String, Object?>{};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return Map<String, Object?>.from(decoded);
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
    return <String, Object?>{'raw': decoded};
  }
}

/// Laravel mobile auth: login / refresh / logout / MFA via generated client.
///
/// Opaque bearers are device-bound. Refresh rotates; reuse invalidates the
/// credential family — never retry a consumed refresh token.
final class LaravelAuthRepository implements AuthRepository, SessionRefresher {
  LaravelAuthRepository({
    required this.tokenStore,
    this.authorizationGateway,
    String? apiBaseUrl,
    http.Client? httpClient,
    FamilyHouseProtectedApiClient? client,
  }) : _client =
           client ??
           FamilyHouseProtectedApiClient(
             baseUri: Uri.parse(
               Uri.parse(resolveFhcApiUrl(override: apiBaseUrl)).origin,
             ),
             transport: HttpProtectedApiTransport(httpClient: httpClient),
           );

  final SessionTokenStore tokenStore;
  final AuthorizationGateway? authorizationGateway;
  final FamilyHouseProtectedApiClient _client;

  DateTime? _mfaVerifiedAt;
  Future<AppResult<String>>? _refreshInFlight;

  DateTime? get mfaVerifiedAt => _mfaVerifiedAt;

  @override
  Future<AppResult<JsonObject>> signIn(JsonObject credentials) async {
    final email = (credentials['email'] as String?)?.trim() ?? '';
    final password = credentials['password'] as String? ?? '';
    if (email.isEmpty || password.isEmpty) {
      return const AppError(
        ValidationFailure('Email and password are required.'),
      );
    }

    try {
      final deviceIdentifier = await ensureDeviceIdentifier(tokenStore);
      final response = await _client.mobileLogin(
        body: {
          'email': email,
          'password': password,
          'device_identifier': deviceIdentifier,
          'device_label':
              credentials['device_label'] as String? ?? 'Family House Connect',
          'device_type': credentials['device_type'] as String? ?? 'mobile',
          'platform':
              credentials['platform'] as String? ??
              defaultTargetPlatform.name,
          'app_version': credentials['app_version'] as String? ?? '1.0.0',
        },
      );
      final data = _dataMap(response);
      final issued = AuthCredentials.fromLoginData(
        data,
        deviceIdentifier: deviceIdentifier,
      );
      if (issued.accessToken.isEmpty || issued.refreshToken.isEmpty) {
        return const AppError(
          ServerFailure('Login succeeded without mobile credentials.'),
        );
      }
      await _persistIssued(issued);
      if (email.isNotEmpty) {
        await tokenStore.writeRememberedEmail(email);
      }
      await _enableBiometricUnlockIfAvailable();
      return AppSuccess(Map<String, Object?>.from(data));
    } on ProtectedApiException catch (error) {
      return AppError(_mapApiException(error, loginContext: true));
    } on AppFailure catch (failure) {
      return AppError(failure);
    } on http.ClientException catch (error, stack) {
      debugPrint('mobile login failed: $error\n$stack');
      return AppError(
        NetworkFailure(
          kIsWeb
              ? 'Browser blocked the sign-in request (CORS). '
                  'Use Android/iOS/desktop for production API testing, run against '
                  'local Laravel with --dart-define, or deploy the latest API CORS update.'
              : 'Unable to reach the server. Check your internet connection and try again.',
          cause: error,
        ),
      );
    } catch (error, stack) {
      debugPrint('mobile login failed: $error\n$stack');
      return AppError(NetworkFailure('Sign in failed.', cause: error));
    }
  }

  @override
  Future<AppResult<JsonObject>> register(JsonObject registration) async {
    final email = (registration['email'] as String?)?.trim() ?? '';
    final password = registration['password'] as String? ?? '';
    final passwordConfirmation =
        registration['password_confirmation'] as String? ?? password;
    final givenName = (registration['given_name'] as String?)?.trim() ?? '';
    final familyName = (registration['family_name'] as String?)?.trim() ?? '';

    if (email.isEmpty ||
        password.isEmpty ||
        givenName.isEmpty ||
        familyName.isEmpty) {
      return const AppError(
        ValidationFailure('Name, email, and password are required.'),
      );
    }

    final profile = <String, Object?>{
      'given_name': givenName,
      'family_name': familyName,
    };
    for (final entry in <MapEntry<String, Object?>>[
      MapEntry('middle_name', registration['middle_name']),
      MapEntry('preferred_name', registration['preferred_name']),
      MapEntry('country', registration['country']),
      MapEntry('region', registration['region']),
      MapEntry('locality', registration['locality']),
    ]) {
      final value =
          entry.key == 'country'
              ? _optionalString(entry.value)?.toUpperCase()
              : _optionalString(entry.value);
      if (value != null) {
        profile[entry.key] = value;
      }
    }

    try {
      final deviceIdentifier = await ensureDeviceIdentifier(tokenStore);
      final response = await _client.mobileRegister(
        body: {
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'profile': profile,
          'device_identifier': deviceIdentifier,
          'device_label':
              registration['device_label'] as String? ?? 'Family House Connect',
          'device_type': registration['device_type'] as String? ?? 'mobile',
          'platform':
              registration['platform'] as String? ??
              defaultTargetPlatform.name,
          'app_version': registration['app_version'] as String? ?? '1.0.0',
        },
      );
      final data = _dataMap(response);
      final issued = AuthCredentials.fromLoginData(
        data,
        deviceIdentifier: deviceIdentifier,
      );
      if (issued.accessToken.isEmpty || issued.refreshToken.isEmpty) {
        return const AppError(
          ServerFailure('Registration succeeded without mobile credentials.'),
        );
      }
      await _persistIssued(issued);
      if (email.isNotEmpty) {
        await tokenStore.writeRememberedEmail(email);
      }
      await _enableBiometricUnlockIfAvailable();
      return AppSuccess(Map<String, Object?>.from(data));
    } on ProtectedApiException catch (error) {
      return AppError(_mapApiException(error));
    } on AppFailure catch (failure) {
      return AppError(failure);
    } on http.ClientException catch (error, stack) {
      debugPrint('mobile registration failed: $error\n$stack');
      return AppError(
        NetworkFailure(
          'Unable to reach the server. Check your internet connection and try again.',
          cause: error,
        ),
      );
    } catch (error, stack) {
      debugPrint('mobile registration failed: $error\n$stack');
      return AppError(NetworkFailure('Registration failed.', cause: error));
    }
  }

  String? _optionalString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<AppResult<void>> requestPasswordReset(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Email is required.'));
    }

    try {
      await _client.requestPasswordReset(body: {'email': trimmed});
      return const AppSuccess(null);
    } on ProtectedApiException catch (error) {
      return AppError(_mapApiException(error));
    } on AppFailure catch (failure) {
      return AppError(failure);
    } catch (error, stack) {
      debugPrint('password reset request failed: $error\n$stack');
      return AppError(
        NetworkFailure('Password reset request failed.', cause: error),
      );
    }
  }

  @override
  Future<AppResult<void>> resetPassword(JsonObject payload) async {
    final email = (payload['email'] as String?)?.trim() ?? '';
    final token = (payload['token'] as String?)?.trim() ?? '';
    final password = payload['password'] as String? ?? '';
    final passwordConfirmation =
        payload['password_confirmation'] as String? ?? password;

    if (email.isEmpty || token.isEmpty || password.isEmpty) {
      return const AppError(
        ValidationFailure('Email, reset token, and password are required.'),
      );
    }

    try {
      await _client.resetPassword(
        body: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return const AppSuccess(null);
    } on ProtectedApiException catch (error) {
      return AppError(_mapApiException(error));
    } on AppFailure catch (failure) {
      return AppError(failure);
    } catch (error, stack) {
      debugPrint('password reset failed: $error\n$stack');
      return AppError(NetworkFailure('Password reset failed.', cause: error));
    }
  }

  @override
  Future<AppResult<void>> verify(JsonObject challenge) async {
    return const AppError(
      IntegrationUnavailableFailure(
        'Phone OTP verification has no mobile API operation in this build.',
      ),
    );
  }

  @override
  Future<AppResult<void>> signOut() async {
    try {
      final access = await tokenStore.readAccessToken();
      final deviceId = await tokenStore.readDeviceIdentifier();
      if (access != null &&
          access.isNotEmpty &&
          deviceId != null &&
          deviceId.isNotEmpty) {
        try {
          await _client.mobileLogout(
            options: ProtectedRequestOptions(
              bearerToken: access,
              deviceIdentifier: deviceId,
            ),
          );
        } on ProtectedApiException catch (error) {
          debugPrint('mobile logout remote failed: ${error.statusCode}');
        }
      }
      await _clearLocalSession();
      return const AppSuccess(null);
    } on AppFailure catch (failure) {
      await _clearLocalSession();
      return AppError(failure);
    } catch (error, stack) {
      debugPrint('mobile logout failed: $error\n$stack');
      await _clearLocalSession();
      return AppError(UnknownFailure('Sign out failed.', cause: error));
    }
  }

  @override
  Future<AppResult<void>> lockSession() async {
    await authorizationGateway?.clearSession();
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<JsonObject>> restoreSession() async {
    _mfaVerifiedAt ??= AuthCredentials.parseIso8601(
      await tokenStore.readMfaVerifiedAt(),
    );
    final access = await tokenStore.readAccessToken();
    final refresh = await tokenStore.readRefreshToken();
    final accessExpires = await tokenStore.readAccessTokenExpiresAt();
    final now = DateTime.now().toUtc();
    final accessStillValid = access != null &&
        access.isNotEmpty &&
        (accessExpires == null ||
            accessExpires.isAfter(now.add(const Duration(minutes: 2))));

    if (accessStillValid) {
      await authorizationGateway?.prefetchCapabilities();
      return AppSuccess(<String, Object?>{
        'access_token': access,
        'mfa_verified_at': _mfaVerifiedAt?.toIso8601String(),
      });
    }

    if (refresh == null || refresh.isEmpty) {
      return const AppError(UnauthorizedFailure('Missing refresh credential.'));
    }

    final refreshResult = await refreshAccessToken();
    switch (refreshResult) {
      case AppSuccess():
        return AppSuccess(<String, Object?>{
          'access_token': await tokenStore.readAccessToken(),
          'mfa_verified_at': _mfaVerifiedAt?.toIso8601String(),
        });
      case AppError(:final failure):
        return AppError(failure);
    }
  }

  @override
  Future<AppResult<String>> refreshAccessToken() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final future = _refreshAccessTokenBody();
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<AppResult<String>> _refreshAccessTokenBody() async {
    try {
      final refresh = await tokenStore.readRefreshToken();
      final deviceId = await ensureDeviceIdentifier(tokenStore);
      if (refresh == null || refresh.isEmpty) {
        return const AppError(UnauthorizedFailure('Missing refresh credential.'));
      }

      final response = await _client.mobileRefresh(
        body: {
          'refresh_token': refresh,
          'device_identifier': deviceId,
        },
      );
      final data = _dataMap(response);
      final issued = AuthCredentials.fromLoginData(
        data,
        deviceIdentifier: deviceId,
      );
      if (issued.accessToken.isEmpty || issued.refreshToken.isEmpty) {
        await _clearLocalSession();
        return const AppError(
          ServerFailure('Refresh succeeded without mobile credentials.'),
        );
      }
      await _persistIssued(issued);
      return AppSuccess(issued.accessToken);
    } on ProtectedApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _clearLocalSession();
      }
      return AppError(_mapApiException(error));
    } on AppFailure catch (failure) {
      return AppError(failure);
    } catch (error, stack) {
      debugPrint('mobile refresh failed: $error\n$stack');
      return AppError(NetworkFailure('Session restore failed.', cause: error));
    }
  }

  Future<AppResult<JsonObject>> challengeMfa({
    String? code,
    String? recoveryCode,
    String? methodId,
  }) async {
    try {
      final options = await _authedOptions();
      if (options == null) {
        return const AppError(UnauthorizedFailure('Sign in required.'));
      }
      final body = <String, Object?>{
        if (methodId != null && methodId.isNotEmpty) 'method_id': methodId,
        if (code != null && code.isNotEmpty) 'code': code,
        if (recoveryCode != null && recoveryCode.isNotEmpty)
          'recovery_code': recoveryCode,
      };
      final response = await _client.mobileMfaChallenge(
        body: body,
        options: options,
      );
      final data = _dataMap(response);
      _mfaVerifiedAt = AuthCredentials.parseIso8601(data['mfa_verified_at']);
      await tokenStore.writeMfaVerifiedAt(_mfaVerifiedAt?.toIso8601String());
      return AppSuccess(Map<String, Object?>.from(data));
    } on ProtectedApiException catch (error) {
      return AppError(_mapApiException(error));
    } on AppFailure catch (failure) {
      return AppError(failure);
    } catch (error, stack) {
      debugPrint('mfa challenge failed: $error\n$stack');
      return AppError(
        NetworkFailure('MFA verification failed.', cause: error),
      );
    }
  }

  Future<AppResult<JsonObject>> setupTotp({String? label}) async {
    try {
      final options = await _authedOptions();
      if (options == null) {
        return const AppError(UnauthorizedFailure('Sign in required.'));
      }
      final response = await _client.mobileMfaSetup(
        body: {
          if (label != null && label.isNotEmpty) 'label': label,
        },
        options: options,
      );
      return AppSuccess(Map<String, Object?>.from(_dataMap(response)));
    } on ProtectedApiException catch (error) {
      return AppError(_mapApiException(error));
    } on AppFailure catch (failure) {
      return AppError(failure);
    } catch (error, stack) {
      debugPrint('mfa setup failed: $error\n$stack');
      return AppError(NetworkFailure('MFA setup failed.', cause: error));
    }
  }

  Future<AppResult<JsonObject>> confirmTotp({
    required String methodId,
    required String code,
  }) async {
    try {
      final options = await _authedOptions();
      if (options == null) {
        return const AppError(UnauthorizedFailure('Sign in required.'));
      }
      final response = await _client.mobileMfaConfirm(
        body: {'method_id': methodId, 'code': code},
        options: options,
      );
      final data = _dataMap(response);
      _mfaVerifiedAt = AuthCredentials.parseIso8601(data['verified_at']);
      await tokenStore.writeMfaVerifiedAt(_mfaVerifiedAt?.toIso8601String());
      return AppSuccess(Map<String, Object?>.from(data));
    } on ProtectedApiException catch (error) {
      return AppError(_mapApiException(error));
    } on AppFailure catch (failure) {
      return AppError(failure);
    } catch (error, stack) {
      debugPrint('mfa confirm failed: $error\n$stack');
      return AppError(
        NetworkFailure('MFA confirmation failed.', cause: error),
      );
    }
  }

  Future<void> _persistIssued(AuthCredentials issued) async {
    await tokenStore.writeSession(
      accessToken: issued.accessToken,
      refreshToken: issued.refreshToken,
      deviceIdentifier: issued.deviceIdentifier,
      accessTokenExpiresAt: issued.accessTokenExpiresAt,
      refreshTokenExpiresAt: issued.refreshTokenExpiresAt,
    );
    _mfaVerifiedAt = issued.mfaVerifiedAt;
    await tokenStore.writeMfaVerifiedAt(_mfaVerifiedAt?.toIso8601String());
    final gateway = authorizationGateway;
    if (gateway != null) {
      await gateway.bindSession(
        accessToken: issued.accessToken,
        deviceIdentifier: issued.deviceIdentifier,
      );
    }
  }

  Future<void> _clearLocalSession() async {
    // Keep install device id so the next login stays device-bound.
    final deviceId = await tokenStore.readDeviceIdentifier();
    await tokenStore.clear();
    if (deviceId != null && deviceId.isNotEmpty) {
      await tokenStore.writeDeviceIdentifier(deviceId);
    }
    _mfaVerifiedAt = null;
    await tokenStore.writeMfaVerifiedAt(null);
    await authorizationGateway?.clearSession();
  }

  Future<void> _enableBiometricUnlockIfAvailable() async {
    try {
      if (await BiometricUnlock(tokenStore: tokenStore).isHardwareAvailable) {
        await tokenStore.writeBiometricUnlockEnabled(true);
      }
    } catch (error, stack) {
      debugPrint('Could not enable fingerprint unlock: $error\n$stack');
    }
  }

  Future<ProtectedRequestOptions?> _authedOptions() async {
    final access = await tokenStore.readAccessToken();
    final deviceId = await tokenStore.readDeviceIdentifier();
    if (access == null ||
        access.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty) {
      return null;
    }
    return ProtectedRequestOptions(
      bearerToken: access,
      deviceIdentifier: deviceId,
    );
  }

  Map<String, Object?> _dataMap(JsonMap response) {
    final data = response['data'];
    if (data is Map<String, Object?>) return data;
    if (data is Map) return Map<String, Object?>.from(data);
    return <String, Object?>{};
  }

  AppFailure _mapApiException(
    ProtectedApiException error, {
    bool loginContext = false,
  }) {
    final parsed = ApiEnvelope.errorOf(error.payload);
    final validationErrors =
        parsed == null
            ? const <String, List<String>>{}
            : ApiEnvelope.validationFieldsOf(parsed);
    final correlationId =
        ApiEnvelope.correlationIdOf(error.payload) ?? parsed?.correlationId;

    var message = parsed?.message;
    if (loginContext && error.statusCode == 401) {
      message = 'Invalid email or password.';
    } else if (loginContext && error.statusCode == 429) {
      message = 'Too many sign-in attempts. Wait a minute and try again.';
    } else if (loginContext &&
        error.statusCode == 422 &&
        validationErrors.isNotEmpty) {
      final first = validationErrors.values.expand((items) => items).firstOrNull;
      if (first != null && first.isNotEmpty) {
        message = first;
      }
    }

    return mapHttpStatusToFailure(
      statusCode: error.statusCode,
      message: message,
      code: parsed?.code,
      correlationId: correlationId,
      validationErrors: validationErrors,
      cause: error,
    );
  }
}

/// User-facing message for auth screens (prefers first Laravel field error).
String authFailureMessage(AppFailure failure) {
  if (failure is ValidationFailure && failure.errors.isNotEmpty) {
    final first = failure.errors.values.first;
    if (first.isNotEmpty) return first.first;
  }
  return failure.message;
}

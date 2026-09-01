import 'app_failure.dart';

enum ApiMethod { get, post, put, patch, delete }

/// Outbound HTTP request for [ApiTransport].
///
/// Paths are relative to the `/api/v1` base (e.g. `/mobile/auth/login`).
/// Pass [correlationId] and/or [idempotencyKey] when the operation requires
/// them; they become `X-Correlation-ID` and `Idempotency-Key`.
final class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.path,
    this.query = const {},
    this.headers = const {},
    this.body,
    this.timeout = const Duration(seconds: 30),
    this.idempotencyKey,
    this.correlationId,
    this.skipAuth = false,
  });

  final ApiMethod method;
  final String path;
  final Map<String, Object?> query;
  final Map<String, String> headers;
  final Object? body;
  final Duration timeout;
  final String? idempotencyKey;
  final String? correlationId;

  /// When true, do not attach Bearer / device headers (public catalogue calls).
  final bool skipAuth;
}

final class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    this.body,
    this.headers = const {},
    this.correlationId,
  });

  final int statusCode;
  final Object? body;
  final Map<String, String> headers;

  /// Echoed from the Laravel envelope or response header when present.
  final String? correlationId;
}

abstract interface class ApiTransport {
  Future<AppResult<ApiResponse>> send(ApiRequest request);

  Future<void> cancel(String requestId);
}

/// Persists opaque mobile access/refresh credentials and the device binding id.
///
/// Mobile auth requires both `Authorization: Bearer <access>` and
/// `X-Device-Identifier` on protected calls. Refresh rotation is one-time;
/// reuse detection revokes the credential family — callers must persist the
/// newly issued refresh token and never retry a consumed one.
abstract interface class SessionTokenStore {
  Future<String?> readAccessToken();

  Future<void> writeAccessToken(String token);

  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String token);

  Future<String?> readDeviceIdentifier();

  Future<void> writeDeviceIdentifier(String deviceIdentifier);

  /// Writes access, refresh, and device identifier together.
  ///
  /// When expiry timestamps are omitted, stores default to a 30-day window.
  Future<void> writeSession({
    required String accessToken,
    required String refreshToken,
    required String deviceIdentifier,
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
  });

  Future<DateTime?> readAccessTokenExpiresAt();

  Future<DateTime?> readRefreshTokenExpiresAt();

  Future<String?> readRememberedEmail();

  Future<void> writeRememberedEmail(String email);

  Future<bool> readBiometricUnlockEnabled();

  Future<void> writeBiometricUnlockEnabled(bool enabled);

  Future<String?> readMfaVerifiedAt();

  Future<void> writeMfaVerifiedAt(String? iso8601);

  Future<void> clear();
}

/// Performs `POST /mobile/auth/refresh` with the stored refresh token + device
/// id, persists **both** rotated credentials (access + refresh), and returns
/// the new access token.
///
/// Refresh tokens are one-time; reuse detection revokes the credential family.
/// Implementations must never retry a spent refresh token.
abstract interface class SessionRefresher {
  Future<AppResult<String>> refreshAccessToken();
}

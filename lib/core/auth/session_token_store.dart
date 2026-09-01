import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_transport.dart';
import 'session_lifetime.dart';

const _accessTokenKey = 'fhc.mobile.access_token';
const _refreshTokenKey = 'fhc.mobile.refresh_token';
const _deviceIdentifierKey = 'fhc.mobile.device_identifier';
const _accessExpiresKey = 'fhc.mobile.access_token_expires_at';
const _refreshExpiresKey = 'fhc.mobile.refresh_token_expires_at';
const _rememberedEmailKey = 'fhc.mobile.remembered_email';
const _biometricEnabledKey = 'fhc.mobile.biometric_unlock';

DateTime _defaultSessionExpiry() =>
    DateTime.now().toUtc().add(kMobileSessionLifetime);

DateTime? _parseExpiry(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}

/// In-memory store for tests and web (tokens do not survive reloads).
final class MemorySessionTokenStore implements SessionTokenStore {
  String? _accessToken;
  String? _refreshToken;
  String? _deviceIdentifier;
  DateTime? _accessExpiresAt;
  DateTime? _refreshExpiresAt;
  String? _rememberedEmail;
  bool _biometricEnabled = false;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> writeAccessToken(String token) async => _accessToken = token;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async => _refreshToken = token;

  @override
  Future<String?> readDeviceIdentifier() async => _deviceIdentifier;

  @override
  Future<void> writeDeviceIdentifier(String deviceIdentifier) async =>
      _deviceIdentifier = deviceIdentifier;

  @override
  Future<void> writeSession({
    required String accessToken,
    required String refreshToken,
    required String deviceIdentifier,
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _deviceIdentifier = deviceIdentifier;
    _accessExpiresAt =
        accessTokenExpiresAt?.toUtc() ?? _defaultSessionExpiry();
    _refreshExpiresAt =
        refreshTokenExpiresAt?.toUtc() ?? _accessExpiresAt;
  }

  @override
  Future<DateTime?> readAccessTokenExpiresAt() async => _accessExpiresAt;

  @override
  Future<DateTime?> readRefreshTokenExpiresAt() async => _refreshExpiresAt;

  @override
  Future<String?> readRememberedEmail() async => _rememberedEmail;

  @override
  Future<void> writeRememberedEmail(String email) async =>
      _rememberedEmail = email.trim();

  @override
  Future<bool> readBiometricUnlockEnabled() async => _biometricEnabled;

  @override
  Future<void> writeBiometricUnlockEnabled(bool enabled) async =>
      _biometricEnabled = enabled;

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _deviceIdentifier = null;
    _accessExpiresAt = null;
    _refreshExpiresAt = null;
    _biometricEnabled = false;
  }
}

/// Platform secure store (Keychain / Keystore / encrypted prefs).
///
/// Not used on web — prefer [createSessionTokenStore].
final class SecureSessionTokenStore implements SessionTokenStore {
  SecureSessionTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  @override
  Future<String?> readDeviceIdentifier() =>
      _storage.read(key: _deviceIdentifierKey);

  @override
  Future<void> writeDeviceIdentifier(String deviceIdentifier) =>
      _storage.write(key: _deviceIdentifierKey, value: deviceIdentifier);

  @override
  Future<void> writeSession({
    required String accessToken,
    required String refreshToken,
    required String deviceIdentifier,
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
  }) async {
    final accessExpiry =
        (accessTokenExpiresAt ?? _defaultSessionExpiry()).toUtc();
    final refreshExpiry =
        (refreshTokenExpiresAt ?? accessExpiry).toUtc();
    await Future.wait([
      writeAccessToken(accessToken),
      writeRefreshToken(refreshToken),
      writeDeviceIdentifier(deviceIdentifier),
      _storage.write(
        key: _accessExpiresKey,
        value: accessExpiry.toIso8601String(),
      ),
      _storage.write(
        key: _refreshExpiresKey,
        value: refreshExpiry.toIso8601String(),
      ),
    ]);
  }

  @override
  Future<DateTime?> readAccessTokenExpiresAt() async =>
      _parseExpiry(await _storage.read(key: _accessExpiresKey));

  @override
  Future<DateTime?> readRefreshTokenExpiresAt() async =>
      _parseExpiry(await _storage.read(key: _refreshExpiresKey));

  @override
  Future<String?> readRememberedEmail() =>
      _storage.read(key: _rememberedEmailKey);

  @override
  Future<void> writeRememberedEmail(String email) =>
      _storage.write(key: _rememberedEmailKey, value: email.trim());

  @override
  Future<bool> readBiometricUnlockEnabled() async {
    final raw = await _storage.read(key: _biometricEnabledKey);
    return raw == '1' || raw == 'true';
  }

  @override
  Future<void> writeBiometricUnlockEnabled(bool enabled) =>
      _storage.write(key: _biometricEnabledKey, value: enabled ? '1' : '0');

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _deviceIdentifierKey),
      _storage.delete(key: _accessExpiresKey),
      _storage.delete(key: _refreshExpiresKey),
      _storage.delete(key: _biometricEnabledKey),
    ]);
  }
}

/// Secure storage on mobile/desktop; in-memory on web and widget tests.
SessionTokenStore createSessionTokenStore({SessionTokenStore? override}) {
  if (override != null) return override;

  if (kIsWeb) {
    debugPrint(
      'FHC: SessionTokenStore is in-memory on web — opaque tokens are not '
      'persisted across reloads. Prefer native builds for durable sessions.',
    );
    return MemorySessionTokenStore();
  }

  // FlutterSecureStorage has no platform channel in widget tests.
  if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
    return MemorySessionTokenStore();
  }

  return SecureSessionTokenStore();
}

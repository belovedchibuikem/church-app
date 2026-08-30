import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_transport.dart';

const _accessTokenKey = 'fhc.mobile.access_token';
const _refreshTokenKey = 'fhc.mobile.refresh_token';
const _deviceIdentifierKey = 'fhc.mobile.device_identifier';

/// In-memory store for tests and web (tokens do not survive reloads).
final class MemorySessionTokenStore implements SessionTokenStore {
  String? _accessToken;
  String? _refreshToken;
  String? _deviceIdentifier;

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
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _deviceIdentifier = deviceIdentifier;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _deviceIdentifier = null;
  }
}

/// Platform secure store (Keychain / Keystore / encrypted prefs).
///
/// Not used on web — prefer [createSessionTokenStore].
final class SecureSessionTokenStore implements SessionTokenStore {
  SecureSessionTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

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
  }) async {
    await Future.wait([
      writeAccessToken(accessToken),
      writeRefreshToken(refreshToken),
      writeDeviceIdentifier(deviceIdentifier),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _deviceIdentifierKey),
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

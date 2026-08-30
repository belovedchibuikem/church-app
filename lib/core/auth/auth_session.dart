import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../api/api_transport.dart';

/// Opaque mobile credential snapshot returned by login/refresh (not a JWT).
@immutable
final class AuthCredentials {
  const AuthCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.deviceIdentifier,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
    this.securitySessionId,
    this.deviceId,
    this.mfaVerifiedAt,
    this.userEmail,
    this.personId,
  });

  final String accessToken;
  final String refreshToken;
  final String deviceIdentifier;
  final DateTime? accessTokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;
  final String? securitySessionId;
  final String? deviceId;
  final DateTime? mfaVerifiedAt;
  final String? userEmail;
  final String? personId;

  bool get hasMfaEvidence => mfaVerifiedAt != null;

  factory AuthCredentials.fromLoginData(
    Map<String, Object?> data, {
    required String deviceIdentifier,
  }) {
    final user = data['user'];
    final userMap = <String, Object?>{
      if (user is Map)
        for (final entry in user.entries) '${entry.key}': entry.value,
    };
    return AuthCredentials(
      accessToken: data['access_token'] as String? ?? '',
      refreshToken: data['refresh_token'] as String? ?? '',
      deviceIdentifier: deviceIdentifier,
      accessTokenExpiresAt: parseIso8601(data['access_token_expires_at']),
      refreshTokenExpiresAt: parseIso8601(data['refresh_token_expires_at']),
      securitySessionId: data['security_session_id'] as String?,
      deviceId: data['device_id'] as String?,
      mfaVerifiedAt: parseIso8601(data['mfa_verified_at']),
      userEmail: userMap['email'] as String?,
      personId: userMap['person_id'] as String?,
    );
  }

  static DateTime? parseIso8601(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}

/// Ensures a stable install-scoped device identifier for X-Device-Identifier.
Future<String> ensureDeviceIdentifier(SessionTokenStore store) async {
  final existing = await store.readDeviceIdentifier();
  if (existing != null && existing.isNotEmpty) return existing;
  final generated = generateDeviceIdentifier();
  await store.writeDeviceIdentifier(generated);
  return generated;
}

String generateDeviceIdentifier() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

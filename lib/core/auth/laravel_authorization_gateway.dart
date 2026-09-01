import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/api_transport.dart';
import '../api/app_failure.dart';
import '../api/fhc_api_config.dart';
import 'authorization.dart';
import 'session_lifetime.dart';
import 'session_token_store.dart';

export 'session_token_store.dart'
    show MemorySessionTokenStore, createSessionTokenStore;

/// Laravel-backed authorization adapter for protected mobile routes.
///
/// Protected `/user/*` calls require both `Authorization: Bearer …` and
/// `X-Device-Identifier` (`AuthenticateMobileAccessToken`).
final class LaravelAuthorizationGateway implements AuthorizationGateway {
  LaravelAuthorizationGateway({
    required this.baseUrl,
    required this.tokenStore,
    http.Client? httpClient,
    SessionRefresher? sessionRefresher,
  })  : _http = httpClient ?? http.Client(),
        _sessionRefresher = sessionRefresher;

  final String baseUrl;
  final SessionTokenStore tokenStore;
  final http.Client _http;
  SessionRefresher? _sessionRefresher;
  Completer<bool>? _refreshCompleter;

  /// Wired after [LaravelAuthRepository] is constructed in [AppServices].
  set sessionRefresher(SessionRefresher? value) => _sessionRefresher = value;

  final Map<String, AuthorizationDecision> _decisionCache = {};
  DateTime? _cacheExpiresAt;

  Set<String>? _capabilityPermissions;
  DateTime? _capabilitiesFetchedAt;

  /// Test helper: treat the cached capability snapshot as idle/stale.
  @visibleForTesting
  void markCapabilitiesStale() {
    _capabilitiesFetchedAt = DateTime.now().toUtc().subtract(
      kCapabilityRevalidateAfter + const Duration(minutes: 1),
    );
  }

  Uri get _root => Uri.parse(baseUrl.replaceAll(RegExp(r'/$'), ''));

  bool get _capabilitiesAreStale {
    final fetchedAt = _capabilitiesFetchedAt;
    if (fetchedAt == null) return true;
    return !DateTime.now().toUtc().isBefore(
          fetchedAt.add(kCapabilityRevalidateAfter),
        );
  }

  @override
  Future<void> bindSession({
    required String accessToken,
    required String deviceIdentifier,
  }) async {
    final refresh = await tokenStore.readRefreshToken() ?? '';
    final accessExpires = await tokenStore.readAccessTokenExpiresAt();
    final refreshExpires = await tokenStore.readRefreshTokenExpiresAt();
    await tokenStore.writeSession(
      accessToken: accessToken,
      refreshToken: refresh,
      deviceIdentifier: deviceIdentifier,
      accessTokenExpiresAt: accessExpires,
      refreshTokenExpiresAt: refreshExpires,
    );
    clearCache();
    await prefetchCapabilities();
  }

  @override
  Future<void> clearSession() async {
    await tokenStore.clear();
    clearCache();
  }

  @override
  Future<void> prefetchCapabilities() async {
    var credentials = await _readCredentials();
    if (credentials == null) return;

    try {
      final snapshot = await _fetchCapabilities(credentials);
      _capabilityPermissions = snapshot;
      _capabilitiesFetchedAt = DateTime.now().toUtc();
    } on UnauthorizedFailure {
      final refreshed = await _refreshOnce();
      if (!refreshed) return;
      credentials = await _readCredentials();
      if (credentials == null) return;
      try {
        final snapshot = await _fetchCapabilities(credentials);
        _capabilityPermissions = snapshot;
        _capabilitiesFetchedAt = DateTime.now().toUtc();
      } on UnauthorizedFailure {
        // Refresh already persisted or cleared credentials. Do not wipe
        // a still-valid 30-day refresh token from a second 401.
      }
    } catch (error, stack) {
      debugPrint('Capabilities prefetch failed: $error\n$stack');
    }
  }

  @override
  Future<AuthorizationDecision> authorize({
    required String permission,
    String? resourceId,
    String? organizationScope,
  }) async {
    var credentials = await _readCredentials();
    if (credentials == null) {
      return const AuthorizationDecision(
        AuthorizationState.unauthenticated,
        reason: 'Sign in to access this area.',
      );
    }

    final needsScopedCheck =
        (organizationScope != null && organizationScope.isNotEmpty) ||
        (resourceId != null && resourceId.isNotEmpty);

    if (!needsScopedCheck) {
      final fromSnapshot = _decisionFromCapabilities(permission);
      if (fromSnapshot != null) {
        if (_capabilitiesAreStale) {
          unawaited(prefetchCapabilities());
        }
        return fromSnapshot;
      }
    }

    final cacheKey =
        '$permission|${organizationScope ?? ''}|${resourceId ?? ''}';
    final now = DateTime.now().toUtc();
    if (_cacheExpiresAt != null &&
        now.isBefore(_cacheExpiresAt!) &&
        _decisionCache.containsKey(cacheKey)) {
      return _decisionCache[cacheKey]!;
    }

    try {
      final decision = await _checkRemote(
        credentials: credentials,
        permission: permission,
        organizationScope: organizationScope,
        resourceId: resourceId,
      );
      _decisionCache[cacheKey] = decision;
      _cacheExpiresAt = now.add(kCapabilityRevalidateAfter);
      return decision;
    } on UnauthorizedFailure {
      final refreshed = await _refreshOnce();
      if (refreshed) {
        credentials = await _readCredentials();
        if (credentials != null) {
          try {
            final decision = await _checkRemote(
              credentials: credentials,
              permission: permission,
              organizationScope: organizationScope,
              resourceId: resourceId,
            );
            _decisionCache[cacheKey] = decision;
            _cacheExpiresAt = DateTime.now().toUtc().add(
              kCapabilityRevalidateAfter,
            );
            return decision;
          } on UnauthorizedFailure {
            // Fall through.
          }
        }
      }
      final stale = _decisionFromCapabilities(permission);
      if (stale != null && !needsScopedCheck) return stale;
      final refresh = await tokenStore.readRefreshToken();
      if (refresh != null && refresh.isNotEmpty) {
        return const AuthorizationDecision(
          AuthorizationState.restricted,
          reason:
              'Unable to verify access with the Family House authorization service. Check your connection and try again.',
        );
      }
      return const AuthorizationDecision(
        AuthorizationState.unauthenticated,
        reason: 'Your session expired. Sign in again to continue.',
      );
    } catch (error, stack) {
      debugPrint('Authorization gateway error: $error\n$stack');
      final stale = _decisionFromCapabilities(permission);
      if (stale != null && !needsScopedCheck) return stale;
      return const AuthorizationDecision(
        AuthorizationState.restricted,
        reason:
            'Unable to verify access with the Family House authorization service. Check your connection and try again.',
      );
    }
  }

  Future<bool> _refreshOnce() async {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final refresher = _sessionRefresher;
    if (refresher == null) return false;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final result = await refresher.refreshAccessToken();
      final ok = result is AppSuccess;
      if (!completer.isCompleted) completer.complete(ok);
      return ok;
    } catch (error, stack) {
      debugPrint('Authorization refresh failed: $error\n$stack');
      if (!completer.isCompleted) completer.complete(false);
      return false;
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  AuthorizationDecision? _decisionFromCapabilities(String permission) {
    final permissions = _capabilityPermissions;
    if (permissions == null) return null;

    final canonical = canonicalizeMobilePermission(permission);
    if (permissions.contains(canonical)) {
      return const AuthorizationDecision.allowed();
    }
    return const AuthorizationDecision(
      AuthorizationState.forbidden,
      reason: 'You do not have permission to open this area.',
    );
  }

  Future<({String token, String deviceId})?> _readCredentials() async {
    final token = await tokenStore.readAccessToken();
    final deviceId = await tokenStore.readDeviceIdentifier();
    if (token == null ||
        token.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty) {
      return null;
    }
    return (token: token, deviceId: deviceId);
  }

  Future<Set<String>> _fetchCapabilities(
    ({String token, String deviceId}) credentials,
  ) async {
    final uri = _root.replace(path: '${_root.path}/user/capabilities');
    final response = await _http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${credentials.token}',
        'X-Device-Identifier': credentials.deviceId,
      },
    );

    if (response.statusCode == 401) {
      throw const UnauthorizedFailure('Unauthorized');
    }
    if (response.statusCode >= 400) {
      throw ServerFailure(
        'Capabilities fetch failed (${response.statusCode})',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final raw = data['permissions'] as List<dynamic>? ?? const [];
    return raw.map((item) => item.toString()).toSet();
  }

  Future<AuthorizationDecision> _checkRemote({
    required ({String token, String deviceId}) credentials,
    required String permission,
    String? organizationScope,
    String? resourceId,
  }) async {
    String? scopeType;
    String? scopeId;
    if (organizationScope != null && organizationScope.contains(':')) {
      final parts = organizationScope.split(':');
      scopeType = parts.first;
      scopeId = parts.sublist(1).join(':');
    }

    final uri = _root.replace(path: '${_root.path}/user/authorization/check');
    final response = await _http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${credentials.token}',
        'X-Device-Identifier': credentials.deviceId,
      },
      body: jsonEncode({
        'permission': permission,
        if (scopeType != null) 'scope_type': scopeType,
        if (scopeId != null) 'scope_id': scopeId,
        if (resourceId != null) 'resource_id': resourceId,
      }),
    );

    if (response.statusCode == 401) {
      throw const UnauthorizedFailure('Unauthorized');
    }
    if (response.statusCode >= 400) {
      throw ServerFailure(
        'Authorization check failed (${response.statusCode})',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    if (data['allowed'] == true) {
      return const AuthorizationDecision.allowed();
    }

    return AuthorizationDecision(
      AuthorizationState.forbidden,
      reason: _humanReason(data['reason'] as String?),
    );
  }

  String _humanReason(String? reason) {
    return switch (reason) {
      'permission_not_assigned' =>
        'You do not have permission to open this area.',
      'scope_not_assigned' || 'scope_not_contained' =>
        'This area is outside your assigned ministry scope.',
      'account_suspended' => 'Your account is suspended.',
      _ => 'You do not have permission to open this area.',
    };
  }

  void clearCache() {
    _decisionCache.clear();
    _cacheExpiresAt = null;
    _capabilityPermissions = null;
    _capabilitiesFetchedAt = null;
  }
}

/// Bootstrap helper used by `main.dart`, `AppServices`, and tests.
AuthorizationGateway createAuthorizationGateway({
  String? apiBaseUrl,
  SessionTokenStore? tokenStore,
  bool visualReview = false,
}) {
  if (visualReview) {
    return const VisualReviewAuthorizationGateway();
  }

  return LaravelAuthorizationGateway(
    baseUrl: resolveFhcApiUrl(override: apiBaseUrl),
    tokenStore: tokenStore ?? createSessionTokenStore(),
  );
}

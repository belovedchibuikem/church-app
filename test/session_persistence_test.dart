import 'dart:convert';

import 'package:family_house_connect_mobile/core/api/api_transport.dart';
import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:family_house_connect_mobile/core/auth/laravel_authorization_gateway.dart';
import 'package:family_house_connect_mobile/core/auth/session_lifetime.dart';
import 'package:family_house_connect_mobile/core/auth/session_token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('writeSession stores a 30-day expiry by default', () async {
    final store = MemorySessionTokenStore();
    await store.writeSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      deviceIdentifier: 'device',
    );

    final accessExpires = await store.readAccessTokenExpiresAt();
    final refreshExpires = await store.readRefreshTokenExpiresAt();
    expect(accessExpires, isNotNull);
    expect(refreshExpires, isNotNull);
    expect(
      accessExpires!.isAfter(
        DateTime.now().toUtc().add(kMobileSessionLifetime - const Duration(minutes: 1)),
      ),
      isTrue,
    );
  });

  test('stale capability snapshot still unlocks screens after idle', () async {
    final store = MemorySessionTokenStore();
    await store.writeSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      deviceIdentifier: 'device',
    );

    var capabilityCalls = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/user/capabilities')) {
        capabilityCalls += 1;
        return http.Response(
          jsonEncode({
            'data': {
              'permissions': [
                'mobile.app.access',
                'identity.preferences.manage',
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      fail('Unexpected ${request.url}');
    });

    final gateway = LaravelAuthorizationGateway(
      baseUrl: 'http://example.test/api/v1',
      tokenStore: store,
      httpClient: client,
    );

    await gateway.prefetchCapabilities();
    expect(capabilityCalls, 1);

    gateway.markCapabilitiesStale();
    final decision = await gateway.authorize(permission: 'profile.view');
    expect(decision.isAllowed, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(capabilityCalls, greaterThanOrEqualTo(1));
  });

  test('failed refresh does not wipe a stored 30-day session', () async {
    final store = MemorySessionTokenStore();
    await store.writeSession(
      accessToken: 'access',
      refreshToken: 'refresh-still-valid',
      deviceIdentifier: 'device',
    );

    final client = MockClient((request) async {
      return http.Response('{"error":{"message":"Unauthorized"}}', 401);
    });

    final gateway = LaravelAuthorizationGateway(
      baseUrl: 'http://example.test/api/v1',
      tokenStore: store,
      httpClient: client,
      sessionRefresher: _FailingRefresher(),
    );

    final decision = await gateway.authorize(permission: 'profile.view');
    expect(decision.state, AuthorizationState.restricted);
    expect(await store.readRefreshToken(), 'refresh-still-valid');
    expect(await store.readAccessToken(), 'access');
  });
}

final class _FailingRefresher implements SessionRefresher {
  @override
  Future<AppResult<String>> refreshAccessToken() async {
    return const AppError(NetworkFailure('offline'));
  }
}

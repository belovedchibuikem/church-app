import 'dart:convert';

import 'package:family_house_connect_mobile/core/api/api_transport.dart';
import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/api/http_api_transport.dart';
import 'package:family_house_connect_mobile/core/auth/session_token_store.dart';
import 'package:family_house_connect_mobile/core/l10n/locale_holder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late MemorySessionTokenStore store;

  setUp(() {
    store = MemorySessionTokenStore();
  });

  tearDown(() {
    FhcLocaleHolder.languageCode = 'en';
  });

  test('attaches Bearer and X-Device-Identifier from the token store', () async {
    await store.writeSession(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      deviceIdentifier: 'device-1',
    );

    Map<String, String>? seenHeaders;
    final client = MockClient((request) async {
      seenHeaders = request.headers;
      return http.Response(
        jsonEncode({
          'data': {'ok': true},
          'meta': <String, Object?>{},
          'correlation_id': 'corr-1',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final transport = HttpApiTransport(
      tokenStore: store,
      baseUrl: 'http://example.test/api/v1',
      httpClient: client,
    );

    final result = await transport.send(
      const ApiRequest(method: ApiMethod.get, path: '/user/me'),
    );

    expect(result, isA<AppSuccess<ApiResponse>>());
    expect(seenHeaders?['Authorization'], 'Bearer access-1');
    expect(seenHeaders?['X-Device-Identifier'], 'device-1');
    expect(seenHeaders?['Accept'], 'application/json');
  });

  test('maps Laravel validation envelope to ValidationFailure', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'error': {
            'code': 'VALIDATION_FAILED',
            'message': 'The request data is invalid.',
            'details': {
              'fields': {
                'email': ['The email field is required.'],
              },
            },
          },
          'meta': <String, Object?>{},
          'correlation_id': 'corr-422',
        }),
        422,
        headers: {'content-type': 'application/json'},
      );
    });

    final transport = HttpApiTransport(
      tokenStore: store,
      baseUrl: 'http://example.test/api/v1',
      httpClient: client,
    );

    final result = await transport.send(
      const ApiRequest(
        method: ApiMethod.post,
        path: '/mobile/auth/login',
        body: {'email': ''},
        skipAuth: true,
        correlationId: 'client-corr',
        idempotencyKey: 'idem-1',
      ),
    );

    expect(result, isA<AppError<ApiResponse>>());
    final failure = (result as AppError<ApiResponse>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.code, 'VALIDATION_FAILED');
    expect(failure.correlationId, 'corr-422');
    expect(
      (failure as ValidationFailure).errors['email'],
      ['The email field is required.'],
    );
  });

  test('retries once after SessionRefresher on 401', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls += 1;
      if (calls == 1) {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'AUTH_UNAUTHENTICATED',
              'message': 'Authentication is required.',
              'details': <String, Object?>{},
            },
            'meta': <String, Object?>{},
            'correlation_id': 'corr-401',
          }),
          401,
        );
      }
      expect(request.headers['Authorization'], 'Bearer access-2');
      return http.Response(
        jsonEncode({
          'data': {'ok': true},
          'meta': <String, Object?>{},
          'correlation_id': 'corr-ok',
        }),
        200,
      );
    });

    await store.writeSession(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      deviceIdentifier: 'device-1',
    );

    final transport = HttpApiTransport(
      tokenStore: store,
      baseUrl: 'http://example.test/api/v1',
      httpClient: client,
      refresher: _FakeRefresher(),
    );

    final result = await transport.send(
      const ApiRequest(method: ApiMethod.get, path: '/user/me'),
    );

    expect(result, isA<AppSuccess<ApiResponse>>());
    expect(calls, 2);
    expect(await store.readAccessToken(), 'access-2');
  });

  test('forwards correlation and idempotency headers', () async {
    Map<String, String>? seenHeaders;
    final client = MockClient((request) async {
      seenHeaders = request.headers;
      return http.Response(
        jsonEncode({
          'data': null,
          'meta': <String, Object?>{},
          'correlation_id': 'server-corr',
        }),
        200,
      );
    });

    final transport = HttpApiTransport(
      tokenStore: store,
      baseUrl: 'http://example.test/api/v1',
      httpClient: client,
    );

    await transport.send(
      const ApiRequest(
        method: ApiMethod.post,
        path: '/home-church-applications',
        skipAuth: true,
        correlationId: 'client-corr',
        idempotencyKey: 'idem-key',
        body: {'name': 'Test'},
      ),
    );

    expect(seenHeaders?['X-Correlation-ID'], 'client-corr');
    expect(seenHeaders?['Idempotency-Key'], 'idem-key');
  });

  test('includes Accept-Language from FhcLocaleHolder.languageCode', () async {
    FhcLocaleHolder.languageCode = 'fr';

    Map<String, String>? seenHeaders;
    final client = MockClient((request) async {
      seenHeaders = request.headers;
      return http.Response(
        jsonEncode({
          'data': {'ok': true},
          'meta': <String, Object?>{},
          'correlation_id': 'corr-locale',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final transport = HttpApiTransport(
      tokenStore: store,
      baseUrl: 'http://example.test/api/v1',
      httpClient: client,
    );

    final result = await transport.send(
      const ApiRequest(
        method: ApiMethod.get,
        path: '/user/me',
        skipAuth: true,
      ),
    );

    expect(result, isA<AppSuccess<ApiResponse>>());
    expect(seenHeaders?['Accept-Language'], 'fr');
  });
}

final class _FakeRefresher implements SessionRefresher {
  @override
  Future<AppResult<String>> refreshAccessToken() async =>
      const AppSuccess('access-2');
}

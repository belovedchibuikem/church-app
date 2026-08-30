import 'dart:convert';
import 'dart:typed_data';

import 'package:family_house_connect_mobile/core/api/api_transport.dart';
import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/contracts/mobile_repository_contracts.dart';
import 'package:family_house_connect_mobile/features/community/data/event_repository.dart';
import 'package:family_house_connect_mobile/features/content/data/content_repository.dart';
import 'package:family_house_connect_mobile/features/press/data/press_repository.dart';
import 'package:family_house_connect_public_api/public_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('RemotePressRepository.download', () {
    test('returns bytes, content_type, and filename on 200', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/api/v1/press/publications/pub-1/download',
        );
        expect(request.headers['Accept'], '*/*');
        return http.Response.bytes(
          Uint8List.fromList(const [37, 80, 68, 70]),
          200,
          headers: {
            'content-type': 'application/pdf',
            'content-disposition':
                'attachment; filename="Hope and Faith.pdf"',
          },
        );
      });

      final result = await RemotePressRepository(
        baseUrl: 'http://example.test/api/v1',
        httpClient: client,
      ).download('pub-1');

      expect(result, isA<AppSuccess<JsonObject>>());
      final value = (result as AppSuccess<JsonObject>).value;
      expect(value['content_type'], 'application/pdf');
      expect(value['filename'], 'Hope and Faith.pdf');
      expect(value['bytes'], Uint8List.fromList(const [37, 80, 68, 70]));
    });

    test('maps 404 JSON envelope to NotFoundFailure', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'RESOURCE_NOT_FOUND',
              'message': 'The requested resource was not found.',
              'details': <String, Object?>{},
            },
            'meta': <String, Object?>{},
            'correlation_id': 'corr-404',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await RemotePressRepository(
        baseUrl: 'http://example.test/api/v1',
        httpClient: client,
      ).download('missing');

      expect(result, isA<AppError<JsonObject>>());
      final failure = (result as AppError<JsonObject>).failure;
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, 'The requested resource was not found.');
    });
  });

  group('RemoteEventRepository.getTicket', () {
    test('GETs /user/events/registrations/{id} via transport', () async {
      ApiRequest? seen;
      final result = await RemoteEventRepository(
        baseUrl: 'http://example.test/api/v1',
        transport: _FakeTransport((request) async {
          seen = request;
          return AppSuccess(
            const ApiResponse(
              statusCode: 200,
              body: {
                'data': {
                  'id': 'reg-1',
                  'status': 'confirmed',
                },
                'correlation_id': 'corr-1',
              },
            ),
          );
        }),
      ).getTicket('reg-1');

      expect(seen?.method, ApiMethod.get);
      expect(seen?.path, '/user/events/registrations/reg-1');
      expect(result, isA<AppSuccess<JsonObject>>());
      expect((result as AppSuccess<JsonObject>).value['id'], 'reg-1');
    });
  });

  group('RemoteContentRepository', () {
    test('listContentPages maps publicApi data[]', () async {
      final client = FamilyHousePublicApiClient(
        baseUri: Uri.parse('http://example.test'),
        transport: _FakePublicTransport((uri) {
          expect(uri.path, '/api/v1/content/pages');
          return PublicApiTransportResponse(
            statusCode: 200,
            body: {
              'data': [
                {'slug': 'about', 'title': 'About Family House'},
              ],
              'meta': {
                'api_version': 'v1',
                'timestamp': '2026-01-01T00:00:00Z',
              },
              'correlation_id': 'corr-1',
            },
          );
        }),
      );

      final result = await RemoteContentRepository(
        publicApi: client,
      ).listContentPages();

      expect(result, isA<AppSuccess<List<JsonObject>>>());
      final pages = (result as AppSuccess<List<JsonObject>>).value;
      expect(pages.single['slug'], 'about');
    });

    test('getContentPage maps 404 to NotFoundFailure', () async {
      final client = FamilyHousePublicApiClient(
        baseUri: Uri.parse('http://example.test'),
        transport: _FakePublicTransport((uri) {
          expect(uri.path, '/api/v1/content/pages/missing');
          return const PublicApiTransportResponse(
            statusCode: 404,
            body: {
              'error': {
                'code': 'RESOURCE_NOT_FOUND',
                'message': 'The requested resource was not found.',
                'details': <String, Object?>{},
              },
              'correlation_id': 'corr-404',
            },
          );
        }),
      );

      final result = await RemoteContentRepository(
        publicApi: client,
      ).getContentPage('missing');

      expect(result, isA<AppError<JsonObject>>());
      expect((result as AppError<JsonObject>).failure, isA<NotFoundFailure>());
    });
  });
}

final class _FakeTransport implements ApiTransport {
  _FakeTransport(this._send);

  final Future<AppResult<ApiResponse>> Function(ApiRequest request) _send;

  @override
  Future<AppResult<ApiResponse>> send(ApiRequest request) => _send(request);

  @override
  Future<void> cancel(String requestId) async {}
}

final class _FakePublicTransport implements PublicApiTransport {
  _FakePublicTransport(this._get);

  final PublicApiTransportResponse Function(Uri uri) _get;

  @override
  Future<PublicApiTransportResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async =>
      _get(uri);

  @override
  Future<PublicApiTransportResponse> post(
    Uri uri, {
    Map<String, String> headers = const {},
    JsonMap body = const {},
  }) async =>
      throw UnsupportedError('POST is not used by content page reads.');
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/contracts/mobile_repository_contracts.dart';
import 'package:family_house_connect_mobile/features/press/data/press_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _publicationId = '01ARZ3NDEKTSV4RRFFQ69G5FAV';

void main() {
  test('download returns a 200-byte payload without faking success', () async {
    final bytes = Uint8List.fromList(List<int>.filled(200, 0x41));
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(
        request.url.path,
        '/api/v1/press/publications/$_publicationId/download',
      );
      return http.Response.bytes(
        bytes,
        200,
        headers: {
          'content-type': 'application/pdf',
          'content-disposition': 'attachment; filename="Hope.pdf"',
        },
      );
    });

    final repo = RemotePressRepository(
      baseUrl: 'http://example.test/api/v1',
      httpClient: client,
    );
    final result = await repo.download(_publicationId);

    expect(result, isA<AppSuccess<JsonObject>>());
    final value = (result as AppSuccess<JsonObject>).value;
    expect((value['bytes'] as Uint8List).length, 200);
    expect(value['content_type'], contains('application/pdf'));
    expect(value['filename'], 'Hope.pdf');
  });

  test('download maps 404 JSON to NotFoundFailure', () async {
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

    final repo = RemotePressRepository(
      baseUrl: 'http://example.test/api/v1',
      httpClient: client,
    );
    final result = await repo.download(_publicationId);

    expect(result, isA<AppError<JsonObject>>());
    final failure = (result as AppError<JsonObject>).failure;
    expect(failure, isA<NotFoundFailure>());
    expect(failure.message, contains('not found'));
  });

  test('search maps publication_type onto filter query', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/press/publications');
      expect(request.url.queryParameters['filter[publication_type]'], 'sermon');
      return http.Response(
        jsonEncode({
          'data': [
            {'id': _publicationId, 'title': 'Hope Sunday', 'publication_type': 'sermon'},
          ],
          'meta': <String, Object?>{},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repo = RemotePressRepository(
      baseUrl: 'http://example.test/api/v1',
      httpClient: client,
    );
    final result = await repo.search({'publication_type': 'sermon'});
    expect(result, isA<AppSuccess<List<JsonObject>>>());
    final value = (result as AppSuccess<List<JsonObject>>).value;
    expect(value.first['publication_type'], 'sermon');
  });
}

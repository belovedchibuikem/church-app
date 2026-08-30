import 'package:family_house_connect_mobile/core/api/api_transport.dart';
import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/contracts/mobile_repository_contracts.dart';
import 'package:family_house_connect_mobile/features/community/data/event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _registrationId = '01ARZ3NDEKTSV4RRFFQ69G5FAV';

void main() {
  test('getTicket requires transport and does not fake a ticket', () async {
    final repo = RemoteEventRepository(baseUrl: 'http://example.test/api/v1');
    final result = await repo.getTicket(_registrationId);

    expect(result, isA<AppError<JsonObject>>());
    expect(
      (result as AppError<JsonObject>).failure,
      isA<IntegrationUnavailableFailure>(),
    );
  });

  test('getTicket GETs /user/events/registrations/{id}', () async {
    final transport = ScriptedTransport((request) async {
      expect(request.method, ApiMethod.get);
      expect(request.path, '/user/events/registrations/$_registrationId');
      return AppSuccess(
        const ApiResponse(
          statusCode: 200,
          body: {
            'data': {
              'id': _registrationId,
              'status': 'confirmed',
            },
            'meta': <String, Object?>{},
            'correlation_id': 'corr-ticket',
          },
        ),
      );
    });

    final repo = RemoteEventRepository(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.getTicket(_registrationId);

    expect(result, isA<AppSuccess<JsonObject>>());
    final value = (result as AppSuccess<JsonObject>).value;
    expect(value['id'], _registrationId);
    expect(value['status'], 'confirmed');
    expect(transport.requests, hasLength(1));
  });

  test('getTicket maps a 404 envelope to NotFoundFailure', () async {
    final transport = ScriptedTransport((request) async {
      return const AppError(
        NotFoundFailure(
          'The requested resource was not found.',
          code: 'RESOURCE_NOT_FOUND',
        ),
      );
    });

    final repo = RemoteEventRepository(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.getTicket(_registrationId);

    expect(result, isA<AppError<JsonObject>>());
    final failure = (result as AppError<JsonObject>).failure;
    expect(failure, isA<NotFoundFailure>());
    expect(failure.code, 'RESOURCE_NOT_FOUND');
  });

  test('recordFeedback requires transport and does not fake a rating', () async {
    final repo = RemoteEventRepository(baseUrl: 'http://example.test/api/v1');
    final result = await repo.recordFeedback(_registrationId, 5);

    expect(result, isA<AppError<JsonObject>>());
    expect(
      (result as AppError<JsonObject>).failure,
      isA<IntegrationUnavailableFailure>(),
    );
  });

  test('recordFeedback POSTs /user/events/feedback', () async {
    final transport = ScriptedTransport((request) async {
      expect(request.method, ApiMethod.post);
      expect(request.path, '/user/events/feedback');
      final body = request.body as Map<String, Object?>;
      expect(body['registration_id'], _registrationId);
      expect(body['rating'], 5);
      return AppSuccess(
        const ApiResponse(
          statusCode: 201,
          body: {
            'data': {
              'id': '01ARZ3NDEKTSV4RRFFQ69G5FBW',
              'rating': 5,
            },
            'meta': <String, Object?>{},
            'correlation_id': 'corr-feedback',
          },
        ),
      );
    });

    final repo = RemoteEventRepository(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.recordFeedback(_registrationId, 5);

    expect(result, isA<AppSuccess<JsonObject>>());
    expect((result as AppSuccess<JsonObject>).value['rating'], 5);
    expect(transport.requests, hasLength(1));
  });

  test('listMyRegistrations requires transport', () async {
    final repo = RemoteEventRepository(baseUrl: 'http://example.test/api/v1');
    final result = await repo.listMyRegistrations(when: 'upcoming');

    expect(result, isA<AppError<List<JsonObject>>>());
    expect(
      (result as AppError<List<JsonObject>>).failure,
      isA<IntegrationUnavailableFailure>(),
    );
  });

  test('listMyRegistrations GETs /user/events/registrations with filter', () async {
    final transport = ScriptedTransport((request) async {
      expect(request.method, ApiMethod.get);
      expect(request.path, '/user/events/registrations');
      expect(request.query['filter[when]'], 'upcoming');
      return const AppSuccess(
        ApiResponse(
          statusCode: 200,
          body: {
            'data': [
              {
                'id': _registrationId,
                'ticket_code': 'TCK-1',
                'qr_payload': 'payload-1',
              },
            ],
            'meta': <String, Object?>{},
            'correlation_id': 'corr-regs',
          },
        ),
      );
    });

    final repo = RemoteEventRepository(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.listMyRegistrations(when: 'upcoming');

    expect(result, isA<AppSuccess<List<JsonObject>>>());
    final value = (result as AppSuccess<List<JsonObject>>).value;
    expect(value, hasLength(1));
    expect(value.single['ticket_code'], 'TCK-1');
    expect(transport.requests, hasLength(1));
  });
}

final class ScriptedTransport implements ApiTransport {
  ScriptedTransport(this._handler);

  final Future<AppResult<ApiResponse>> Function(ApiRequest request) _handler;
  final List<ApiRequest> requests = [];

  @override
  Future<AppResult<ApiResponse>> send(ApiRequest request) {
    requests.add(request);
    return _handler(request);
  }

  @override
  Future<void> cancel(String requestId) async {}
}

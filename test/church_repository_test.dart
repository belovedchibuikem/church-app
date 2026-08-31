import 'package:family_house_connect_mobile/core/api/api_transport.dart';
import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/contracts/mobile_repository_contracts.dart';
import 'package:family_house_connect_mobile/features/church/data/church_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _churchId = '01ARZ3NDEKTSV4RRFFQ69G5FAV';

void main() {
  test('requestMembership requires transport and does not fake success', () async {
    final repo = ChurchRepositoryImpl(baseUrl: 'http://example.test/api/v1');
    final result = await repo.requestMembership(_churchId);

    expect(result, isA<AppError<void>>());
    expect(
      (result as AppError<void>).failure,
      isA<IntegrationUnavailableFailure>(),
    );
  });

  test('requestMembership POSTs /user/churches/{id}/memberships', () async {
    final transport = ScriptedTransport((request) async {
      expect(request.method, ApiMethod.post);
      expect(request.path, '/user/churches/$_churchId/memberships');
      return const AppSuccess(
        ApiResponse(
          statusCode: 201,
          body: {
            'data': {
              'id': '01ARZ3NDEKTSV4RRFFQ69G5FBW',
              'church_id': _churchId,
              'status': 'active',
            },
            'meta': <String, Object?>{},
            'correlation_id': 'corr-mem',
          },
        ),
      );
    });

    final repo = ChurchRepositoryImpl(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.requestMembership(_churchId);

    expect(result, isA<AppSuccess<void>>());
    expect(transport.requests, hasLength(1));
    expect(transport.requests.single.body, isA<Map>());
  });

  test('listChurchMembers GETs /user/churches/{id}/members', () async {
    final transport = ScriptedTransport((request) async {
      expect(request.method, ApiMethod.get);
      expect(request.path, '/user/churches/$_churchId/members');
      return const AppSuccess(
        ApiResponse(
          statusCode: 200,
          body: {
            'data': [
              {'id': 'm1', 'name': 'Ada'},
            ],
            'meta': <String, Object?>{},
            'correlation_id': 'corr-members',
          },
        ),
      );
    });

    final repo = ChurchRepositoryImpl(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.listChurchMembers(_churchId);

    expect(result, isA<AppSuccess<List<JsonObject>>>());
    expect((result as AppSuccess<List<JsonObject>>).value.single['name'], 'Ada');
  });

  test('joinGroup POSTs /user/groups/{id}/join', () async {
    final transport = ScriptedTransport((request) async {
      expect(request.method, ApiMethod.post);
      expect(request.path, '/user/groups/$_churchId/join');
      return const AppSuccess(
        ApiResponse(
          statusCode: 204,
          body: {
            'data': null,
            'meta': <String, Object?>{},
            'correlation_id': 'corr-join',
          },
        ),
      );
    });

    final repo = ChurchRepositoryImpl(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.joinGroup(_churchId);
    expect(result, isA<AppSuccess<void>>());
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

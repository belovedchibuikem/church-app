import 'package:family_house_connect_mobile/core/api/api_transport.dart';
import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/contracts/mobile_repository_contracts.dart';
import 'package:family_house_connect_mobile/features/mission/data/mission_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _soulId = '01ARZ3NDEKTSV4RRFFQ69G5FAV';
const _mentorAssignmentId = '01ARZ3NDEKTSV4RRFFQ69G5FBW';
const _followUpId = '01ARZ3NDEKTSV4RRFFQ69G5FCX';

void main() {
  test('recordFollowUp requires transport and does not fake success', () async {
    final repo = HttpMissionRepository(baseUrl: 'http://example.test/api/v1');
    final result = await repo.recordFollowUp(_soulId, {
      'mentor_assignment_id': _mentorAssignmentId,
      'channel_code': 'phone',
      'outcome_code': 'reached',
      'occurred_at': '2026-08-01T12:00:00Z',
    });

    expect(result, isA<AppError<JsonObject>>());
    expect(
      (result as AppError<JsonObject>).failure,
      isA<IntegrationUnavailableFailure>(),
    );
  });

  test('recordFollowUp POSTs /admin/mission/souls/{id}/follow-ups', () async {
    final transport = ScriptedTransport((request) async {
      expect(request.method, ApiMethod.post);
      expect(request.path, '/admin/mission/souls/$_soulId/follow-ups');
      expect(request.headers['X-Scope-Type'], 'global');
      expect(request.headers['X-Scope-ID'], 'platform');
      final body = request.body as Map<String, Object?>;
      expect(body['mentor_assignment_id'], _mentorAssignmentId);
      expect(body['channel_code'], 'phone');
      expect(body['outcome_code'], 'reached');
      expect(body['occurred_at'], '2026-08-01T12:00:00Z');
      return AppSuccess(
        const ApiResponse(
          statusCode: 201,
          body: {
            'data': {
              'id': _followUpId,
              'status': 'recorded',
            },
            'meta': <String, Object?>{},
            'correlation_id': 'corr-follow-up',
          },
        ),
      );
    });

    final repo = HttpMissionRepository(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.recordFollowUp(_soulId, {
      'mentor_assignment_id': _mentorAssignmentId,
      'channel_code': 'phone',
      'outcome_code': 'reached',
      'occurred_at': '2026-08-01T12:00:00Z',
    });

    expect(result, isA<AppSuccess<JsonObject>>());
    final value = (result as AppSuccess<JsonObject>).value;
    expect(value['id'], _followUpId);
    expect(transport.requests, hasLength(1));
    expect(transport.requests.single.idempotencyKey, isNotEmpty);
  });

  test('completeFollowUp POSTs /admin/mission/souls/{id}/follow-up-completion',
      () async {
    final transport = ScriptedTransport((request) async {
      expect(request.method, ApiMethod.post);
      expect(
        request.path,
        '/admin/mission/souls/$_soulId/follow-up-completion',
      );
      expect(request.headers['X-Scope-Type'], 'global');
      final body = request.body as Map<String, Object?>;
      expect(body['reason_code'], 'discipleship_connected');
      return AppSuccess(
        const ApiResponse(
          statusCode: 200,
          body: {
            'data': {
              'id': _soulId,
              'status': 'follow_up_completed',
            },
            'meta': <String, Object?>{},
            'correlation_id': 'corr-complete',
          },
        ),
      );
    });

    final repo = HttpMissionRepository(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.completeFollowUp(_soulId, {
      'reason_code': 'discipleship_connected',
    });

    expect(result, isA<AppSuccess<JsonObject>>());
    expect(
      (result as AppSuccess<JsonObject>).value['status'],
      'follow_up_completed',
    );
  });

  test('getSoul GETs /admin/mission/souls/{id}', () async {
    final transport = ScriptedTransport((request) async {
      expect(request.method, ApiMethod.get);
      expect(request.path, '/admin/mission/souls/$_soulId');
      return AppSuccess(
        const ApiResponse(
          statusCode: 200,
          body: {
            'data': {'id': _soulId, 'status': 'new', 'converted_at': null},
            'meta': <String, Object?>{},
            'correlation_id': 'corr-soul',
          },
        ),
      );
    });
    final repo = HttpMissionRepository(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.getSoul(_soulId);
    expect(result, isA<AppSuccess<JsonObject>>());
    expect((result as AppSuccess<JsonObject>).value['converted_at'], isNull);
  });

  test('submitInvitation POSTs /user/mission/invitations', () async {
    final transport = ScriptedTransport((request) async {
      expect(request.method, ApiMethod.post);
      expect(request.path, '/user/mission/invitations');
      final body = request.body as Map<String, Object?>;
      expect(body['title'], 'Invite us');
      return AppSuccess(
        const ApiResponse(
          statusCode: 201,
          body: {
            'data': {'id': _soulId, 'status': 'received'},
            'meta': <String, Object?>{},
            'correlation_id': 'corr-invite',
          },
        ),
      );
    });
    final repo = HttpMissionRepository(
      baseUrl: 'http://example.test/api/v1',
      transport: transport,
    );
    final result = await repo.submitInvitation({'title': 'Invite us'});
    expect(result, isA<AppSuccess<JsonObject>>());
    expect((result as AppSuccess<JsonObject>).value['status'], 'received');
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

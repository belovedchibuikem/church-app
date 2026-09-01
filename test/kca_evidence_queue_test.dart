import 'package:family_house_connect_mobile/core/api/api_transport.dart';
import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/auth/session_token_store.dart';
import 'package:family_house_connect_mobile/features/kca/data/kca_evidence_queue.dart';
import 'package:family_house_connect_mobile/features/kca/data/kca_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final class _ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw http.ClientException('offline');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueue is idempotent per key and remove clears it', () async {
    final queue = KcaEvidenceQueue();
    await queue.enqueue(
      assignmentId: 'asg-1',
      idempotencyKey: 'ev-1',
      filename: 'photo.jpg',
      bytes: const [1, 2, 3],
    );
    await queue.enqueue(
      assignmentId: 'asg-1',
      idempotencyKey: 'ev-1',
      filename: 'photo.jpg',
      bytes: const [9],
    );
    expect((await queue.load()).length, 1);
    await queue.remove('ev-1');
    expect(await queue.load(), isEmpty);
  });

  test('oversized files are not stored on device', () async {
    final queue = KcaEvidenceQueue();
    await queue.enqueue(
      assignmentId: 'asg-1',
      idempotencyKey: 'ev-big',
      filename: 'huge.bin',
      bytes: List<int>.filled(KcaEvidenceQueue.maxBytes + 1, 1),
    );
    expect(await queue.load(), isEmpty);
  });

  test('network failure queues evidence instead of claiming upload', () async {
    final store = MemorySessionTokenStore();
    await store.writeSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      deviceIdentifier: 'device-1',
    );
    final queue = KcaEvidenceQueue();
    final repo = HttpKcaRepository(
      transport: _OkTransport(),
      httpClient: _ThrowingClient(),
      tokenStore: store,
      evidenceQueue: queue,
    );

    final result = await repo.submitEvidence({
      'assignment_id': 'asg-1',
      'filename': 'photo.jpg',
      'bytes': const [1, 2, 3, 4],
      'idempotency_key': 'ev-net-1',
    });

    expect(result, isA<AppSuccess<Map<String, Object?>>>());
    final value = (result as AppSuccess<Map<String, Object?>>).value;
    expect(value['queued'], isTrue);
    expect((await queue.load()).length, 1);
  });
}

final class _OkTransport implements ApiTransport {
  @override
  Future<AppResult<ApiResponse>> send(ApiRequest request) async {
    return AppSuccess(
      ApiResponse(
        statusCode: 201,
        body: {
          'data': {'accepted': true},
          'meta': <String, Object?>{},
        },
      ),
    );
  }

  @override
  Future<void> cancel(String requestId) async {}
}

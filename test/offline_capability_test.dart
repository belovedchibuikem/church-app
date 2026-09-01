import 'package:family_house_connect_mobile/core/api/api_transport.dart';
import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/offline/connectivity_monitor.dart';
import 'package:family_house_connect_mobile/core/offline/local_offline_sync_repository.dart';
import 'package:family_house_connect_mobile/core/offline/offline_aware_transport.dart';
import 'package:family_house_connect_mobile/core/offline/offline_policy.dart';
import 'package:family_house_connect_mobile/core/offline/kca_curriculum_prefetch.dart';
import 'package:family_house_connect_mobile/core/offline/offline_store.dart';
import 'package:family_house_connect_mobile/core/sync/sync_contract.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeTransport implements ApiTransport {
  _FakeTransport({this.online = true});

  bool online;
  final List<ApiRequest> sent = [];
  final Map<String, Object?> getBodies = {};

  @override
  Future<AppResult<ApiResponse>> send(ApiRequest request) async {
    sent.add(request);
    if (!online) {
      return const AppError(NetworkFailure('offline'));
    }
    if (request.method == ApiMethod.get) {
      return AppSuccess(
        ApiResponse(
          statusCode: 200,
          body: {
            'data': getBodies[request.path] ?? {'ok': true, 'path': request.path},
            'meta': <String, Object?>{},
          },
        ),
      );
    }
    return AppSuccess(
      ApiResponse(
        statusCode: 201,
        body: {
          'data': {'accepted': true, 'path': request.path},
          'meta': <String, Object?>{},
        },
      ),
    );
  }

  @override
  Future<void> cancel(String requestId) async {}
}

final class _FailingRemoteSync implements SyncRepository {
  @override
  Future<AppResult<List<SyncItem>>> pendingItems() async =>
      const AppError(NetworkFailure('offline'));

  @override
  Future<AppResult<List<SyncItem>>> requestSync() async =>
      const AppError(NetworkFailure('offline'));

  @override
  Future<AppResult<SyncItem>> retry(String localId) async =>
      const AppError(NotFoundFailure('missing'));

  @override
  Future<AppResult<void>> pauseUpload(String localId) async =>
      const AppSuccess(null);

  @override
  Future<AppResult<void>> resumeUpload(String localId) async =>
      const AppSuccess(null);
}

void main() {
  late MemoryOfflineStore store;
  late ConnectivityMonitor connectivity;
  late _FakeTransport inner;
  late OfflineAwareApiTransport transport;

  setUp(() {
    store = MemoryOfflineStore();
    connectivity = ConnectivityMonitor();
    inner = _FakeTransport();
    transport = OfflineAwareApiTransport(
      inner: inner,
      store: store,
      connectivity: connectivity,
    );
  });

  test('GET responses are served from cache after the network drops', () async {
    final online = await transport.send(
      const ApiRequest(method: ApiMethod.get, path: '/user/prayers'),
    );
    expect(online, isA<AppSuccess<ApiResponse>>());

    inner.online = false;
    final offline = await transport.send(
      const ApiRequest(method: ApiMethod.get, path: '/user/prayers'),
    );
    expect(offline, isA<AppSuccess<ApiResponse>>());
    expect(connectivity.confirmedOffline, isTrue);
    final body = (offline as AppSuccess<ApiResponse>).value.body as Map;
    expect(body['data'], isA<Map>());
  });

  test('safe mutations queue locally and drain when back online', () async {
    inner.online = false;
    final queued = await transport.send(
      const ApiRequest(
        method: ApiMethod.post,
        path: '/user/prayers',
        body: {'summary': 'Pray for the village'},
        idempotencyKey: 'prayer-1',
      ),
    );
    expect(queued, isA<AppSuccess<ApiResponse>>());
    final payload =
        (((queued as AppSuccess<ApiResponse>).value.body as Map)['data'] as Map);
    expect(payload['queued'], isTrue);
    expect((await store.loadOutbox()).length, 1);

    inner.online = true;
    await transport.drainAll();
    expect(await store.loadOutbox(), isEmpty);
    expect(
      inner.sent.where((request) => request.path == '/user/prayers').length,
      2,
    );
  });

  test('payments are not queued or treated as complete offline', () async {
    inner.online = false;
    final result = await transport.send(
      const ApiRequest(
        method: ApiMethod.post,
        path: '/user/payments/giving-intents',
        body: {'amount': 1000},
      ),
    );
    expect(result, isA<AppError<ApiResponse>>());
    expect((result as AppError<ApiResponse>).failure, isA<OfflineFailure>());
    expect(await store.loadOutbox(), isEmpty);
  });

  test('duplicate idempotency keys do not create two outbox rows', () async {
    inner.online = false;
    const request = ApiRequest(
      method: ApiMethod.post,
      path: '/user/needs',
      body: {'summary': 'Need a generator'},
      idempotencyKey: 'need-1',
    );
    await transport.send(request);
    await transport.send(request);
    expect((await store.loadOutbox()).length, 1);
  });

  test('local sync reports outbox items and waits for server confirmation',
      () async {
    inner.online = false;
    await transport.send(
      const ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/lessons/abc/complete',
        body: {'acknowledged': true},
        idempotencyKey: 'lesson-1',
      ),
    );
    final sync = LocalOfflineSyncRepository(
      store: store,
      transport: transport,
      remote: _FailingRemoteSync(),
    );
    final pending = await sync.pendingItems();
    expect(pending, isA<AppSuccess<List<SyncItem>>>());
    expect((pending as AppSuccess<List<SyncItem>>).value, isNotEmpty);

    final requested = await sync.requestSync();
    expect(requested, isA<AppError<List<SyncItem>>>());
    expect(
      (requested as AppError<List<SyncItem>>).failure.message,
      OfflinePolicy.serverConfirmMessage,
    );
  });

  test('GET cache miss explains that content was not downloaded', () async {
    inner.online = false;
    final result = await transport.send(
      const ApiRequest(method: ApiMethod.get, path: '/user/kca/lessons/abc'),
    );
    expect(result, isA<AppError<ApiResponse>>());
    expect(
      (result as AppError<ApiResponse>).failure.message,
      OfflinePolicy.notDownloadedMessage,
    );
  });

  test('KCA directory follow/unfollow can be queued offline', () async {
    inner.online = false;
    const policy = OfflinePolicy();
    expect(
      policy.isQueueableMutation(
        const ApiRequest(
          method: ApiMethod.post,
          path: '/user/kca/directory/abc/follow',
        ),
      ),
      isTrue,
    );
    expect(
      policy.isQueueableMutation(
        const ApiRequest(
          method: ApiMethod.delete,
          path: '/user/kca/directory/abc/follow',
        ),
      ),
      isTrue,
    );

    final queued = await transport.send(
      const ApiRequest(
        method: ApiMethod.post,
        path: '/user/kca/directory/abc/follow',
        idempotencyKey: 'follow-1',
      ),
    );
    expect(queued, isA<AppSuccess<ApiResponse>>());
    expect((await store.loadOutbox()).length, 1);
  });

  test('extractKcaCurriculumIds walks nested modules and assignments', () {
    final ids = extractKcaCurriculumIds(
      modules: [
        {
          'id': 'mod-1',
          'lessons': [
            {
              'id': 'les-1',
              'chapters': [
                {'id': 'ch-1'},
              ],
            },
          ],
        },
      ],
      assignments: [
        {'public_id': 'asg-1'},
      ],
    );
    expect(ids.moduleIds, ['mod-1']);
    expect(ids.lessonIds, ['les-1']);
    expect(ids.chapterIds, ['ch-1']);
    expect(ids.assignmentIds, ['asg-1']);
  });
}

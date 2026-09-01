import '../api/api_transport.dart';
import '../api/app_failure.dart';
import 'connectivity_monitor.dart';
import 'offline_policy.dart';
import 'offline_store.dart';

/// Wraps [HttpApiTransport] with a durable GET cache and mutation outbox.
final class OfflineAwareApiTransport implements ApiTransport {
  OfflineAwareApiTransport({
    required ApiTransport inner,
    required OfflineStore store,
    required ConnectivityMonitor connectivity,
    this.policy = const OfflinePolicy(),
    this.onOutboxChanged,
  })  : _inner = inner,
        _store = store,
        _connectivity = connectivity;

  final ApiTransport _inner;
  final OfflineStore _store;
  final ConnectivityMonitor _connectivity;
  final OfflinePolicy policy;
  final void Function()? onOutboxChanged;

  /// Direct inner transport for outbox drain and health probes.
  ApiTransport get inner => _inner;

  @override
  Future<AppResult<ApiResponse>> send(ApiRequest request) async {
    if (request.method == ApiMethod.get) {
      return _sendGet(request);
    }
    return _sendMutation(request);
  }

  Future<AppResult<ApiResponse>> _sendGet(ApiRequest request) async {
    final result = await _inner.send(request);
    switch (result) {
      case AppSuccess(:final value):
        _connectivity.markOnline();
        if (policy.isCacheableGet(request)) {
          await _store.writeCache(
            SharedPreferencesOfflineStore.cacheKeyFor(request),
            CachedApiEnvelope(
              statusCode: value.statusCode,
              body: value.body,
              correlationId: value.correlationId,
              storedAt: DateTime.now().toUtc(),
            ),
          );
        }
        return result;
      case AppError(:final failure):
        if (failure is! NetworkFailure) return result;
        _connectivity.markOffline();
        if (!policy.isCacheableGet(request)) {
          return AppError(
            OfflineFailure(
              OfflinePolicy.requiresNetworkMessage,
              cause: failure,
            ),
          );
        }
        final cached = await _store.readCache(
          SharedPreferencesOfflineStore.cacheKeyFor(request),
        );
        if (cached != null) {
          return AppSuccess(cached.toResponse());
        }
        return AppError(
          OfflineFailure(
            OfflinePolicy.notDownloadedMessage,
            cause: failure,
          ),
        );
    }
  }

  Future<AppResult<ApiResponse>> _sendMutation(ApiRequest request) async {
    final result = await _inner.send(request);
    switch (result) {
      case AppSuccess():
        _connectivity.markOnline();
        return result;
      case AppError(:final failure):
        if (failure is! NetworkFailure) return result;
        _connectivity.markOffline();
        if (policy.isQueueableMutation(request)) {
          final entry = await _enqueue(request);
          onOutboxChanged?.call();
          return AppSuccess(_queuedResponse(request, entry.id));
        }
        return AppError(
          OfflineFailure(
            OfflinePolicy.requiresNetworkMessage,
            cause: failure,
          ),
        );
    }
  }

  Future<OutboxEntry> _enqueue(ApiRequest request) async {
    final existing = await _store.loadOutbox();
    final idempotency = request.idempotencyKey;
    if (idempotency != null && idempotency.isNotEmpty) {
      for (final item in existing) {
        if (item.idempotencyKey == idempotency) return item;
      }
    }
    final createdAt = DateTime.now().toUtc();
    final entry = OutboxEntry(
      id: 'local-${createdAt.microsecondsSinceEpoch}',
      method: request.method,
      path: request.path,
      query: request.query,
      body: request.body,
      headers: request.headers,
      idempotencyKey: request.idempotencyKey,
      type: policy.typeForPath(request.path),
      state: SyncItemState.queued,
      createdAt: createdAt,
    );
    await _store.upsertOutbox(entry);
    return entry;
  }

  ApiResponse _queuedResponse(ApiRequest request, String localId) {
    final payload = <String, Object?>{
      'local_id': localId,
      'queued': true,
      'sync_state': 'queued',
      'message': OfflinePolicy.queuedSuccessMessage,
    };
    final body = request.body;
    if (body is Map) {
      payload.addAll({
        for (final entry in body.entries) '${entry.key}': entry.value,
      });
    }
    return ApiResponse(
      statusCode: 202,
      body: {
        'data': payload,
        'meta': {'offline_queued': true},
      },
    );
  }

  /// Sends queued mutations through the inner transport (no re-queue loop).
  Future<AppResult<OutboxEntry>> drainOne(OutboxEntry entry) async {
    if (entry.state == SyncItemState.queued ||
        entry.state == SyncItemState.failed) {
      await _store.upsertOutbox(
        entry.copyWith(state: SyncItemState.uploading),
      );
    }
    final result = await _inner.send(entry.toRequest());
    switch (result) {
      case AppSuccess():
        _connectivity.markOnline();
        await _store.removeOutbox(entry.id);
        onOutboxChanged?.call();
        return AppSuccess(
          entry.copyWith(state: SyncItemState.synced),
        );
      case AppError(:final failure):
        if (failure is NetworkFailure) {
          _connectivity.markOffline();
          final paused = entry.copyWith(
            state: SyncItemState.queued,
            attempts: entry.attempts + 1,
            lastError: failure.message,
          );
          await _store.upsertOutbox(paused);
          onOutboxChanged?.call();
          return AppError(failure);
        }
        if (failure is ConflictFailure) {
          final conflicted = entry.copyWith(
            state: SyncItemState.conflict,
            attempts: entry.attempts + 1,
            lastError: failure.message,
          );
          await _store.upsertOutbox(conflicted);
          onOutboxChanged?.call();
          return AppSuccess(conflicted);
        }
        if (failure is ValidationFailure || failure is ForbiddenFailure) {
          await _store.removeOutbox(entry.id);
          onOutboxChanged?.call();
          return AppError(failure);
        }
        final failed = entry.copyWith(
          state: SyncItemState.failed,
          attempts: entry.attempts + 1,
          lastError: failure.message,
        );
        await _store.upsertOutbox(failed);
        onOutboxChanged?.call();
        return AppError(failure);
    }
  }

  Future<void> drainAll() async {
    final items = await _store.loadOutbox();
    for (final item in items) {
      if (item.state == SyncItemState.conflict) continue;
      if (item.state == SyncItemState.synced) {
        await _store.removeOutbox(item.id);
        continue;
      }
      final result = await drainOne(item);
      if (result is AppError<OutboxEntry> && result.failure is NetworkFailure) {
        break;
      }
    }
  }

  Future<AppResult<ApiResponse>> probe() {
    return _inner.send(
      const ApiRequest(
        method: ApiMethod.get,
        path: '/health',
        skipAuth: true,
        timeout: Duration(seconds: 8),
      ),
    );
  }

  @override
  Future<void> cancel(String requestId) => _inner.cancel(requestId);
}

/// Fail-closed stand-in so visual-review widget tests do not block on HTTP.
final class ImmediateNetworkFailureTransport implements ApiTransport {
  const ImmediateNetworkFailureTransport();

  @override
  Future<AppResult<ApiResponse>> send(ApiRequest request) async {
    return const AppError(NetworkFailure('offline'));
  }

  @override
  Future<void> cancel(String requestId) async {}
}


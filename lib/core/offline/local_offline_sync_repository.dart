import '../api/app_failure.dart';
import '../sync/sync_contract.dart';
import 'offline_aware_transport.dart';
import 'offline_policy.dart';
import 'offline_store.dart';

/// Combines the local outbox with Laravel `/user/sync/*`.
final class LocalOfflineSyncRepository implements SyncRepository {
  LocalOfflineSyncRepository({
    required OfflineStore store,
    required OfflineAwareApiTransport transport,
    SyncRepository? remote,
  })  : _store = store,
        _transport = transport,
        _remote = remote;

  final OfflineStore _store;
  final OfflineAwareApiTransport _transport;
  final SyncRepository? _remote;

  @override
  Future<AppResult<List<SyncItem>>> pendingItems() async {
    final local = await _localItems();
    final remote = _remote;
    if (remote == null) return AppSuccess(local);
    final feed = await remote.pendingItems();
    return switch (feed) {
      AppSuccess(:final value) => AppSuccess([...local, ...value]),
      AppError() => AppSuccess(local),
    };
  }

  @override
  Future<AppResult<List<SyncItem>>> requestSync() async {
    await _transport.drainAll();
    final remaining = await _localItems();
    final remote = _remote;
    if (remote == null) {
      return remaining.isEmpty
          ? const AppSuccess(<SyncItem>[])
          : AppSuccess(remaining);
    }
    final checkpoint = await remote.requestSync();
    return switch (checkpoint) {
      AppSuccess() => AppSuccess(remaining),
      AppError(:final failure) => AppError(
          NetworkFailure(
            OfflinePolicy.serverConfirmMessage,
            cause: failure,
            code: failure.code,
            correlationId: failure.correlationId,
          ),
        ),
    };
  }

  @override
  Future<AppResult<SyncItem>> retry(String localId) async {
    final items = await _store.loadOutbox();
    for (final item in items) {
      if (item.id != localId) continue;
      final result = await _transport.drainOne(item);
      return switch (result) {
        AppSuccess(:final value) => AppSuccess(value.toSyncItem()),
        AppError(:final failure) => AppError(failure),
      };
    }
    final remote = _remote;
    if (remote != null) return remote.retry(localId);
    return AppError(NotFoundFailure('Sync item $localId was not found.'));
  }

  @override
  Future<AppResult<void>> pauseUpload(String localId) async {
    final items = await _store.loadOutbox();
    for (final item in items) {
      if (item.id != localId) continue;
      await _store.upsertOutbox(item.copyWith(state: SyncItemState.queued));
      return const AppSuccess(null);
    }
    return _remote?.pauseUpload(localId) ?? const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> resumeUpload(String localId) async {
    return retry(localId).then(
      (result) => switch (result) {
        AppSuccess() => const AppSuccess(null),
        AppError(:final failure) => AppError(failure),
      },
    );
  }

  Future<List<SyncItem>> _localItems() async {
    final items = await _store.loadOutbox();
    return [
      for (final item in items)
        if (item.state != SyncItemState.synced) item.toSyncItem(),
    ];
  }
}

/// Used by visual-review / widget tests so Sync Now does not block on HTTP.
final class ImmediateNetworkSyncRepository implements SyncRepository {
  const ImmediateNetworkSyncRepository();

  AppError<T> _offline<T>() => const AppError(
        NetworkFailure(OfflinePolicy.serverConfirmMessage),
      );

  @override
  Future<AppResult<List<SyncItem>>> pendingItems() async => _offline();

  @override
  Future<AppResult<List<SyncItem>>> requestSync() async => _offline();

  @override
  Future<AppResult<SyncItem>> retry(String localId) async => _offline();

  @override
  Future<AppResult<void>> pauseUpload(String localId) async =>
      const AppSuccess(null);

  @override
  Future<AppResult<void>> resumeUpload(String localId) async =>
      const AppSuccess(null);
}


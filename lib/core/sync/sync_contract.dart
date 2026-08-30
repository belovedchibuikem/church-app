import '../api/app_failure.dart';

enum SyncItemType { attendance, assignment, evidence, report, soul, prayer }

enum SyncItemState {
  queued,
  uploading,
  awaitingServer,
  synced,
  conflict,
  failed,
}

final class SyncItem {
  const SyncItem({
    required this.localId,
    required this.type,
    required this.state,
    required this.idempotencyKey,
    required this.createdAt,
  });

  final String localId;
  final SyncItemType type;
  final SyncItemState state;
  final String idempotencyKey;
  final DateTime createdAt;
}

abstract interface class SyncRepository {
  Future<AppResult<List<SyncItem>>> pendingItems();
  Future<AppResult<List<SyncItem>>> requestSync();
  Future<AppResult<SyncItem>> retry(String localId);
  Future<AppResult<void>> pauseUpload(String localId);
  Future<AppResult<void>> resumeUpload(String localId);
}

final class UnconfiguredSyncRepository implements SyncRepository {
  const UnconfiguredSyncRepository();

  AppError<T> _unavailable<T>() => const AppError(
    IntegrationUnavailableFailure(
      'The Laravel synchronization contract is not configured.',
    ),
  );

  @override
  Future<AppResult<List<SyncItem>>> pendingItems() async => _unavailable();

  @override
  Future<AppResult<List<SyncItem>>> requestSync() async => _unavailable();

  @override
  Future<AppResult<SyncItem>> retry(String localId) async => _unavailable();

  @override
  Future<AppResult<void>> pauseUpload(String localId) async => _unavailable();

  @override
  Future<AppResult<void>> resumeUpload(String localId) async => _unavailable();
}

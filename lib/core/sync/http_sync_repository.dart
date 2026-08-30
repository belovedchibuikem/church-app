import '../api/api_transport.dart';
import '../api/app_failure.dart';
import '../api/transport_repository_helpers.dart';
import '../contracts/mobile_repository_contracts.dart';
import 'sync_contract.dart';

/// Laravel `/user/sync/*` client mapped onto [SyncRepository].
///
/// Contract:
/// - `GET /user/sync/checkpoint` → `{cursor, updated_at}`
/// - `PUT /user/sync/checkpoint` → body `{cursor}`
/// - `GET /user/sync/changes?since=` → `{changes:[…], next_cursor}` (`since` required)
final class HttpSyncRepository
    with TransportRepositoryHelpers
    implements SyncRepository {
  HttpSyncRepository({required ApiTransport transport})
      : _transport = transport;

  static const _epoch = '1970-01-01T00:00:00.000000Z';

  final ApiTransport _transport;
  String? _cursor;
  List<SyncItem> _pending = const [];

  @override
  Future<AppResult<List<SyncItem>>> pendingItems() async {
    final checkpointResult = await _getCheckpoint();
    if (checkpointResult is AppError<String?>) {
      return AppError(checkpointResult.failure);
    }
    final since =
        checkpointResult is AppSuccess<String?>
            ? (checkpointResult.value?.trim().isNotEmpty == true
                ? checkpointResult.value!.trim()
                : _epoch)
            : _epoch;

    final feed = await sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/sync/changes',
        query: {'since': since},
      ),
    );
    return switch (feed) {
      AppError(:final failure) => AppError(failure),
      AppSuccess(:final value) => () {
          final raw = value['changes'];
          final list = <JsonObject>[];
          if (raw is List) {
            for (final item in raw) {
              if (item is Map) {
                list.add(
                  Map<String, Object?>.from(
                    item.map((key, v) => MapEntry('$key', v)),
                  ),
                );
              }
            }
          }
          final next = '${value['next_cursor'] ?? ''}'.trim();
          if (next.isNotEmpty) _cursor = next;

          final items = list.map(_mapChange).toList(growable: false);
          _pending = items
              .where((item) => item.state != SyncItemState.synced)
              .toList(growable: false);
          return AppSuccess(List<SyncItem>.from(_pending));
        }(),
    };
  }

  @override
  Future<AppResult<List<SyncItem>>> requestSync() async {
    final pending = await pendingItems();
    if (pending is AppError<List<SyncItem>>) {
      return pending;
    }

    final cursor =
        (_cursor != null && _cursor!.trim().isNotEmpty)
            ? _cursor!.trim()
            : DateTime.now().toUtc().toIso8601String();

    final put = await sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.put,
        path: '/user/sync/checkpoint',
        body: {'cursor': cursor},
      ),
    );
    return switch (put) {
      AppError(:final failure) => AppError(failure),
      AppSuccess(:final value) => () {
          final next = '${value['cursor'] ?? value['next_cursor'] ?? ''}'.trim();
          if (next.isNotEmpty) _cursor = next;
          _pending = const [];
          return const AppSuccess(<SyncItem>[]);
        }(),
    };
  }

  @override
  Future<AppResult<SyncItem>> retry(String localId) async {
    final pending = await pendingItems();
    switch (pending) {
      case AppError(:final failure):
        return AppError(failure);
      case AppSuccess(:final value):
        for (final item in value) {
          if (item.localId == localId) {
            return AppSuccess(
              SyncItem(
                localId: item.localId,
                type: item.type,
                state: SyncItemState.uploading,
                idempotencyKey: item.idempotencyKey,
                createdAt: item.createdAt,
              ),
            );
          }
        }
        return AppError(
          NotFoundFailure('Sync item $localId was not found.'),
        );
    }
  }

  @override
  Future<AppResult<void>> pauseUpload(String localId) async {
    if (localId.trim().isEmpty) {
      return const AppError(ValidationFailure('Upload id is required.'));
    }
    // Server contract is checkpoint/changes only; pause is acknowledged locally.
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> resumeUpload(String localId) async {
    if (localId.trim().isEmpty) {
      return const AppError(ValidationFailure('Upload id is required.'));
    }
    return const AppSuccess(null);
  }

  Future<AppResult<String?>> _getCheckpoint() async {
    final result = await sendObject(
      _transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/sync/checkpoint'),
    );
    return switch (result) {
      AppError(:final failure) => AppError(failure),
      AppSuccess(:final value) => () {
          final cursor =
              '${value['cursor'] ?? value['checkpoint'] ?? value['since'] ?? ''}'
                  .trim();
          _cursor = cursor.isEmpty ? _cursor : cursor;
          return AppSuccess(_cursor);
        }(),
    };
  }

  SyncItem _mapChange(JsonObject raw) {
    final typeName = '${raw['type'] ?? raw['entity_type'] ?? 'report'}'
        .toLowerCase();
    final stateName = '${raw['state'] ?? raw['status'] ?? 'queued'}'
        .toLowerCase();
    final createdRaw =
        '${raw['updated_at'] ?? raw['created_at'] ?? raw['queued_at'] ?? ''}';
    final createdAt =
        DateTime.tryParse(createdRaw)?.toUtc() ?? DateTime.now().toUtc();
    return SyncItem(
      localId:
          '${raw['id'] ?? raw['local_id'] ?? raw['ulid'] ?? createdAt.millisecondsSinceEpoch}',
      type: switch (typeName) {
        'attendance' => SyncItemType.attendance,
        'assignment' => SyncItemType.assignment,
        'evidence' || 'upload' => SyncItemType.evidence,
        'soul' => SyncItemType.soul,
        'prayer' || 'prayer_request' => SyncItemType.prayer,
        'pastoral_need' || 'need' => SyncItemType.report,
        'notification' => SyncItemType.report,
        'payment_intent' => SyncItemType.report,
        _ => SyncItemType.report,
      },
      state: switch (stateName) {
        'uploading' => SyncItemState.uploading,
        'awaiting' || 'awaiting_server' || 'pending' =>
          SyncItemState.awaitingServer,
        'synced' || 'done' || 'complete' => SyncItemState.synced,
        'conflict' => SyncItemState.conflict,
        'failed' || 'error' => SyncItemState.failed,
        _ => SyncItemState.queued,
      },
      idempotencyKey:
          '${raw['idempotency_key'] ?? raw['id'] ?? createdAt.millisecondsSinceEpoch}',
      createdAt: createdAt,
    );
  }
}

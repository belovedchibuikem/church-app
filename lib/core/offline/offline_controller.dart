import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/app_failure.dart';
import '../sync/sync_contract.dart';
import 'connectivity_monitor.dart';
import 'offline_aware_transport.dart';
import 'offline_store.dart';

/// App-wide offline status, pending count, and sync/probe helpers.
final class OfflineController extends ChangeNotifier {
  OfflineController({
    required this.connectivity,
    required this.store,
    this.transport,
    this.syncRepository,
  }) {
    connectivity.addListener(_onConnectivity);
    _refreshPending();
  }

  final ConnectivityMonitor connectivity;
  final OfflineStore store;
  final OfflineAwareApiTransport? transport;
  SyncRepository? syncRepository;
  Future<void> Function()? extraDrain;

  int pendingCount = 0;
  bool syncing = false;

  bool get isOnline => connectivity.isOnline;

  bool get showOfflineBanner => connectivity.confirmedOffline;

  void _onConnectivity() {
    notifyListeners();
    if (connectivity.isOnline && !syncing) {
      unawaited(syncNow());
    }
  }

  Future<void> _refreshPending() async {
    pendingCount = (await store.loadOutbox()).length;
    notifyListeners();
  }

  void outboxChanged() {
    unawaited(_refreshPending());
  }

  Future<void> markFromFailure(AppFailure failure) async {
    if (failure is NetworkFailure || failure is OfflineFailure) {
      connectivity.markOffline();
    }
  }

  Future<bool> probe() async {
    final wrapped = transport;
    if (wrapped == null) return isOnline;
    final result = await wrapped.probe();
    switch (result) {
      case AppSuccess():
        connectivity.markOnline();
        unawaited(syncNow());
        return true;
      case AppError(:final failure):
        if (failure is NetworkFailure) {
          connectivity.markOffline();
          return false;
        }
        connectivity.markOnline();
        return true;
    }
  }

  Future<AppResult<List<SyncItem>>> syncNow() async {
    if (syncing) {
      return AppSuccess(await store.loadOutbox().then(
            (items) => [for (final item in items) item.toSyncItem()],
          ));
    }
    syncing = true;
    notifyListeners();
    try {
      await extraDrain?.call();
      await transport?.drainAll();
      final repo = syncRepository;
      final result =
          repo == null
              ? const AppSuccess(<SyncItem>[])
              : await repo.requestSync();
      await _refreshPending();
      return result;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> clearDownloadedContent() async {
    await store.clearCache();
    notifyListeners();
  }

  @override
  void dispose() {
    connectivity.removeListener(_onConnectivity);
    super.dispose();
  }
}

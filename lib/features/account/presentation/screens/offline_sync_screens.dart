import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/sync/sync_contract.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

enum OfflineSyncKind {
  offline,
  syncPending,
  syncSuccessful,
  uploadProgress,
  uploadFailed,
  storage,
  lowBandwidth,
  contentUnavailable,
}

class OfflineSyncScreen extends StatefulWidget {
  const OfflineSyncScreen({super.key, required this.kind, this.syncRepository});
  final OfflineSyncKind kind;
  final SyncRepository? syncRepository;

  @override
  State<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends State<OfflineSyncScreen> {
  bool wifiOnly = true;
  bool audioLessons = true;
  bool primaryUploadPaused = false;
  int mediaQuality = 0;

  FhcAsyncValue<List<SyncItem>> _syncState = const FhcAsyncValue.loading();
  bool _syncing = false;

  SyncRepository? get _repo =>
      widget.syncRepository ??
      AppServicesScope.maybeOf(context)?.syncRepository;

  bool get _usesSyncApi =>
      widget.kind == OfflineSyncKind.syncPending ||
      widget.kind == OfflineSyncKind.syncSuccessful ||
      widget.kind == OfflineSyncKind.uploadFailed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_usesSyncApi && _syncState is FhcAsyncLoading) {
      _loadPending();
    }
  }

  Future<void> _loadPending() async {
    final repo = _repo;
    if (repo == null || repo is UnconfiguredSyncRepository) {
      setState(() {
        _syncState = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'account.syncWaiting',
            fallback:
                'Offline sync is waiting on the Laravel sync checkpoint API.',
          ),
        );
      });
      return;
    }

    setState(() => _syncState = const FhcAsyncValue.loading());
    final result = await repo.pendingItems();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _syncState =
              value.isEmpty
                  ? FhcAsyncValue.empty(
                    message: fhcT(
                      context,
                      'account.noItemsWaiting',
                      fallback: 'No items are waiting to sync.',
                    ),
                  )
                  : FhcAsyncValue.data(value);
        });
      case AppError(:final failure):
        setState(() => _syncState = FhcAsyncValue.error(failure));
    }
  }

  Future<void> _requestSync() async {
    final repo = _repo;
    if (repo == null || repo is UnconfiguredSyncRepository) {
      _showMessage(
        fhcT(
          context,
          'account.syncNotConnected',
          fallback:
              'Sync is not connected to the Laravel checkpoint API in this build.',
        ),
      );
      return;
    }
    setState(() => _syncing = true);
    final result = await repo.requestSync();
    if (!mounted) return;
    setState(() => _syncing = false);
    switch (result) {
      case AppSuccess():
        fhcPush(context, '/sync/successful');
      case AppError(:final failure):
        _showMessage(failure.message);
        await _loadPending();
    }
  }

  Future<void> _retryItem(String localId) async {
    final repo = _repo;
    if (repo == null) return;
    final result = await repo.retry(localId);
    if (!mounted) return;
    switch (result) {
      case AppSuccess():
        _showMessage(
          fhcT(
            context,
            'account.retryRequested',
            args: {'id': localId},
            fallback: 'Retry requested for $localId.',
          ),
        );
        await _loadPending();
      case AppError(:final failure):
        _showMessage(failure.message);
    }
  }

  Future<void> _togglePause(String localId) async {
    final repo = _repo;
    if (repo == null) return;
    final result =
        primaryUploadPaused
            ? await repo.resumeUpload(localId)
            : await repo.pauseUpload(localId);
    if (!mounted) return;
    switch (result) {
      case AppSuccess():
        setState(() => primaryUploadPaused = !primaryUploadPaused);
      case AppError(:final failure):
        _showMessage(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec(widget.kind);
    return WorkflowPage(
      title: spec.title,
      domain: WorkflowDomain.utility,
      actionLabel:
          _syncing
              ? fhcT(context, 'account.syncing', fallback: 'Syncing…')
              : spec.action,
      onAction:
          spec.action == null || _syncing ? null : () => _handleAction(spec),
      trailing: _headerAction(widget.kind),
      trailingWidth: FhcSizes.minTap,
      backIcon:
          widget.kind == OfflineSyncKind.offline
              ? Icons.close
              : Icons.chevron_left,
      backTooltip:
          widget.kind == OfflineSyncKind.offline
              ? fhcT(context, 'common.close', fallback: 'Close')
              : fhcT(context, 'common.back', fallback: 'Back'),
      children: _content(widget.kind),
    );
  }

  void _handleAction(_OfflineSpec spec) {
    switch (widget.kind) {
      case OfflineSyncKind.syncPending:
        _requestSync();
      case OfflineSyncKind.storage:
        _showMessage(
          fhcT(
            context,
            'account.cacheCleared',
            fallback: '120 MB of cached temporary files cleared.',
          ),
        );
      case OfflineSyncKind.lowBandwidth:
        _showMessage(
          fhcT(
            context,
            'account.lowBandwidthSaved',
            fallback: 'Low-bandwidth preferences saved on this device.',
          ),
        );
      case OfflineSyncKind.uploadFailed:
        _requestSync();
      default:
        if (spec.next != null) fhcPush(context, spec.next!);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _retryConnection() {
    _showMessage(
      fhcT(
        context,
        'account.checkingConnection',
        fallback: 'Checking the connection. Offline content remains available.',
      ),
    );
  }

  Widget? _headerAction(OfflineSyncKind kind) => switch (kind) {
    OfflineSyncKind.offline => IconButton(
      onPressed: _retryConnection,
      icon: const Icon(Icons.refresh),
      tooltip: fhcT(
        context,
        'account.retryConnection',
        fallback: 'Retry connection',
      ),
    ),
    OfflineSyncKind.syncPending => IconButton(
      onPressed: _loadPending,
      icon: const Icon(Icons.refresh),
      tooltip: fhcT(
        context,
        'account.refreshPendingSync',
        fallback: 'Refresh pending sync',
      ),
    ),
    OfflineSyncKind.syncSuccessful => Icon(
      Icons.check_circle_outline,
      color: FhcColors.green,
      semanticLabel: fhcT(
        context,
        'account.syncConfirmed',
        fallback: 'Sync confirmed',
      ),
    ),
    OfflineSyncKind.uploadProgress => IconButton(
      onPressed: () => _togglePause('primary-upload'),
      icon: Icon(
        primaryUploadPaused
            ? Icons.play_circle_outline
            : Icons.pause_circle_outline,
      ),
      tooltip:
          primaryUploadPaused
              ? fhcT(context, 'account.resumeUpload', fallback: 'Resume upload')
              : fhcT(context, 'account.pauseUpload', fallback: 'Pause upload'),
    ),
    OfflineSyncKind.storage => IconButton(
      onPressed: () => fhcPush(context, '/settings/low-bandwidth'),
      icon: const Icon(Icons.settings_outlined),
      tooltip: fhcT(
        context,
        'account.mediaSettings',
        fallback: 'Media settings',
      ),
    ),
    OfflineSyncKind.lowBandwidth => IconButton(
      onPressed:
          () => _showMessage(
            fhcT(
              context,
              'account.lowBandwidthInfo',
              fallback:
                  'These preferences affect future streams and downloads.',
            ),
          ),
      icon: const Icon(Icons.info_outline),
      tooltip: fhcT(
        context,
        'account.aboutLowBandwidth',
        fallback: 'About low-bandwidth mode',
      ),
    ),
    OfflineSyncKind.uploadFailed || OfflineSyncKind.contentUnavailable => null,
  };

  _OfflineSpec _spec(OfflineSyncKind kind) => switch (kind) {
    OfflineSyncKind.offline => _OfflineSpec(
      fhcT(context, 'account.youreOffline', fallback: 'You’re Offline'),
      fhcT(context, 'account.goToDownloads', fallback: 'Go to Downloads'),
      '/downloads/storage',
    ),
    OfflineSyncKind.syncPending => _OfflineSpec(
      fhcT(context, 'account.syncPending', fallback: 'Sync Pending'),
      fhcT(context, 'account.syncNow', fallback: 'Sync Now'),
      null,
    ),
    OfflineSyncKind.syncSuccessful => _OfflineSpec(
      fhcT(context, 'account.syncSuccessful', fallback: 'Sync Successful'),
      fhcT(context, 'account.great', fallback: 'Great!'),
      '/hub',
    ),
    OfflineSyncKind.uploadProgress => _OfflineSpec(
      fhcT(
        context,
        'account.uploadingEvidence',
        fallback: 'Uploading Evidence',
      ),
      null,
      null,
    ),
    OfflineSyncKind.uploadFailed => _OfflineSpec(
      fhcT(context, 'account.uploadFailed', fallback: 'Upload Failed'),
      fhcT(context, 'account.retryAll', fallback: 'Retry All'),
      null,
    ),
    OfflineSyncKind.storage => _OfflineSpec(
      fhcT(
        context,
        'account.downloadsStorage',
        fallback: 'Downloads & Storage',
      ),
      fhcT(context, 'account.clearCache', fallback: 'Clear Cache (120 MB)'),
      null,
    ),
    OfflineSyncKind.lowBandwidth => _OfflineSpec(
      fhcT(context, 'account.lowBandwidthMode', fallback: 'Low-Bandwidth Mode'),
      fhcT(context, 'account.saveSettings', fallback: 'Save Settings'),
      null,
    ),
    OfflineSyncKind.contentUnavailable => _OfflineSpec(
      fhcT(
        context,
        'account.contentNotAvailable',
        fallback: 'Content Not Available',
      ),
      fhcT(context, 'account.goBackHome', fallback: 'Go Back Home'),
      '/hub',
    ),
  };

  List<Widget> _content(OfflineSyncKind kind) => switch (kind) {
    OfflineSyncKind.offline => [
      _hero(
        Icons.cloud_off_outlined,
        fhcT(context, 'account.youreOfflineHeadline', fallback: 'You’re offline'),
        fhcT(
          context,
          'account.offlineCopy',
          fallback:
              'Some features are unavailable, but you can still access downloaded content.',
        ),
      ),
      WorkflowSectionTitle(
        fhcT(context, 'account.availableOffline', fallback: 'Available Offline'),
      ),
      _rows([
        (
          fhcT(context, 'account.kcaLessons', fallback: 'KCA Lessons'),
          fhcT(
            context,
            'account.lessonsDownloaded',
            fallback: '12 lessons downloaded',
          ),
        ),
        (
          fhcT(context, 'account.pdfMaterials', fallback: 'PDF Materials'),
          fhcT(
            context,
            'account.filesDownloaded',
            fallback: '28 files downloaded',
          ),
        ),
        (
          fhcT(context, 'account.audioMessages', fallback: 'Audio Messages'),
          fhcT(
            context,
            'account.messagesDownloaded',
            fallback: '16 messages downloaded',
          ),
        ),
        (
          fhcT(context, 'account.churchMedia', fallback: 'Church Media'),
          fhcT(
            context,
            'account.videosDownloaded',
            fallback: '8 videos downloaded',
          ),
        ),
      ]),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _retryConnection,
        icon: const Icon(Icons.refresh),
        label: Text(
          fhcT(
            context,
            'account.retryConnectionButton',
            fallback: 'Retry Connection',
          ),
        ),
      ),
    ],
    OfflineSyncKind.syncPending => [
      _notice(
        fhcT(context, 'account.syncPending', fallback: 'Sync Pending'),
        fhcT(
          context,
          'account.syncPendingCopy',
          fallback:
              'Items below come from GET /user/sync/changes. Sync Now updates the checkpoint.',
        ),
        FhcColors.orange,
      ),
      SizedBox(
        height: 320,
        child: FhcAsyncBody<List<SyncItem>>(
          value: _syncState,
          onRetry: _loadPending,
          emptyTitle: fhcT(
            context,
            'account.queueEmpty',
            fallback: 'Queue empty',
          ),
          emptyMessage: fhcT(
            context,
            'account.nothingWaitingToSync',
            fallback: 'Nothing is waiting to sync.',
          ),
          unavailableTitle: fhcT(
            context,
            'account.syncUnavailable',
            fallback: 'Sync unavailable',
          ),
          builder: (context, items) {
            return _rows([
              for (final item in items)
                (
                  _labelForType(item.type),
                  '${_labelForState(item.state)} · ${item.localId}',
                ),
            ], trailing: Icons.sync);
          },
        ),
      ),
    ],
    OfflineSyncKind.syncSuccessful => [
      _hero(
        Icons.check_circle,
        fhcT(context, 'account.allSynced', fallback: 'All synced!'),
        fhcT(
          context,
          'account.allSyncedCopy',
          fallback: 'Your checkpoint was updated with the Laravel sync API.',
        ),
      ),
      WorkflowSectionTitle(
        fhcT(context, 'account.syncedItems', fallback: 'Synced Items'),
      ),
      SizedBox(
        height: 280,
        child: FhcAsyncBody<List<SyncItem>>(
          value: _syncState,
          onRetry: _loadPending,
          emptyTitle: fhcT(
            context,
            'account.nothingPending',
            fallback: 'Nothing pending',
          ),
          emptyMessage: fhcT(
            context,
            'account.localQueueClear',
            fallback: 'Your local queue is clear.',
          ),
          builder: (context, items) {
            final shown =
                items.isEmpty
                    ? <(String, String)>[
                      (
                        fhcT(
                          context,
                          'account.checkpoint',
                          fallback: 'Checkpoint',
                        ),
                        fhcT(
                          context,
                          'account.updatedOnServer',
                          fallback: 'Updated on server',
                        ),
                      ),
                    ]
                    : [
                      for (final item in items)
                        (
                          _labelForType(item.type),
                          _labelForState(item.state),
                        ),
                    ];
            return _rows(shown, trailing: Icons.check);
          },
        ),
      ),
    ],
    OfflineSyncKind.uploadProgress => [
      _upload(
        'Baptism Report.pdf',
        fhcT(
          context,
          'account.resumableUploadSubtitle',
          fallback: 'PDF Document • resumable via SyncRepository',
        ),
        .78,
        canPause: true,
      ),
      _notice(
        fhcT(
          context,
          'account.resumableUploads',
          fallback: 'Resumable uploads',
        ),
        fhcT(
          context,
          'account.resumableUploadsCopy',
          fallback: 'Pause/resume calls SyncRepository pauseUpload / resumeUpload.',
        ),
        FhcColors.green,
      ),
    ],
    OfflineSyncKind.uploadFailed => [
      _notice(
        fhcT(context, 'account.uploadFailed', fallback: 'Upload Failed'),
        fhcT(
          context,
          'account.uploadFailedCopy',
          fallback:
              'Failed items come from the sync changes feed. Retry uses SyncRepository.retry.',
        ),
        FhcColors.red,
      ),
      SizedBox(
        height: 280,
        child: FhcAsyncBody<List<SyncItem>>(
          value: _syncState,
          onRetry: _loadPending,
          emptyTitle: fhcT(
            context,
            'account.noFailedUploads',
            fallback: 'No failed uploads',
          ),
          emptyMessage: fhcT(
            context,
            'account.nothingNeedsRetry',
            fallback: 'Nothing needs a retry right now.',
          ),
          builder: (context, items) {
            final failed =
                items
                    .where((item) => item.state == SyncItemState.failed)
                    .toList();
            final rows = failed.isEmpty ? items : failed;
            return _rows(
              [
                for (final item in rows)
                  (
                    _labelForType(item.type),
                    '${_labelForState(item.state)} · ${item.localId}',
                  ),
              ],
              trailing: Icons.refresh,
              accent: FhcColors.red,
              onTap: (index) {
                if (index < rows.length) {
                  _retryItem(rows[index].localId);
                }
              },
            );
          },
        ),
      ),
    ],
    OfflineSyncKind.storage => [
      WorkflowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fhcT(context, 'account.storageUsed', fallback: 'Storage Used'),
              style: FhcTypography.label,
            ),
            const SizedBox(height: 5),
            const Text(
              '1.62 GB / 10 GB',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            WorkflowProgress(
              label: fhcT(
                context,
                'account.deviceStorage',
                fallback: 'Device storage',
              ),
              value: .16,
              trailing: '16%',
            ),
          ],
        ),
      ),
      WorkflowSectionTitle(
        fhcT(
          context,
          'account.downloadedContent',
          fallback: 'Downloaded Content',
        ),
      ),
      WorkflowSegments(
        labels: [
          fhcT(context, 'account.all', fallback: 'All'),
          fhcT(context, 'account.pdf', fallback: 'PDF'),
          fhcT(context, 'account.audio', fallback: 'Audio'),
          fhcT(context, 'account.video', fallback: 'Video'),
          fhcT(context, 'member.kca', fallback: 'KCA'),
        ],
      ),
      const SizedBox(height: 10),
      _rows([
        (
          fhcT(context, 'account.kcaLessons', fallback: 'KCA Lessons'),
          fhcT(context, 'account.kcaLessonsSize', fallback: '420 MB • 12 items'),
        ),
        (
          fhcT(context, 'account.pdfMaterials', fallback: 'PDF Materials'),
          fhcT(
            context,
            'account.pdfMaterialsSize',
            fallback: '630 MB • 28 items',
          ),
        ),
        (
          fhcT(context, 'account.audioMessages', fallback: 'Audio Messages'),
          fhcT(
            context,
            'account.audioMessagesSize',
            fallback: '280 MB • 16 items',
          ),
        ),
        (
          fhcT(context, 'account.videos', fallback: 'Videos'),
          fhcT(context, 'account.videosSize', fallback: '220 MB • 8 items'),
        ),
        (
          fhcT(context, 'account.kcaMaterials', fallback: 'KCA Materials'),
          fhcT(
            context,
            'account.kcaMaterialsSize',
            fallback: '90 MB • 6 items',
          ),
        ),
      ]),
    ],
    OfflineSyncKind.lowBandwidth => [
      _notice(
        fhcT(
          context,
          'account.optimizeExperience',
          fallback: 'Optimize your experience',
        ),
        fhcT(
          context,
          'account.optimizeExperienceCopy',
          fallback: 'Choose how you want to use media when your internet is slow.',
        ),
        FhcColors.green,
      ),
      WorkflowSectionTitle(
        fhcT(context, 'account.mediaQuality', fallback: 'Media Quality'),
      ),
      _quality(
        0,
        fhcT(
          context,
          'account.audioOnlyRecommended',
          fallback: 'Audio Only (Recommended)',
        ),
        fhcT(
          context,
          'account.audioOnlyCopy',
          fallback: 'Best for very low bandwidth',
        ),
      ),
      _quality(
        1,
        fhcT(context, 'account.lowVideoQuality', fallback: 'Low Video Quality'),
        fhcT(
          context,
          'account.lowVideoQualityCopy',
          fallback: '360p – Uses less data',
        ),
      ),
      _quality(
        2,
        fhcT(context, 'account.standardQuality', fallback: 'Standard Quality'),
        fhcT(
          context,
          'account.standardQualityCopy',
          fallback: '480p – Good balance',
        ),
      ),
      _quality(
        3,
        fhcT(context, 'account.highQuality', fallback: 'High Quality'),
        fhcT(
          context,
          'account.highQualityCopy',
          fallback: '720p – Uses more data',
        ),
      ),
      WorkflowSectionTitle(
        fhcT(context, 'member.downloads', fallback: 'Downloads'),
      ),
      _toggle(
        fhcT(
          context,
          'account.downloadWifiOnly',
          fallback: 'Download over Wi-Fi only',
        ),
        wifiOnly,
        (value) {
          setState(() => wifiOnly = value);
        },
      ),
      _toggle(
        fhcT(
          context,
          'account.autoDownloadKcaAudio',
          fallback: 'Auto download KCA lessons (Audio)',
        ),
        audioLessons,
        (value) {
          setState(() => audioLessons = value);
        },
      ),
    ],
    OfflineSyncKind.contentUnavailable => [
      const SizedBox(height: 34),
      _hero(
        Icons.link_off,
        fhcT(
          context,
          'account.couldNotOpenContent',
          fallback: 'We couldn’t open this content',
        ),
        fhcT(
          context,
          'account.couldNotOpenContentCopy',
          fallback: 'It may have been removed or is no longer available.',
        ),
      ),
      WorkflowSectionTitle(
        fhcT(context, 'account.whatYouCanDo', fallback: 'What you can do'),
      ),
      _rows([
        (
          fhcT(
            context,
            'account.goBackPreviousPage',
            fallback: 'Go back to the previous page',
          ),
          fhcT(
            context,
            'account.useBackButton',
            fallback: 'Use the back button',
          ),
        ),
        (
          fhcT(
            context,
            'account.searchSimilarContent',
            fallback: 'Search for similar content',
          ),
          fhcT(
            context,
            'account.browseRelatedResources',
            fallback: 'Browse related resources',
          ),
        ),
        (
          fhcT(
            context,
            'account.checkInternetConnection',
            fallback: 'Check your internet connection',
          ),
          fhcT(
            context,
            'account.retryWhenOnline',
            fallback: 'Retry when online',
          ),
        ),
        (
          fhcT(
            context,
            'account.contactSupportHelp',
            fallback: 'Contact support if you need help',
          ),
          fhcT(
            context,
            'account.weAreHereToAssist',
            fallback: 'We are here to assist',
          ),
        ),
      ]),
    ],
  };

  String _labelForType(SyncItemType type) => switch (type) {
    SyncItemType.attendance => fhcT(
      context,
      'account.attendance',
      fallback: 'Attendance',
    ),
    SyncItemType.assignment => fhcT(
      context,
      'account.assignments',
      fallback: 'Assignments',
    ),
    SyncItemType.evidence => fhcT(
      context,
      'account.evidenceUploads',
      fallback: 'Evidence Uploads',
    ),
    SyncItemType.report => fhcT(context, 'account.reports', fallback: 'Reports'),
    SyncItemType.soul => fhcT(
      context,
      'account.soulCapture',
      fallback: 'Soul Capture',
    ),
    SyncItemType.prayer => fhcT(
      context,
      'account.prayerRequestItems',
      fallback: 'Prayer Requests',
    ),
  };

  String _labelForState(SyncItemState state) => switch (state) {
    SyncItemState.queued => fhcT(context, 'account.waiting', fallback: 'waiting'),
    SyncItemState.uploading => fhcT(
      context,
      'account.uploading',
      fallback: 'uploading',
    ),
    SyncItemState.awaitingServer => fhcT(
      context,
      'account.awaitingServer',
      fallback: 'awaiting server',
    ),
    SyncItemState.synced => fhcT(context, 'account.synced', fallback: 'synced'),
    SyncItemState.conflict => fhcT(
      context,
      'account.conflict',
      fallback: 'conflict',
    ),
    SyncItemState.failed => fhcT(context, 'account.failed', fallback: 'failed'),
  };

  Widget _hero(IconData icon, String title, String subtitle) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: FhcColors.canvas,
      borderRadius: BorderRadius.circular(FhcRadius.card),
    ),
    child: Column(
      children: [
        Icon(icon, size: 76, color: FhcColors.greenDark),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(subtitle, textAlign: TextAlign.center, style: FhcTypography.body),
      ],
    ),
  );

  Widget _notice(String title, String subtitle, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(subtitle, style: FhcTypography.caption),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _rows(
    List<(String, String)> values, {
    IconData trailing = Icons.chevron_right,
    Color accent = FhcColors.green,
    ValueChanged<int>? onTap,
  }) => WorkflowCard(
    child: Column(
      children: [
        for (var index = 0; index < values.length; index++)
          WorkflowRow(
            title: values[index].$1,
            subtitle: values[index].$2,
            accent: accent,
            onTap: onTap == null ? null : () => onTap(index),
            trailing: Icon(trailing, size: 18, color: accent),
          ),
      ],
    ),
  );

  Widget _upload(
    String name,
    String subtitle,
    double value, {
    bool canPause = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: WorkflowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: FhcColors.mint,
                child: Icon(
                  Icons.insert_drive_file,
                  size: 18,
                  color: FhcColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(subtitle, style: FhcTypography.caption),
                  ],
                ),
              ),
              if (canPause)
                IconButton(
                  onPressed: () => _togglePause('primary-upload'),
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  tooltip:
                      primaryUploadPaused
                          ? fhcT(
                            context,
                            'account.resumeUpload',
                            fallback: 'Resume upload',
                          )
                          : fhcT(
                            context,
                            'account.pauseUpload',
                            fallback: 'Pause upload',
                          ),
                  icon: Icon(
                    primaryUploadPaused
                        ? Icons.play_circle_outline
                        : Icons.pause_circle_outline,
                  ),
                )
              else
                Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(FhcRadius.sm),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: FhcColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(FhcColors.green),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _quality(int index, String title, String subtitle) {
    final selected = mediaQuality == index;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: () => setState(() => mediaQuality = index),
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: WorkflowCard(
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: FhcColors.green,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(subtitle, style: FhcTypography.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) =>
      WorkflowCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Switch(
              value: value,
              activeTrackColor: FhcColors.green,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}

class _OfflineSpec {
  const _OfflineSpec(this.title, this.action, this.next);
  final String title;
  final String? action;
  final String? next;
}

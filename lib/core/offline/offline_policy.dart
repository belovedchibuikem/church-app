import '../api/api_transport.dart';
import '../sync/sync_contract.dart';

/// Rules for remote-area offline use.
///
/// Reads that succeeded while online are served from the durable cache.
/// Safe drafts are queued. Privileged outcomes (payments, membership,
/// certificates, applications, MFA) stay fail-closed until the server answers.
final class OfflinePolicy {
  const OfflinePolicy();

  static const queuedSuccessMessage =
      'Saved on this device. It will sync when a connection is available.';

  static const serverConfirmMessage =
      'Sync requested. Waiting for authoritative server confirmation.';

  static const requiresNetworkMessage =
      'This action needs a network connection and cannot be completed offline.';

  static const notDownloadedMessage =
      'You’re offline and this content has not been downloaded yet. Open it once while online, or wait for the next sync.';

  bool isCacheableGet(ApiRequest request) {
    if (request.method != ApiMethod.get) return false;
    final path = _norm(request.path);
    if (path.contains('/health')) return false;
    if (path.contains('/sync/')) return false;
    if (path.contains('/mobile/auth')) return false;
    if (path.contains('/payments')) return false;
    if (path.contains('/authorization/check')) return false;
    return true;
  }

  bool isQueueableMutation(ApiRequest request) {
    if (request.method == ApiMethod.get) return false;
    final path = _norm(request.path);
    if (_neverQueue(path)) return false;
    if (path.contains('/kca/applications')) {
      final body = request.body;
      if (body is Map && body['finalize'] == true) return false;
      return true;
    }
    return _queueablePrefixes.any(path.startsWith);
  }

  bool requiresLiveNetwork(ApiRequest request) {
    if (request.method == ApiMethod.get) return false;
    return _neverQueue(_norm(request.path));
  }

  SyncItemType typeForPath(String path) {
    final normalized = _norm(path);
    if (normalized.contains('/prayer')) return SyncItemType.prayer;
    if (normalized.contains('/attendance')) return SyncItemType.attendance;
    if (normalized.contains('/evidence') || normalized.contains('/files')) {
      return SyncItemType.evidence;
    }
    if (normalized.contains('/souls') || normalized.contains('/soul')) {
      return SyncItemType.soul;
    }
    if (normalized.contains('/kca/') && normalized.contains('/complete')) {
      return SyncItemType.assignment;
    }
    if (normalized.contains('/assignments')) return SyncItemType.assignment;
    return SyncItemType.report;
  }

  bool _neverQueue(String path) {
    return path.contains('/mobile/auth') ||
        path.contains('/payments') ||
        path.contains('/giving') ||
        path.contains('/authorization') ||
        path.contains('/capabilities') ||
        path.contains('/consents') ||
        path.contains('/privacy') ||
        path.contains('/memberships') ||
        path.contains('/certificates') ||
        path.contains('/sync/');
  }

  static const _queueablePrefixes = <String>[
    '/user/prayers',
    '/user/needs',
    '/user/home-churches',
    '/user/kca/lessons',
    '/user/kca/chapters',
    '/user/kca/notes',
    '/user/kca/assignments',
    '/user/kca/applications',
    '/user/kca/directory',
    '/user/bible',
    '/user/messages',
    '/user/notifications',
    '/user/events/feedback',
    '/user/preferences',
    '/admin/mission/crusades',
    '/admin/mission/souls',
  ];

  String _norm(String path) {
    var value = path.trim();
    if (value.isEmpty) return '/';
    if (!value.startsWith('/')) value = '/$value';
    if (value.length > 1 && value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}

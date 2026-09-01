import 'package:flutter/foundation.dart';

/// Tracks whether the last transport attempt reached the network.
///
/// Starts optimistic (online). The first [NetworkFailure] flips it off; any
/// HTTP success flips it back on. No extra connectivity plugin — works on web.
final class ConnectivityMonitor extends ChangeNotifier {
  ConnectivityMonitor({bool initiallyOnline = true}) : _online = initiallyOnline;

  bool _online;
  bool _confirmedOffline = false;

  bool get isOnline => _online;

  /// True only after at least one failed network attempt.
  bool get confirmedOffline => _confirmedOffline && !_online;

  void markOnline() {
    final changed = !_online || _confirmedOffline;
    _online = true;
    _confirmedOffline = false;
    if (changed) notifyListeners();
  }

  void markOffline() {
    final changed = _online || !_confirmedOffline;
    _online = false;
    _confirmedOffline = true;
    if (changed) notifyListeners();
  }
}

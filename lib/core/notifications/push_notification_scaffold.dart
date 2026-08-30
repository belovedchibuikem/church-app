/// Push registration scaffold.
///
/// Honest limit: no FCM/APNs SDK is bound until OD-009 selects a provider and
/// store credentials / `google-services.json` / APNs keys are supplied.
/// Callers should treat [isConfigured] as false and keep notification UX
/// on the in-app Laravel `/user/notifications` feed.
final class PushNotificationScaffold {
  const PushNotificationScaffold();

  bool get isConfigured => false;

  Future<String?> requestToken() async {
    // Not implemented — returning null is intentional (not a fake token).
    return null;
  }

  Future<void> registerDevice({required String deviceIdentifier}) async {
    // No-op until a provider adapter is approved.
  }
}

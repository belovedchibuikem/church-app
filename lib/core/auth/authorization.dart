import 'package:flutter/foundation.dart';

enum AuthorizationState { allowed, unauthenticated, forbidden, restricted }

@immutable
class AuthorizationDecision {
  const AuthorizationDecision(this.state, {this.reason});

  const AuthorizationDecision.allowed()
    : state = AuthorizationState.allowed,
      reason = null;

  final AuthorizationState state;
  final String? reason;

  bool get isAllowed => state == AuthorizationState.allowed;
}

/// Client permission → Laravel canonical codes (mirrors
/// `MobilePermissionAliasCatalog`). Unknown keys fall through to
/// `mobile.app.access` on the server — document provisional UI codes in
/// KNOWN_GAPS KG-008 rather than inventing new Laravel permissions.
const Map<String, String> kMobilePermissionAliases = {
  'profile.view': 'identity.preferences.manage',
  'settings.view': 'identity.preferences.manage',
  'settings.notifications.manage': 'identity.preferences.manage',
  'settings.communications.manage': 'identity.preferences.manage',
  'security.sessions.manage': 'identity.security.sessions.view',
  'consents.manage_own': 'identity.consents.manage',
  'privacy.manage_own': 'identity.consents.manage',
  'privacy.export_own': 'identity.consents.manage',
  'privacy.delete_own': 'identity.consents.manage',
  'church.reports.view': 'church.churches.view',
  'church.followup.view': 'church.follow_up.view',
  'church.attendance.manage': 'church.churches.manage',
  'church.activities.manage': 'church.churches.manage',
  'home_church.members.view': 'church.home_churches.view',
  'home_church.attendance.manage': 'church.home_churches.view',
  'home_church.activities.manage': 'church.home_churches.view',
  'home_church.reports.view': 'church.home_churches.view',
  'home_church.reports.create': 'church.home_churches.view',
  'home_church.needs.manage': 'church.home_churches.view',
  'leadership.dashboard.view': 'church.churches.view',
  'altar_call.followup.view': 'church.follow_up.view',
  'mission.dashboard.view': 'mission.crusades.view',
  'mission.souls.create': 'mission.souls.capture',
  'mission.souls.view': 'mission.souls.view',
  'mission.mentors.assign': 'mission.mentors.assign',
  'mission.assignments.view': 'mission.crusades.view',
  'kca.dashboard.view': 'kca.enrollments.view',
  'kca.evidence.review': 'kca.evidence.view',
  'kca.certification.view_own': 'kca.certificates.view',
  'kca.admission.view_own': 'kca.applications.view',
  'kca.attendance.view': 'kca.enrollments.view',
  'kca.mentoring.view': 'kca.enrollments.view',
  'kca.assessment.view_own': 'kca.assessments.view',
  'kca.assessments.view_own': 'kca.assessments.view',
  'kca.certificate.view_own': 'kca.certificates.view',
  'kca.reviews.manage': 'kca.applications.view',
  'kca.admission.manage': 'kca.applications.view',
  'kca.lessons.deliver': 'kca.enrollments.view',
  'kca.mentoring.intervene': 'kca.enrollments.view',
  'church.finance.view': 'finance.payment_intents.view',
  'home_church.finance.view': 'finance.payment_intents.view',
  'giving.history.view': kMobileAppAccessPermission,
  'payments.receipts.view_own': kMobileAppAccessPermission,
  'payments.history.view_own': kMobileAppAccessPermission,
  'payments.transactions.view_own': kMobileAppAccessPermission,
  'payments.refunds.view_own': 'finance.payment_refunds.view',
  'payments.disputes.view_own': 'finance.payment_disputes.view',
  'notifications.view': 'communications.notifications.view',
};

const String kMobileAppAccessPermission = 'mobile.app.access';

String canonicalizeMobilePermission(String clientPermission) =>
    kMobilePermissionAliases[clientPermission] ?? kMobileAppAccessPermission;

abstract interface class AuthorizationGateway {
  Future<AuthorizationDecision> authorize({
    required String permission,
    String? resourceId,
    String? organizationScope,
  });

  /// Persist mobile access credentials. Production gateways must also send
  /// `X-Device-Identifier` with protected user calls.
  Future<void> bindSession({
    required String accessToken,
    required String deviceIdentifier,
  });

  Future<void> clearSession();

  /// Prefetch `GET /user/capabilities` when a session is present.
  Future<void> prefetchCapabilities();
}

/// Fail-closed production fallback used only when an authorization gateway
/// cannot be constructed. Prefer [LaravelAuthorizationGateway].
final class UnconfiguredAuthorizationGateway implements AuthorizationGateway {
  const UnconfiguredAuthorizationGateway();

  @override
  Future<AuthorizationDecision> authorize({
    required String permission,
    String? resourceId,
    String? organizationScope,
  }) async => const AuthorizationDecision(
    AuthorizationState.restricted,
    reason:
        'This protected feature is unavailable until the Laravel authorization service is configured.',
  );

  @override
  Future<void> bindSession({
    required String accessToken,
    required String deviceIdentifier,
  }) async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> prefetchCapabilities() async {}
}

/// Local screenshot-review adapter. Production bootstrap must replace this
/// with the Laravel/OpenAPI-backed adapter once that contract is supplied.
final class VisualReviewAuthorizationGateway implements AuthorizationGateway {
  const VisualReviewAuthorizationGateway();

  @override
  Future<AuthorizationDecision> authorize({
    required String permission,
    String? resourceId,
    String? organizationScope,
  }) async => const AuthorizationDecision.allowed();

  @override
  Future<void> bindSession({
    required String accessToken,
    required String deviceIdentifier,
  }) async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> prefetchCapabilities() async {}
}

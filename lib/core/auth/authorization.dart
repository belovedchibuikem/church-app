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

abstract interface class AuthorizationGateway {
  Future<AuthorizationDecision> authorize({
    required String permission,
    String? resourceId,
    String? organizationScope,
  });
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
}

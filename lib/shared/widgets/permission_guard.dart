import 'package:flutter/material.dart';

import '../../core/auth/authorization.dart';
import '../../core/design_system/fhc_tokens.dart';
import '../../core/l10n/locale_scope.dart';
import 'fhc_components.dart';

class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.gateway,
    required this.permission,
    required this.child,
    this.resourceId,
    this.organizationScope,
  });

  final AuthorizationGateway gateway;
  final String permission;
  final Widget child;
  final String? resourceId;
  final String? organizationScope;

  @override
  Widget build(BuildContext context) {
    // VisualReviewAuthorizationGateway always allows — no capability round-trip.
    return FutureBuilder<AuthorizationDecision>(
      future: gateway.authorize(
        permission: permission,
        resourceId: resourceId,
        organizationScope: organizationScope,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const FhcDevicePage(
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return RestrictedAccessState(
            reason: fhcT(
              context,
              'errors.accessUnverified',
              fallback:
                  'Access could not be verified with Family House authorization. Please try again.',
            ),
          );
        }
        final decision = snapshot.requireData;
        if (!decision.isAllowed) {
          return RestrictedAccessState(
            reason: decision.reason ?? _fallbackReason(context, decision.state),
            state: decision.state,
          );
        }
        return child;
      },
    );
  }

  static String _fallbackReason(
    BuildContext context,
    AuthorizationState state,
  ) {
    return switch (state) {
      AuthorizationState.unauthenticated => fhcT(
        context,
        'errors.signInToAccess',
        fallback: 'Sign in to access this area.',
      ),
      AuthorizationState.forbidden => fhcT(
        context,
        'errors.noPermissionArea',
        fallback: 'You do not have permission to open this area.',
      ),
      _ => fhcT(
        context,
        'errors.temporarilyRestricted',
        fallback: 'This area is temporarily restricted.',
      ),
    };
  }
}

class RestrictedAccessState extends StatelessWidget {
  const RestrictedAccessState({
    super.key,
    required this.reason,
    this.state = AuthorizationState.restricted,
  });

  final String reason;
  final AuthorizationState state;

  @override
  Widget build(BuildContext context) {
    final title = switch (state) {
      AuthorizationState.unauthenticated => fhcT(
        context,
        'errors.signInRequired',
        fallback: 'Sign in required',
      ),
      AuthorizationState.forbidden => fhcT(
        context,
        'errors.accessDenied',
        fallback: 'Access denied',
      ),
      _ => fhcT(
        context,
        'errors.restrictedAccess',
        fallback: 'Restricted access',
      ),
    };

    return FhcDevicePage(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Semantics(
            liveRegion: true,
            label: title,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FhcCircleIcon(
                  icon: state == AuthorizationState.unauthenticated
                      ? Icons.login
                      : Icons.lock_outline,
                  size: 58,
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: FhcColors.muted),
                ),
                if (state == AuthorizationState.unauthenticated) ...[
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/sign-in'),
                      child: Text(
                        fhcT(context, 'common.signIn', fallback: 'Sign in'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

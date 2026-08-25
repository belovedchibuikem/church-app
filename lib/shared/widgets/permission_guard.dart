import 'package:flutter/material.dart';

import '../../core/auth/authorization.dart';
import '../../core/design_system/fhc_tokens.dart';
import 'fhc_components.dart';

class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.gateway,
    required this.permission,
    required this.child,
  });

  final AuthorizationGateway gateway;
  final String permission;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthorizationDecision>(
      future: gateway.authorize(permission: permission),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const FhcDevicePage(
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const RestrictedAccessState(
            reason: 'Access could not be verified. Please try again.',
          );
        }
        if (!snapshot.requireData.isAllowed) {
          return RestrictedAccessState(
            reason:
                snapshot.requireData.reason ??
                'You do not have access to this area.',
          );
        }
        return child;
      },
    );
  }
}

class RestrictedAccessState extends StatelessWidget {
  const RestrictedAccessState({super.key, required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Semantics(
            liveRegion: true,
            label: 'Restricted access',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FhcCircleIcon(icon: Icons.lock_outline, size: 58),
                const SizedBox(height: 18),
                const Text(
                  'Restricted access',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: FhcColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

/// Phone OTP has no Laravel mobile auth operation.
///
/// Do not invent OTP success. Users return to sign-in; MFA uses `/2fa`
/// only when the mobile auth API session requires or enrolls TOTP.
class VerifyPhoneScreen extends StatelessWidget {
  const VerifyPhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => fhcGo(context, '/sign-in'),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left, size: 28),
              color: FhcColors.ink,
              tooltip: fhcT(context, 'common.back', fallback: 'Back'),
            ),
          ),
          Text(
            fhcT(
              context,
              'auth.phoneVerificationUnavailable',
              fallback: 'Phone verification unavailable',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: FhcColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              fhcT(
                context,
                'auth.phoneVerificationCopy',
                fallback:
                    'Mobile phone OTP is not exposed by the Family House Connect '
                    'API in this build. Sign in with email and password; use the '
                    'authenticator challenge when MFA evidence is required.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: FhcColors.muted,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: FhcPrimaryButton(
              label: fhcT(
                context,
                'auth.backToSignIn',
                fallback: 'Back to Sign In',
              ),
              onPressed: () => fhcGo(context, '/sign-in'),
            ),
          ),
          TextButton(
            onPressed: () => fhcGo(context, '/2fa'),
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.green,
              minimumSize: const Size(88, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              fhcT(
                context,
                'auth.openMfaChallenge',
                fallback: 'Open MFA challenge',
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

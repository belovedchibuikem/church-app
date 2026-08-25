import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class TwoFactorScreen extends StatelessWidget {
  const TwoFactorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(title: '', onBack: () => fhcGo(context, '/verify-phone')),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Enable Two-Factor\nAuthentication (Optional)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'Add an extra layer of security to\nprotect your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: FhcColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Spacer(flex: 1),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: SizedBox(
                      height: 220,
                      width: 240,
                      child: Image.asset(
                        'assets/images/security_shield.png',
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.verified_user,
                              size: 140,
                              color: FhcColors.green,
                            ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(52, 8, 52, 0),
                  child: Column(
                    children: [
                      _CheckLine('Secure your account'),
                      _CheckLine('Protect your personal data'),
                      _CheckLine('Required for important actions'),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: FhcPrimaryButton(
              label: 'Enable 2FA',
              onPressed: () => fhcGo(context, '/role-selection'),
            ),
          ),
          TextButton(
            onPressed: () => fhcGo(context, '/role-selection'),
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.green,
              minimumSize: const Size(88, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Maybe Later',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: FhcColors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: FhcColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

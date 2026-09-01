import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/biometric_unlock.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/launch/app_launch_scope.dart';
import '../../../../shared/widgets/fhc_brand_logo.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../data/auth_repository.dart';
import '../fhc_nav.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.biometricUnlock});

  final BiometricUnlock? biometricUnlock;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _unlocking = false;
  bool _hydrated = false;
  String? _error;
  BiometricUnlock? _biometric;

  AuthRepository? get _auth =>
      AppServicesScope.maybeOf(context)?.authRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = AppServicesScope.maybeOf(context)?.tokenStore;
    _biometric ??=
        widget.biometricUnlock ??
        (store == null ? null : BiometricUnlock(tokenStore: store));
    if (_hydrated) return;
    _hydrated = true;
    unawaited(_hydrate());
  }

  Future<void> _hydrate() async {
    final store = AppServicesScope.maybeOf(context)?.tokenStore;
    if (store == null) return;
    final email = await store.readRememberedEmail();
    if (email != null && email.isNotEmpty && mounted) {
      _emailController.text = email;
    }
    if (!mounted) return;
    final biometric = _biometric;
    if (biometric != null && await biometric.canOfferUnlock) {
      unawaited(_unlockWithFingerprint());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _unlocking) return;
    final auth = _auth;
    if (auth == null) {
      setState(() => _error = fhcT(context, 'errors.authNotConfigured'));
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = fhcT(context, 'errors.enterEmailPassword'));
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await auth.signIn({
      'email': email,
      'password': password,
    });

    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        setState(() => _submitting = false);
        await _enableFingerprintAfterPassword();
        if (!mounted) return;
        _continueAfterAuth(value);
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = authFailureMessage(failure);
        });
    }
  }

  Future<void> _enableFingerprintAfterPassword() async {
    final biometric = _biometric;
    if (biometric == null) return;
    if (await biometric.isHardwareAvailable) {
      await biometric.setEnabled(true);
    }
  }

  Future<void> _unlockWithFingerprint() async {
    if (_submitting || _unlocking) return;
    final auth = _auth;
    final biometric = _biometric;
    if (auth == null || biometric == null) {
      setState(() {
        _error = fhcT(
          context,
          'auth.fingerprintNeedPassword',
          fallback:
              'Sign in with email and password once on this device. After that you can open the app with your fingerprint.',
        );
      });
      return;
    }

    setState(() {
      _unlocking = true;
      _error = null;
    });

    if (!await biometric.hasStoredSession) {
      if (!mounted) return;
      setState(() {
        _unlocking = false;
        _error = fhcT(
          context,
          'auth.fingerprintNeedPassword',
          fallback:
              'Sign in with email and password once on this device. After that you can open the app with your fingerprint.',
        );
      });
      return;
    }

    final ok = await biometric.authenticate(
      reason: fhcT(
        context,
        'auth.fingerprintReason',
        fallback: 'Confirm it is you to open Family House Connect.',
      ),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _unlocking = false;
        _error = fhcT(
          context,
          'auth.fingerprintFailed',
          fallback:
              'Fingerprint was not recognized. Try again or use your password.',
        );
      });
      return;
    }

    await biometric.setEnabled(true);
    final restored = await auth.restoreSession();
    if (!mounted) return;
    switch (restored) {
      case AppSuccess(:final value):
        setState(() => _unlocking = false);
        _continueAfterAuth(value);
      case AppError(:final failure):
        setState(() {
          _unlocking = false;
          _error = authFailureMessage(failure);
        });
    }
  }

  void _continueAfterAuth(Map<String, Object?> value) {
    final mfaVerifiedAt = AuthCredentials.parseIso8601(
      value['mfa_verified_at'],
    );
    final role = AppLaunchScope.maybeOf(context)?.selectedRole;
    final next =
        (role != null && role.isNotEmpty) ? '/hub' : '/role-selection';
    if (mfaVerifiedAt == null) {
      fhcGo(context, '/2fa');
    } else {
      fhcReset(context, next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => fhcGo(context, '/language'),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left, size: 28),
              color: FhcColors.ink,
              tooltip: fhcT(context, 'common.back'),
            ),
          ),
          const FhcBrandLogo(size: 72),
          const SizedBox(height: 12),
          Text(
            fhcT(context, 'auth.welcomeBack'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: FhcColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fhcT(context, 'auth.signInCopy'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: FhcColors.muted,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 34,
                    ),
                    child: _SignInBody(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      submitting: _submitting,
                      unlocking: _unlocking,
                      error: _error,
                      onSubmit: _submit,
                      onFingerprint: _unlockWithFingerprint,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInBody extends StatelessWidget {
  const _SignInBody({
    required this.emailController,
    required this.passwordController,
    required this.submitting,
    required this.unlocking,
    required this.error,
    required this.onSubmit,
    required this.onFingerprint,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool submitting;
  final bool unlocking;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onFingerprint;

  @override
  Widget build(BuildContext context) {
    final busy = submitting || unlocking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AuthTabs(),
        const SizedBox(height: 22),
        FhcField(
          label: fhcT(context, 'auth.emailAddress'),
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          controller: emailController,
        ),
        const SizedBox(height: 16),
        FhcField(
          label: fhcT(context, 'auth.password'),
          hint: 'Enter your password',
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          controller: passwordController,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => fhcGo(context, '/forgot-password'),
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.green,
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              fhcT(context, 'auth.forgotPassword'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: const TextStyle(
              color: FhcColors.red,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 6),
        FhcPrimaryButton(
          label:
              submitting
                  ? fhcT(context, 'auth.signingIn')
                  : fhcT(context, 'auth.signIn'),
          onPressed: busy ? null : onSubmit,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: Divider(color: FhcColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                fhcT(context, 'auth.orSignInWith', fallback: 'or'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.muted,
                ),
              ),
            ),
            const Expanded(child: Divider(color: FhcColors.border)),
          ],
        ),
        const SizedBox(height: 16),
        _FingerprintSignInControl(
          unlocking: unlocking,
          enabled: !busy,
          onPressed: onFingerprint,
        ),
      ],
    );
  }
}

class _FingerprintSignInControl extends StatelessWidget {
  const _FingerprintSignInControl({
    required this.unlocking,
    required this.enabled,
    required this.onPressed,
  });

  final bool unlocking;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label =
        unlocking
            ? fhcT(context, 'auth.unlocking', fallback: 'Unlocking…')
            : fhcT(
              context,
              'auth.useFingerprint',
              fallback: 'Sign in with fingerprint',
            );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FhcColors.green.withValues(alpha: 0.08),
                  border: Border.all(color: FhcColors.green, width: 1.5),
                ),
                child:
                    unlocking
                        ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: FhcColors.green,
                          ),
                        )
                        : Icon(
                          Icons.fingerprint,
                          size: 40,
                          color: enabled ? FhcColors.green : FhcColors.muted,
                        ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: enabled ? onPressed : null,
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.green,
              disabledForegroundColor: FhcColors.muted,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: FhcColors.border)),
      ),
      child: Row(
        children: [
          Expanded(child: _TabItem(label: fhcT(context, 'auth.signIn'), active: true)),
          Expanded(
            child: _TabItem(
              label: fhcT(context, 'auth.createAccount'),
              active: false,
              onTap: () => fhcGo(context, '/sign-up'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.active, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: active,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? FhcColors.green : FhcColors.muted,
                ),
              ),
            ),
            Container(
              height: 2,
              color: active ? FhcColors.green : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

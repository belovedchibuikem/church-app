import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/launch/app_launch_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../data/auth_repository.dart';
import '../fhc_nav.dart';

/// MFA challenge / optional TOTP enrollment against mobile auth routes.
class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _codeController = TextEditingController();
  final _recoveryController = TextEditingController();

  bool _submitting = false;
  bool _enrolling = false;
  String? _error;
  String? _enrollmentMethodId;
  String? _enrollmentSecret;
  String? _provisioningUri;
  List<String> _recoveryCodes = const [];

  LaravelAuthRepository? get _laravel {
    final repo = AppServicesScope.maybeOf(context)?.authRepository;
    return repo is LaravelAuthRepository ? repo : null;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  Future<void> _submitChallenge() async {
    final laravel = _laravel;
    if (laravel == null) {
      setState(
        () => _error = fhcT(
          context,
          'errors.authNotConfigured',
          fallback: 'Auth repository is not configured.',
        ),
      );
      return;
    }
    if (_submitting) return;

    final code = _codeController.text.trim();
    final recovery = _recoveryController.text.trim();
    if (code.isEmpty && recovery.isEmpty) {
      setState(
        () => _error = fhcT(
          context,
          'auth.enterCodeOrRecovery',
          fallback: 'Enter a 6-digit code or a recovery code.',
        ),
      );
      return;
    }
    if (code.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(
        () => _error = fhcT(
          context,
          'auth.authenticatorSixDigits',
          fallback: 'Authenticator codes must be 6 digits.',
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await laravel.challengeMfa(
      code: code.isEmpty ? null : code,
      recoveryCode: recovery.isEmpty ? null : recovery,
      methodId: _enrollmentMethodId,
    );

    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        _finishAuth();
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = _failureText(failure);
        });
    }
  }

  Future<void> _startEnrollment() async {
    final laravel = _laravel;
    if (laravel == null) {
      setState(
        () => _error = fhcT(
          context,
          'errors.authNotConfigured',
          fallback: 'Auth repository is not configured.',
        ),
      );
      return;
    }
    if (_enrolling) return;

    setState(() {
      _enrolling = true;
      _error = null;
    });

    final result = await laravel.setupTotp(label: 'Family House Connect');
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _enrolling = false;
          _enrollmentMethodId = value['method_id'] as String?;
          _enrollmentSecret = value['secret'] as String?;
          _provisioningUri = value['provisioning_uri'] as String?;
          final codes = value['recovery_codes'];
          _recoveryCodes =
              codes is List
                  ? codes.map((e) => '$e').toList(growable: false)
                  : const [];
        });
      case AppError(:final failure):
        setState(() {
          _enrolling = false;
          _error = _failureText(failure);
        });
    }
  }

  Future<void> _confirmEnrollment() async {
    final laravel = _laravel;
    final methodId = _enrollmentMethodId;
    if (laravel == null || methodId == null) {
      setState(
        () => _error = fhcT(
          context,
          'auth.startMfaBeforeConfirm',
          fallback: 'Start MFA setup before confirming.',
        ),
      );
      return;
    }
    if (_submitting) return;

    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(
        () => _error = fhcT(
          context,
          'auth.enterAuthenticatorCode',
          fallback: 'Enter the 6-digit code from your authenticator.',
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await laravel.confirmTotp(methodId: methodId, code: code);
    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        _finishAuth();
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = _failureText(failure);
        });
    }
  }

  String _failureText(AppFailure failure) {
    if (failure is ValidationFailure && failure.errors.isNotEmpty) {
      return authFailureMessage(failure);
    }
    return switch (failure) {
      NetworkFailure() => fhcT(
        context,
        failure.message.toLowerCase().contains('timed out')
            ? 'errors.timeout'
            : 'errors.network',
        fallback:
            failure.message.toLowerCase().contains('timed out')
                ? 'The request timed out.'
                : 'Network request failed.',
      ),
      UnauthorizedFailure() => fhcT(
        context,
        'errors.unauthorized',
        fallback: 'Sign in again.',
      ),
      ForbiddenFailure() => fhcT(
        context,
        'errors.forbidden',
        fallback: 'You do not have access to this page.',
      ),
      NotFoundFailure() => fhcT(
        context,
        'errors.notFound',
        fallback: 'Not found',
      ),
      _ => fhcT(
        context,
        'errors.somethingWentWrong',
        fallback: 'Something went wrong',
      ),
    };
  }

  void _continueWithoutMfa() {
    // Login already issued opaque tokens; MFA is optional unless a later
    // mfa.recent gate rejects the request.
    _finishAuth();
  }

  void _finishAuth() {
    final role = AppLaunchScope.maybeOf(context)?.selectedRole;
    fhcReset(
      context,
      (role != null && role.isNotEmpty) ? '/hub' : '/role-selection',
    );
  }

  @override
  Widget build(BuildContext context) {
    final enrolling = _enrollmentMethodId != null;

    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(title: '', onBack: () => fhcGo(context, '/sign-in')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              enrolling
                  ? fhcT(
                    context,
                    'auth.confirmAuthenticator',
                    fallback: 'Confirm authenticator',
                  )
                  : fhcT(
                    context,
                    'auth.twoFactor',
                    fallback: 'Two-Factor Authentication',
                  ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              enrolling
                  ? fhcT(
                    context,
                    'auth.confirmAuthenticatorCopy',
                    fallback:
                        'Add the secret to your authenticator app, then enter the 6-digit code.',
                  )
                  : fhcT(
                    context,
                    'auth.twoFactorCopy',
                    fallback:
                        'Enter your authenticator code if MFA is required for this session, or enable TOTP.',
                  ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: FhcColors.muted,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (enrolling) ...[
                    if (_enrollmentSecret != null)
                      _InfoBlock(
                        label: fhcT(
                          context,
                          'auth.secret',
                          fallback: 'Secret',
                        ),
                        value: _enrollmentSecret!,
                      ),
                    if (_provisioningUri != null) ...[
                      const SizedBox(height: 10),
                      _InfoBlock(
                        label: fhcT(
                          context,
                          'auth.provisioningUri',
                          fallback: 'Provisioning URI',
                        ),
                        value: _provisioningUri!,
                      ),
                    ],
                    if (_recoveryCodes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _InfoBlock(
                        label: fhcT(
                          context,
                          'auth.recoveryCodesSecure',
                          fallback: 'Recovery codes (store securely)',
                        ),
                        value: _recoveryCodes.join('\n'),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  FhcField(
                    label: fhcT(
                      context,
                      'auth.authenticatorCode',
                      fallback: 'Authenticator code',
                    ),
                    hint: fhcT(
                      context,
                      'auth.sixDigitCode',
                      fallback: '6-digit code',
                    ),
                    keyboardType: TextInputType.number,
                    controller: _codeController,
                  ),
                  if (!enrolling) ...[
                    const SizedBox(height: 14),
                    FhcField(
                      label: fhcT(
                        context,
                        'auth.recoveryCodeOptional',
                        fallback: 'Recovery code (optional)',
                      ),
                      hint: fhcT(
                        context,
                        'auth.recoveryHint',
                        fallback: 'Use instead of authenticator code',
                      ),
                      controller: _recoveryController,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: FhcColors.red,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FhcPrimaryButton(
                    label:
                        _submitting
                            ? fhcT(
                              context,
                              'auth.verifying',
                              fallback: 'Verifying…',
                            )
                            : enrolling
                            ? fhcT(
                              context,
                              'auth.confirm2fa',
                              fallback: 'Confirm 2FA',
                            )
                            : fhcT(
                              context,
                              'auth.verifyCode',
                              fallback: 'Verify code',
                            ),
                    onPressed:
                        _submitting
                            ? null
                            : enrolling
                            ? _confirmEnrollment
                            : _submitChallenge,
                  ),
                  if (!enrolling) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _enrolling ? null : _startEnrollment,
                      child: Text(
                        _enrolling
                            ? fhcT(
                              context,
                              'auth.startingSetup',
                              fallback: 'Starting setup…',
                            )
                            : fhcT(
                              context,
                              'auth.enable2fa',
                              fallback: 'Enable 2FA',
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: _submitting ? null : _continueWithoutMfa,
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.green,
              minimumSize: const Size(88, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              fhcT(context, 'auth.maybeLater', fallback: 'Maybe Later'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FhcColors.canvas,
        borderRadius: BorderRadius.circular(FhcRadius.sm),
        border: Border.all(color: FhcColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FhcColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              value,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: FhcColors.ink,
                fontFamily: 'FhcRoboto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_brand_logo.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../data/auth_repository.dart';
import '../fhc_nav.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitting = false;
  bool _sent = false;
  String? _error;

  AuthRepository? get _auth =>
      AppServicesScope.maybeOf(context)?.authRepository;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _sent) return;
    final auth = _auth;
    if (auth == null) {
      setState(() => _error = fhcT(context, 'errors.authNotConfigured'));
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(
        () => _error = fhcT(
          context,
          'errors.enterEmail',
          fallback: 'Enter your email address.',
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await auth.requestPasswordReset(email);

    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        setState(() {
          _submitting = false;
          _sent = true;
        });
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = authFailureMessage(failure);
        });
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
              onPressed: () => fhcGo(context, '/sign-in'),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left, size: 28),
              color: FhcColors.ink,
              tooltip: fhcT(context, 'common.back'),
            ),
          ),
          const FhcBrandLogo(size: 72),
          const SizedBox(height: 12),
          Text(
            fhcT(
              context,
              'auth.forgotPasswordTitle',
              fallback: 'Forgot password',
            ),
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
            fhcT(
              context,
              'auth.forgotPasswordCopy',
              fallback:
                  'Enter the email on your account and we will send a reset link if it matches.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: FhcColors.muted,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_sent) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FhcColors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: FhcColors.green.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        fhcT(
                          context,
                          'auth.resetAccepted',
                          fallback:
                              'If an account exists for that email, a reset link was accepted. Check your inbox and spam folder.',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: FhcColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FhcPrimaryButton(
                      label: fhcT(
                        context,
                        'auth.openResetPassword',
                        fallback: 'Enter reset code',
                      ),
                      onPressed: () => fhcGo(
                        context,
                        '/reset-password?email=${Uri.encodeComponent(_emailController.text.trim())}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => fhcGo(context, '/sign-in'),
                      style: TextButton.styleFrom(
                        foregroundColor: FhcColors.green,
                      ),
                      child: Text(fhcT(context, 'auth.backToSignIn')),
                    ),
                  ] else ...[
                    FhcField(
                      label: fhcT(context, 'auth.emailAddress'),
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      controller: _emailController,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
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
                    const SizedBox(height: 12),
                    FhcPrimaryButton(
                      label:
                          _submitting
                              ? fhcT(
                                context,
                                'auth.sending',
                                fallback: 'Sending…',
                              )
                              : fhcT(
                                context,
                                'auth.sendResetLink',
                                fallback: 'Send reset link',
                              ),
                      onPressed: _submitting ? null : _submit,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

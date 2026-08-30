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

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.initialEmail,
    this.initialToken,
  });

  final String? initialEmail;
  final String? initialToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;
  bool _done = false;
  String? _error;

  AuthRepository? get _auth =>
      AppServicesScope.maybeOf(context)?.authRepository;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _done) return;
    final auth = _auth;
    if (auth == null) {
      setState(() => _error = fhcT(context, 'errors.authNotConfigured'));
      return;
    }

    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || token.isEmpty || password.isEmpty) {
      setState(
        () => _error = fhcT(
          context,
          'errors.enterResetFields',
          fallback: 'Enter your email, reset code, and new password.',
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      setState(
        () => _error = fhcT(
          context,
          'errors.passwordMismatch',
          fallback: 'Passwords do not match.',
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await auth.resetPassword({
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': confirmPassword,
    });

    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        setState(() {
          _submitting = false;
          _done = true;
        });
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (mounted) fhcReset(context, '/sign-in');
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
              'auth.resetYourPassword',
              fallback: 'Reset your password',
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
              'auth.resetPasswordCopy',
              fallback:
                  'Paste the code from your reset email and choose a new password.',
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
                  if (_done) ...[
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
                          'auth.passwordUpdatedSignIn',
                          fallback:
                              'Password updated. Taking you to sign in…',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: FhcColors.ink,
                        ),
                      ),
                    ),
                  ] else ...[
                    FhcField(
                      label: fhcT(context, 'auth.emailAddress'),
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    FhcField(
                      label: fhcT(
                        context,
                        'auth.resetCode',
                        fallback: 'Reset code',
                      ),
                      hint: 'Paste code from email',
                      textInputAction: TextInputAction.next,
                      controller: _tokenController,
                    ),
                    const SizedBox(height: 16),
                    FhcField(
                      label: fhcT(context, 'auth.password'),
                      hint: 'At least 12 characters',
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 16),
                    FhcField(
                      label: fhcT(
                        context,
                        'auth.confirmPassword',
                        fallback: 'Confirm password',
                      ),
                      hint: 'Re-enter your password',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      controller: _confirmPasswordController,
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
                                'auth.updatingPassword',
                                fallback: 'Updating…',
                              )
                              : fhcT(
                                context,
                                'auth.updatePassword',
                                fallback: 'Update password',
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

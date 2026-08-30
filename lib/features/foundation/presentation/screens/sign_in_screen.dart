import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/auth/auth_session.dart';
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
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  AuthRepository? get _auth =>
      AppServicesScope.maybeOf(context)?.authRepository;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
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
                      error: _error,
                      onSubmit: _submit,
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
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
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
          onPressed: submitting ? null : onSubmit,
        ),
      ],
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


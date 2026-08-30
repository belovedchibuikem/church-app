import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/geography/geography_catalog.dart';
import '../../../../core/launch/app_launch_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_brand_logo.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../../shared/widgets/geography_select.dart';
import '../../data/auth_repository.dart';
import '../fhc_nav.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _givenNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _countryController = TextEditingController(
    text: GeographyCatalog.defaultCountryCode,
  );
  final _countryLabelController = TextEditingController();
  final _regionController = TextEditingController();
  final _localityController = TextEditingController();
  bool _submitting = false;
  String? _error;

  AuthRepository? get _auth =>
      AppServicesScope.maybeOf(context)?.authRepository;

  @override
  void dispose() {
    _givenNameController.dispose();
    _familyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countryController.dispose();
    _countryLabelController.dispose();
    _regionController.dispose();
    _localityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final auth = _auth;
    if (auth == null) {
      setState(() => _error = fhcT(context, 'errors.authNotConfigured'));
      return;
    }

    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;

    final givenName = _givenNameController.text.trim();
    final familyName = _familyNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final country = _countryController.text.trim().toUpperCase();
    final region = _regionController.text.trim();
    final locality = _localityController.text.trim();

    if (givenName.isEmpty ||
        familyName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      setState(
        () => _error = fhcT(
          context,
          'errors.enterRegistrationFields',
          fallback: 'Enter your name, email, and password.',
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

    if (country.isEmpty || region.isEmpty || locality.isEmpty) {
      setState(
        () => _error = fhcT(
          context,
          'errors.enterLocationFields',
          fallback: 'Select your country, state/region, and LGA/city.',
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await auth.register({
      'given_name': givenName,
      'family_name': familyName,
      'email': email,
      'password': password,
      'password_confirmation': confirmPassword,
      'country': country,
      'region': region,
      'locality': locality,
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
            fhcT(
              context,
              'auth.createAccountTitle',
              fallback: 'Create your account',
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
              'auth.createAccountCopy',
              fallback:
                  'Join Family House Connect with your email. You can link your church after signing in.',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthTabs(activeRegister: true),
                    const SizedBox(height: 22),
                    FhcField(
                      label: fhcT(
                        context,
                        'auth.givenName',
                        fallback: 'First name',
                      ),
                      hint: 'Grace',
                      textInputAction: TextInputAction.next,
                      controller: _givenNameController,
                    ),
                    const SizedBox(height: 16),
                    FhcField(
                      label: fhcT(
                        context,
                        'auth.familyName',
                        fallback: 'Last name',
                      ),
                      hint: 'Ezekiel',
                      textInputAction: TextInputAction.next,
                      controller: _familyNameController,
                    ),
                    const SizedBox(height: 16),
                    FhcField(
                      label: fhcT(context, 'auth.emailAddress'),
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    GeographySelect(
                      countryController: _countryController,
                      countryLabelController: _countryLabelController,
                      regionController: _regionController,
                      localityController: _localityController,
                      required: true,
                    ),
                    const SizedBox(height: 4),
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
                                'auth.creatingAccount',
                                fallback: 'Creating account…',
                              )
                              : fhcT(context, 'auth.createAccount'),
                      onPressed: _submitting ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.activeRegister});

  final bool activeRegister;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: FhcColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              label: fhcT(context, 'auth.signIn'),
              active: !activeRegister,
              onTap: activeRegister ? () => fhcGo(context, '/sign-in') : null,
            ),
          ),
          Expanded(
            child: _TabItem(
              label: fhcT(context, 'auth.createAccount'),
              active: activeRegister,
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

import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/home_church_repository.dart';

class StartHomeChurchStep4Screen extends StatefulWidget {
  const StartHomeChurchStep4Screen({
    super.key,
    this.repository,
  });

  final HomeChurchRepositoryImpl? repository;

  @override
  State<StartHomeChurchStep4Screen> createState() =>
      _StartHomeChurchStep4ScreenState();
}

class _StartHomeChurchStep4ScreenState
    extends State<StartHomeChurchStep4Screen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  final List<bool> _commitments = [true, true, true];
  bool _submitting = false;
  String? _formError;
  Map<String, List<String>> _fieldErrors = const {};
  bool _repoMissing = false;

  static const _commitmentKeys = <(String, String)>[
    (
      'homeChurch.commitmentGuidelines',
      'I will follow the guidelines and doctrine of Family House.',
    ),
    (
      'homeChurch.commitmentPray',
      'I will pray and disciple others.',
    ),
    (
      'homeChurch.commitmentReports',
      'I will submit regular reports and remain accountable.',
    ),
  ];

  HomeChurchRepositoryImpl? get _repository {
    final injected = widget.repository;
    if (injected != null) return injected;
    final fromServices =
        AppServicesScope.maybeOf(context)?.homeChurchRepository;
    return fromServices is HomeChurchRepositoryImpl ? fromServices : null;
  }

  @override
  void initState() {
    super.initState();
    final draft = HomeChurchApplicationSession.draft;
    final existingName = [
      draft.givenName,
      draft.familyName,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
    _nameController = TextEditingController(
      text: existingName.isEmpty ? '' : existingName,
    );
    _phoneController = TextEditingController(text: draft.contactPhone ?? '');
    _emailController = TextEditingController(text: draft.contactEmail ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final missing = _repository == null;
    if (missing != _repoMissing) {
      setState(() => _repoMissing = missing);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _popBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      fhcGo(context, FhcRoutes.homeChurchStart3);
    }
  }

  (String given, String family) _splitName(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, parts.first);
    return (parts.first, parts.sublist(1).join(' '));
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final repo = _repository;
    if (repo == null) {
      setState(() {
        _repoMissing = true;
        _formError = fhcT(
          context,
          'homeChurch.submitWaitingOnRepo',
          fallback:
              'Home church submit is waiting on AppServices homeChurchRepository.',
        );
      });
      return;
    }

    final guidelinesAgreed = _commitments.every((v) => v);
    final (given, family) = _splitName(_nameController.text);
    final draft = HomeChurchApplicationSession.draft;
    draft.givenName = given;
    draft.familyName = family;
    if (given.isNotEmpty) {
      draft.preferredName = given;
    }
    draft.contactEmail = _emailController.text.trim();
    draft.contactPhone = _phoneController.text.trim();
    draft.guidelinesAgreed = guidelinesAgreed;

    setState(() {
      _submitting = true;
      _formError = null;
      _fieldErrors = const {};
    });

    final result = await repo.submitPublicApplication(draft);
    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        setState(() => _submitting = false);
        fhcPush(context, FhcRoutes.homeChurchProgress);
      case AppError(:final failure):
        if (failure is IntegrationUnavailableFailure) {
          setState(() {
            _submitting = false;
            _formError = failure.message;
          });
          return;
        }
        final fields = failure is ValidationFailure
            ? Map<String, List<String>>.from(failure.errors)
            : <String, List<String>>{};
        setState(() {
          _submitting = false;
          _formError = failure.message;
          _fieldErrors = fields;
        });
    }
  }

  String? _fieldMessage(String key) {
    final messages = _fieldErrors[key];
    if (messages == null || messages.isEmpty) return null;
    return messages.first;
  }

  @override
  Widget build(BuildContext context) {
    if (_repoMissing) {
      return FhcFeatureUnavailablePage(
        feature: fhcT(
          context,
          'homeChurch.applicationFeature',
          fallback: 'Home church application',
        ),
        detail: fhcT(
          context,
          'homeChurch.submitUnavailableDetail',
          fallback:
              'Submit uses POST /api/v1/home-church-applications via '
              'AppServices.homeChurchRepository. That repository is not wired '
              'in this build, so no fixture success path is shown.',
        ),
        onBack: _popBack,
      );
    }

    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'homeChurch.startTitleInline',
              fallback: 'Start a Church in Your Home',
            ),
            onBack: _popBack,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _StepBanner(step: 4),
                        const SizedBox(height: 10),
                        const _StepProgress(step: 4),
                        const SizedBox(height: 22),
                        Text(
                          fhcT(
                            context,
                            'homeChurch.contactInformation',
                            fallback: 'Contact Information',
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: FhcColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FhcField(
                          label: fhcT(
                            context,
                            'homeChurch.fullName',
                            fallback: 'Full Name',
                          ),
                          hint: fhcT(
                            context,
                            'homeChurch.fullNameHint',
                            fallback: 'Your full name',
                          ),
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                        ),
                        if (_fieldMessage('applicant.given_name') != null ||
                            _fieldMessage('applicant.family_name') != null)
                          _InlineError(
                            _fieldMessage('applicant.given_name') ??
                                _fieldMessage('applicant.family_name')!,
                          ),
                        const SizedBox(height: 14),
                        FhcField(
                          label: fhcT(
                            context,
                            'homeChurch.phone',
                            fallback: 'Phone',
                          ),
                          hint: fhcT(
                            context,
                            'homeChurch.phoneHint',
                            fallback: '+234 000 000 0000',
                          ),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        if (_fieldMessage('contact_phone') != null)
                          _InlineError(_fieldMessage('contact_phone')!),
                        const SizedBox(height: 14),
                        FhcField(
                          label: fhcT(
                            context,
                            'homeChurch.email',
                            fallback: 'Email',
                          ),
                          hint: fhcT(
                            context,
                            'homeChurch.emailHint',
                            fallback: 'you@example.com',
                          ),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        if (_fieldMessage('contact_email') != null)
                          _InlineError(_fieldMessage('contact_email')!),
                        const SizedBox(height: 22),
                        Text(
                          fhcT(
                            context,
                            'homeChurch.ministryCommitment',
                            fallback: 'Ministry Commitment',
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: FhcColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < _commitmentKeys.length; i++)
                          _CommitmentTile(
                            label: fhcT(
                              context,
                              _commitmentKeys[i].$1,
                              fallback: _commitmentKeys[i].$2,
                            ),
                            checked: _commitments[i],
                            onTap:
                                () => setState(
                                  () => _commitments[i] = !_commitments[i],
                                ),
                          ),
                        if (_fieldMessage('guidelines_agreed') != null)
                          _InlineError(_fieldMessage('guidelines_agreed')!),
                        if (_formError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _formError!,
                            style: const TextStyle(
                              color: FhcColors.red,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                SizedBox(
                  height: FhcSizes.buttonHeight,
                  child: OutlinedButton(
                    onPressed: _submitting ? null : _popBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FhcColors.ink,
                      side: const BorderSide(color: FhcColors.border),
                      minimumSize: const Size(88, FhcSizes.buttonHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FhcRadius.button),
                      ),
                    ),
                    child: Text(
                      fhcT(context, 'common.back', fallback: 'Back'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FhcPrimaryButton(
                    label: _submitting
                        ? fhcT(
                            context,
                            'homeChurch.submitting',
                            fallback: 'Submitting…',
                          )
                        : fhcT(
                            context,
                            'homeChurch.submitApplication',
                            fallback: 'Submit Application',
                          ),
                    onPressed: _submitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              fhcT(
                context,
                'homeChurch.submitIdempotencyNote',
                fallback:
                    'Your application will be reviewed. Submits use an Idempotency-Key.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: FhcColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: const TextStyle(color: FhcColors.red, fontSize: 11, height: 1.3),
      ),
    );
  }
}

class _StepBanner extends StatelessWidget {
  const _StepBanner({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: FhcColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            fhcT(
              context,
              'homeChurch.stepOf',
              args: {'current': '$step', 'total': '4'},
              fallback: 'Step {current} of {total}',
            ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: FhcColors.muted,
            ),
          ),
        ),
        const Expanded(child: Divider(color: FhcColors.border, height: 1)),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
              decoration: BoxDecoration(
                color: i < step ? FhcColors.green : FhcColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _CommitmentTile extends StatelessWidget {
  const _CommitmentTile({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  checked ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 22,
                  color: checked ? FhcColors.green : FhcColors.hint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: FhcColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

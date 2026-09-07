import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

/// Submit a testimony via `POST /user/testimonies` (`title`, `body`).
class TestimonyNewScreen extends StatefulWidget {
  const TestimonyNewScreen({super.key, this.testimonyRepository});

  final TestimonyRepository? testimonyRepository;

  @override
  State<TestimonyNewScreen> createState() => _TestimonyNewScreenState();
}

class _TestimonyNewScreenState extends State<TestimonyNewScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;
  String? _error;

  TestimonyRepository? get _repo =>
      widget.testimonyRepository ??
      AppServicesScope.maybeOf(context)?.testimonyRepository;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(
        () => _error = fhcT(
          context,
          'member.testimony.requiredFields',
          fallback: 'Title and testimony are required.',
        ),
      );
      return;
    }

    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error = fhcT(
          context,
          'member.testimony.submitUnavailable',
          fallback:
              'Testimony submission is waiting on the testimony service.',
        );
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await repo.create({'title': title, 'body': body});
    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        setState(() => _submitting = false);
        fhcGo(context, FhcRoutes.prayer);
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }

  void _onBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      fhcGo(context, FhcRoutes.prayer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'member.testimony.share',
              fallback: 'Share Testimony',
            ),
            onBack: _onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Text(
                  fhcT(
                    context,
                    'member.testimony.intro',
                    fallback:
                        'Share how God answered prayer so others can be encouraged.',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: FhcColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fhcT(context, 'homeChurch.title', fallback: 'Title'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: FhcTypography.body,
                  decoration: _fieldDecoration(
                    fhcT(
                      context,
                      'member.testimony.titleHint',
                      fallback: 'What did the Lord do?',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  fhcT(
                    context,
                    'homeChurch.yourTestimony',
                    fallback: 'Your Testimony',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bodyController,
                  minLines: 6,
                  maxLines: 10,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: FhcTypography.body,
                  decoration: _fieldDecoration(
                    fhcT(
                      context,
                      'member.testimony.bodyHint',
                      fallback:
                          'Tell the story of how God met you. You can mention a prayer request that was answered.',
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  FhcErrorState(
                    title: fhcT(
                      context,
                      'errors.unableToSubmit',
                      fallback: 'Unable to submit',
                    ),
                    message: _error!,
                    onRetry: _submitting ? null : _submit,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FhcPrimaryButton(
              label: _submitting
                  ? fhcT(
                      context,
                      'common.submitting',
                      fallback: 'Submitting…',
                    )
                  : fhcT(
                      context,
                      'homeChurch.submitTestimony',
                      fallback: 'Submit Testimony',
                    ),
              onPressed: _submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return InputDecoration(
      hintText: hint,
      hintStyle: FhcTypography.hint,
      filled: true,
      fillColor: FhcColors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: FhcColors.border),
        borderRadius: radius,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: FhcColors.border),
        borderRadius: radius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: FhcColors.green, width: 1.5),
        borderRadius: radius,
      ),
    );
  }
}

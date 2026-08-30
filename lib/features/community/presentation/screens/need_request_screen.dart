import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

/// Create pastoral need via `POST /user/needs` (`category`, `summary`).
class NeedRequestScreen extends StatefulWidget {
  const NeedRequestScreen({super.key, this.needRepository});

  final NeedRepository? needRepository;

  @override
  State<NeedRequestScreen> createState() => _NeedRequestScreenState();
}

class _NeedRequestScreenState extends State<NeedRequestScreen> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  String _category = 'Financial Assistance';
  bool _submitting = false;
  String? _error;

  static const _categories = <(String, String)>[
    ('Financial Assistance', 'member.needs.categoryFinancial'),
    ('Medical Support', 'member.needs.categoryMedical'),
    ('Housing', 'member.needs.categoryHousing'),
    ('Food', 'member.needs.categoryFood'),
    ('Counseling', 'member.needs.categoryCounseling'),
    ('Other', 'member.needs.categoryOther'),
  ];

  NeedRepository? get _repo =>
      widget.needRepository ??
      AppServicesScope.maybeOf(context)?.needRepository;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final summary = _summaryController.text.trim();
    if (title.isEmpty || summary.isEmpty) {
      setState(
        () => _error = fhcT(
          context,
          'member.needs.requiredFields',
          fallback: 'Category, title, and description are required.',
        ),
      );
      return;
    }

    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error = fhcT(
          context,
          'member.needs.submitUnavailable',
          fallback:
              'Need submission is waiting on the Laravel needs API. '
              'No fixture submit path is used.',
        );
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final body = summary.length > 80
        ? '$title\n\n$summary'
        : (title == summary ? summary : '$title — $summary');

    final result = await repo.create({
      'category': _category,
      'summary': body,
    });

    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        setState(() => _submitting = false);
        fhcGo(context, FhcRoutes.needStatus);
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repoMissing = _repo == null;

    return WorkflowPage(
      title: fhcT(context, 'member.needs.request', fallback: 'Need Request'),
      domain: WorkflowDomain.church,
      actionLabel: _submitting
          ? fhcT(context, 'common.submitting', fallback: 'Submitting…')
          : fhcT(context, 'member.needs.submit', fallback: 'Submit Need'),
      onAction: _submitting ? () {} : _submit,
      children: [
        WorkflowCard(
          color: const Color(0xFFEAF4EF),
          child: Text(
            fhcT(
              context,
              'member.needs.helpBanner',
              fallback: 'Need Help?\nShare your need with your church family.',
            ),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 14),
        if (repoMissing)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FhcUnavailableState(
              title: fhcT(
                context,
                'member.needs.unavailableTitle',
                fallback: 'Needs unavailable',
              ),
              message: fhcT(
                context,
                'member.needs.formUnavailable',
                fallback:
                    'Pastoral needs are waiting on the Laravel needs API. '
                    'No fixture form is shown in production.',
              ),
            ),
          )
        else ...[
          Text(
            fhcT(context, 'member.needs.categoryRequired', fallback: 'Category *'),
            style: FhcTypography.label,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in _categories)
                ChoiceChip(
                  label: Text(
                    fhcT(context, category.$2, fallback: category.$1),
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: _category == category.$1,
                  onSelected: (_) => setState(() => _category = category.$1),
                  selectedColor: FhcColors.mint,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fhcT(context, 'member.needs.titleRequired', fallback: 'Need Title *'),
            style: FhcTypography.label,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            style: FhcTypography.body,
            decoration: _fieldDecoration(
              fhcT(
                context,
                'member.needs.titleHint',
                fallback: 'School Fees Support',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            fhcT(
              context,
              'member.needs.descriptionRequired',
              fallback: 'Description *',
            ),
            style: FhcTypography.label,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _summaryController,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            style: FhcTypography.body,
            decoration: _fieldDecoration(
              fhcT(
                context,
                'member.needs.descriptionHint',
                fallback: 'Describe the need your church family can help with.',
              ),
            ),
          ),
        ],
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

import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

const _kParchment = Color(0xFFF7F3EA);

class BiblePlansScreen extends StatefulWidget {
  const BiblePlansScreen({super.key, this.repository});

  final BibleRepository? repository;

  @override
  State<BiblePlansScreen> createState() => _BiblePlansScreenState();
}

class _BiblePlansScreenState extends State<BiblePlansScreen> {
  List<JsonObject> _plans = const [];
  String? _error;
  String? _busy;
  int _customDays = 90;

  BibleRepository? get _repository =>
      widget.repository ?? AppServicesScope.maybeOf(context)?.bibleRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_plans.isEmpty && _error == null) _load();
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) {
      setState(() {
        _error = fhcT(
          context,
          'bible.unavailable',
          fallback: 'The Bible API is not configured in this build.',
        );
      });
      return;
    }
    final result = await repository.plans();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case AppSuccess(:final value):
          _plans = [
            for (final plan in value)
              if ('${plan['code']}' != 'year_3') plan,
          ];
        case AppError(:final failure):
          _error = failure.message;
      }
    });
  }

  Future<void> _start(String code, {int? durationDays}) async {
    final repository = _repository;
    if (repository == null) return;
    setState(() => _busy = code);
    final result = await repository.enroll(
      code,
      durationDays: durationDays,
    );
    if (!mounted) return;
    switch (result) {
      case AppSuccess():
        fhcGo(context, FhcRoutes.bible);
      case AppError(:final failure):
        setState(() {
          _busy = null;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: _kParchment,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'bible.plans', fallback: 'Reading plans'),
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  fhcT(
                    context,
                    'bible.planLead',
                    fallback:
                        'Finish the whole Bible at a pace that fits your life.',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!),
                ],
                const SizedBox(height: 16),
                for (final plan in _plans) ...[
                  FhcSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plan['name']}',
                          style: FhcTypography.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text('${plan['description']}'),
                        const SizedBox(height: 4),
                        Text(
                          fhcT(
                            context,
                            'bible.planDays',
                            args: {'days': '${plan['days']}'},
                            fallback: '{days} days',
                          ),
                          style: FhcTypography.caption,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _busy == plan['code']
                              ? null
                              : () => _start('${plan['code']}'),
                          child: Text(
                            fhcT(
                              context,
                              'bible.startPlan',
                              fallback: 'Start this plan',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FhcSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fhcT(
                          context,
                          'bible.customPlan',
                          fallback: 'Create your own pace',
                        ),
                        style: FhcTypography.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fhcT(
                          context,
                          'bible.customPlanCopy',
                          fallback:
                              'Choose how many days you want to finish the Bible. 30–1,095 days.',
                        ),
                      ),
                      Slider(
                        min: 30,
                        max: 1095,
                        divisions: 213,
                        value: _customDays.toDouble(),
                        label: '$_customDays days',
                        onChanged: (value) =>
                            setState(() => _customDays = value.round()),
                      ),
                      Text(
                        fhcT(
                          context,
                          'bible.planDays',
                          args: {'days': '$_customDays'},
                          fallback: '{days} days',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _busy == 'custom'
                            ? null
                            : () => _start('', durationDays: _customDays),
                        child: Text(
                          fhcT(
                            context,
                            'bible.startCustomPlan',
                            fallback: 'Start custom plan',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

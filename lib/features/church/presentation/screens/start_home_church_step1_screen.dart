import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/church_repository.dart';
import '../../data/home_church_repository.dart';

class StartHomeChurchStep1Screen extends StatefulWidget {
  const StartHomeChurchStep1Screen({
    super.key,
    this.churchRepository,
  });

  final ChurchRepositoryImpl? churchRepository;

  @override
  State<StartHomeChurchStep1Screen> createState() =>
      _StartHomeChurchStep1ScreenState();
}

class _StartHomeChurchStep1ScreenState
    extends State<StartHomeChurchStep1Screen> {
  FhcAsyncValue<List<ChurchSummary>> _state = const FhcAsyncValue.loading();
  ChurchSummary? _selected;
  late final TextEditingController _proposedNameController;
  bool _started = false;

  ChurchRepositoryImpl? get _churchRepository {
    final injected = widget.churchRepository;
    if (injected != null) return injected;
    final fromServices = AppServicesScope.maybeOf(context)?.churchRepository;
    return fromServices is ChurchRepositoryImpl ? fromServices : null;
  }

  @override
  void initState() {
    super.initState();
    final draft = HomeChurchApplicationSession.draft;
    _proposedNameController = TextEditingController(
      text: draft.proposedName ?? '',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _loadChurches();
    }
  }

  @override
  void dispose() {
    _proposedNameController.dispose();
    super.dispose();
  }

  Future<void> _loadChurches() async {
    final repo = _churchRepository;
    if (repo == null) {
      setState(() {
        _selected = null;
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'homeChurch.repoMissingChurches',
            fallback:
                'Home church applications need AppServices churchRepository '
                'to load parent churches. No fixture list is shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());

    final result = await repo.listChurches(perPage: 50);
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.items.isEmpty) {
          setState(() {
            _selected = null;
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'homeChurch.noPublishedChurches',
                fallback:
                    'No published churches are available for applications yet.',
              ),
            );
          });
          return;
        }
        final draftId = HomeChurchApplicationSession.draft.churchId;
        ChurchSummary? selected;
        if (draftId != null) {
          for (final church in value.items) {
            if (church.id == draftId) {
              selected = church;
              break;
            }
          }
        }
        setState(() {
          _selected = selected ?? value.items.first;
          _state = FhcAsyncValue.data(value.items);
        });
      case AppError(:final failure):
        if (failure is IntegrationUnavailableFailure) {
          setState(() {
            _selected = null;
            _state = FhcAsyncValue.unavailable(message: failure.message);
          });
          return;
        }
        setState(() {
          _selected = null;
          _state = FhcAsyncValue.error(failure);
        });
    }
  }

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  void _continue() {
    final church = _selected;
    if (church == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'homeChurch.selectParentChurch',
              fallback: 'Select a parent church to continue.',
            ),
          ),
        ),
      );
      return;
    }

    final unitId = church.location.administrativeUnitId;
    if (church.location.id.isEmpty || unitId == null || unitId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'homeChurch.missingLocationScope',
              fallback:
                  'This church is missing location scope required for applications.',
            ),
          ),
        ),
      );
      return;
    }

    final proposed = _proposedNameController.text.trim();
    if (proposed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'homeChurch.enterProposedName',
              fallback: 'Enter a proposed home church name.',
            ),
          ),
        ),
      );
      return;
    }

    final draft = HomeChurchApplicationSession.draft;
    draft.churchId = church.id;
    draft.locationId = church.location.id;
    draft.administrativeUnitId = unitId;
    draft.churchName = church.name;
    draft.locationLabel = church.location.placeLabel;
    draft.proposedName = proposed;

    fhcPush(context, FhcRoutes.homeChurchStart2);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(title: '', onBack: _onBack),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final compact = h < 520;
                final photoH = (h * 0.28).clamp(96.0, compact ? 120.0 : 148.0);

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        fhcT(
                          context,
                          'homeChurch.startTitle',
                          fallback: 'Start a Church\nin Your Home',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.18,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _StepBanner(step: 1),
                      const SizedBox(height: 10),
                      const _StepProgress(step: 1),
                      SizedBox(height: compact ? 12 : 16),
                      SizedBox(
                        height: photoH,
                        width: double.infinity,
                        child: const _LivingRoomPhoto(),
                      ),
                      SizedBox(height: compact ? 12 : 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          fhcT(
                            context,
                            'homeChurch.chooseParentChurch',
                            fallback:
                                'Choose the parent church that will shepherd your '
                                'home church application.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: FhcColors.ink,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      FhcAsyncBody<List<ChurchSummary>>(
                        value: _state,
                        onRetry: _loadChurches,
                        emptyTitle: fhcT(
                          context,
                          'homeChurch.noChurchesAvailable',
                          fallback: 'No churches available',
                        ),
                        unavailableTitle: fhcT(
                          context,
                          'homeChurch.churchesUnavailable',
                          fallback: 'Churches unavailable',
                        ),
                        builder: (context, churches) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ChurchDropdown(
                                churches: churches,
                                value: _selected,
                                onChanged: (church) =>
                                    setState(() => _selected = church),
                              ),
                              const SizedBox(height: 12),
                              FhcField(
                                label: fhcT(
                                  context,
                                  'homeChurch.proposedName',
                                  fallback: 'Proposed home church name',
                                ),
                                hint: fhcT(
                                  context,
                                  'homeChurch.proposedNameHint',
                                  fallback: 'e.g. Grace Street Home Church',
                                ),
                                controller: _proposedNameController,
                              ),
                              if (_selected != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _selected!.location.placeLabel,
                                  style: FhcTypography.caption,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: FhcPrimaryButton(
              label: fhcT(context, 'common.continue', fallback: 'Continue'),
              onPressed: _state is FhcAsyncData<List<ChurchSummary>>
                  ? _continue
                  : null,
            ),
          ),
          TextButton(
            onPressed: () => fhcGo(context, FhcRoutes.hub),
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.ink,
              minimumSize: const Size(88, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              fhcT(context, 'common.cancel', fallback: 'Cancel'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ChurchDropdown extends StatelessWidget {
  const _ChurchDropdown({
    required this.churches,
    required this.value,
    required this.onChanged,
  });

  final List<ChurchSummary> churches;
  final ChurchSummary? value;
  final ValueChanged<ChurchSummary> onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fhcT(context, 'homeChurch.parentChurch', fallback: 'Parent church'),
          style: FhcTypography.label,
        ),
        const SizedBox(height: 7),
        DecoratedBox(
          decoration: BoxDecoration(
            color: FhcColors.white,
            borderRadius: radius,
            border: Border.all(color: FhcColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ChurchSummary>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 22,
                color: FhcColors.muted,
              ),
              borderRadius: radius,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FhcColors.ink,
              ),
              items: [
                for (final church in churches)
                  DropdownMenuItem<ChurchSummary>(
                    value: church,
                    child: Text(
                      church.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
            ),
          ),
        ),
      ],
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

class _LivingRoomPhoto extends StatelessWidget {
  const _LivingRoomPhoto();

  static const _primary = 'assets/images/home_church_living.png';
  static const _fallback = 'assets/images/multiply_home.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FhcRadius.lg),
      child: Image.asset(
        _primary,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.12),
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            _fallback,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.12),
            errorBuilder:
                (context, error, stackTrace) =>
                    const ColoredBox(color: Color(0xFF4A3428)),
          );
        },
      ),
    );
  }
}

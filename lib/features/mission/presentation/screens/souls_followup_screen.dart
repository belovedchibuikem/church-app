import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/mission_repository.dart';
import 'mission_workflow_screens.dart';

/// Soul follow-up list bound to GET /admin/mission/souls when transport is live.
class SoulsFollowupScreen extends StatefulWidget {
  const SoulsFollowupScreen({super.key, this.repository});

  final MissionRepository? repository;

  @override
  State<SoulsFollowupScreen> createState() => _SoulsFollowupScreenState();
}

class _SoulsFollowupScreenState extends State<SoulsFollowupScreen> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<JsonObject> _souls = const [];
  JsonObject? _selected;

  MissionRepository? get _missionRepo =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.missionRepository;

  HttpMissionRepository? get _httpRepo {
    final injected = widget.repository;
    if (injected is HttpMissionRepository) return injected;
    final fromScope = AppServicesScope.maybeOf(context)?.missionRepository;
    if (fromScope is HttpMissionRepository) return fromScope;
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = _httpRepo;
    if (repo == null || !repo.adminOpsBound) {
      setState(() {
        _loading = false;
        _souls = const [];
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await repo.listSouls(const {'per_page': '50'});
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _souls = value;
          _loading = false;
        });
      case AppError(:final failure):
        setState(() {
          _souls = const [];
          _error = failure.message;
          _loading = false;
        });
    }
  }

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.crusade);
    }
  }

  void _openAddSoul() => fhcPush(context, FhcRoutes.soulAdd);

  void _openSoul(String id) {
    fhcPush(context, '/mission/soul/$id');
  }

  void _selectSoul(JsonObject soul) {
    setState(() => _selected = soul);
    final id = (soul['id'] as String?)?.trim() ?? '';
    if (_tab == 0 && id.isNotEmpty) {
      _openSoul(id);
    }
  }

  List<JsonObject> get _filtered {
    if (_tab == 0) {
      return [
        for (final soul in _souls)
          if ((soul['status'] as String?) == 'new' ||
              soul['follow_up_completed_at'] == null)
            soul,
      ];
    }
    return [
      for (final soul in _souls)
        if (soul['last_follow_up_at'] != null ||
            soul['mentor_assignment_id'] != null)
          soul,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final repo = _httpRepo;
    final bound = repo?.adminOpsBound == true;
    final tabs = [
      fhcT(context, 'mission.newSouls', fallback: 'New Souls'),
      fhcT(context, 'mission.followUp', fallback: 'Follow-up'),
    ];

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'mission.soulFollowUp',
              fallback: 'Soul Follow-up',
            ),
            onBack: _onBack,
          ),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _SoulsTab(
                      label: tabs[i],
                      active: _tab == i,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _body(bound: bound)),
          if (_tab == 1 &&
              _selected != null &&
              looksLikeMissionUlid('${_selected!['id'] ?? ''}'))
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SoulFollowUpForm(
                  key: ValueKey(_selected!['id']),
                  soulId: '${_selected!['id']}',
                  mentorAssignmentId:
                      (_selected!['mentor_assignment_id'] as String?)?.trim(),
                  repository: _missionRepo,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: FhcPrimaryButton(
              label: fhcT(
                context,
                'mission.addNewSoul',
                fallback: 'Add New Soul',
              ),
              onPressed: _openAddSoul,
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }

  Widget _body({required bool bound}) {
    if (!bound) {
      return FhcEmptyState(
        icon: Icons.lock_outline,
        title: fhcT(
          context,
          'mission.soulListNeedsAdmin',
          fallback: 'Soul list needs admin transport',
        ),
        message: fhcT(
          context,
          'mission.soulListNeedsAdminCopy',
          fallback:
              'GET /admin/mission/souls requires bearer token, device binding, '
              'X-Scope-Type/X-Scope-ID, and recent MFA. Capture still needs a '
              'crusade ULID via Add Soul.',
        ),
        actionLabel: fhcT(
          context,
          'mission.addNewSoul',
          fallback: 'Add New Soul',
        ),
        onAction: _openAddSoul,
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null) {
      return FhcErrorState(
        title: fhcT(
          context,
          'mission.unableToLoadSouls',
          fallback: 'Unable to load souls',
        ),
        message: _error!,
        onRetry: _load,
      );
    }
    final rows = _filtered;
    if (rows.isEmpty) {
      return FhcEmptyState(
        icon: Icons.favorite_outline,
        title: _tab == 0
            ? fhcT(context, 'mission.noNewSouls', fallback: 'No new souls yet')
            : fhcT(
                context,
                'mission.noFollowUpRows',
                fallback: 'No follow-up rows yet',
              ),
        message: fhcT(
          context,
          'mission.soulsAppearAfterRefresh',
          fallback:
              'Captured soul journeys from POST /admin/mission/crusades/{id}/souls '
              'appear here after list refresh.',
        ),
        actionLabel: fhcT(
          context,
          'mission.addNewSoul',
          fallback: 'Add New Soul',
        ),
        onAction: _openAddSoul,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final soul = rows[index];
        final id = (soul['id'] as String?)?.trim() ?? '';
        final status = (soul['status'] as String?)?.trim() ?? 'unknown';
        final crusadeId = (soul['crusade_id'] as String?)?.trim() ?? '—';
        return FhcSurfaceCard(
          child: InkWell(
            onTap: id.isEmpty ? null : () => _selectSoul(soul),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: FhcColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          id.isEmpty
                              ? fhcT(
                                  context,
                                  'mission.soulJourney',
                                  fallback: 'Soul journey',
                                )
                              : id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          fhcT(
                            context,
                            'mission.soulStatusLine',
                            fallback: 'Status: {status} · Crusade: {crusadeId}',
                            args: {'status': status, 'crusadeId': crusadeId},
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: FhcColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: FhcColors.muted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SoulsTab extends StatelessWidget {
  const _SoulsTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? FhcColors.green : FhcColors.border,
                width: active ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: active ? FhcColors.green : FhcColors.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

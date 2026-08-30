import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class KcaModulesScreen extends StatefulWidget {
  const KcaModulesScreen({super.key, this.kcaRepository});

  final KcaRepository? kcaRepository;

  @override
  State<KcaModulesScreen> createState() => _KcaModulesScreenState();
}

class _KcaModulesScreenState extends State<KcaModulesScreen> {
  int _tab = 0;
  FhcAsyncValue<List<_ModuleSpec>> _state = const FhcAsyncValue.loading();

  KcaRepository? get _repo =>
      widget.kcaRepository ??
      AppServicesScope.maybeOf(context)?.kcaRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) {
      _load();
    }
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.kca.modulesRequireApi',
            fallback:
                'KCA modules require the member curriculum API. '
                'No design fixtures are shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.listModules();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'member.kca.noActiveModules',
                fallback: 'No active KCA modules are published yet.',
              ),
            );
          });
          return;
        }
        setState(() {
          _state = FhcAsyncValue.data([
            for (var i = 0; i < value.length; i++)
              _ModuleSpec.fromJson(value[i], fallbackNumber: i + 1),
          ]);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.kca);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      fhcT(context, 'member.kca.allModules', fallback: 'All Modules'),
      fhcT(context, 'member.kca.myProgress', fallback: 'My Progress'),
    ];

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'member.kca.modulesTitle', fallback: 'KCA Modules'),
            onBack: _back,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                fhcT(
                  context,
                  'member.kca.modulesSubtitle',
                  fallback: 'Published curriculum from Laravel',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: FhcColors.muted,
                ),
              ),
            ),
          ),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabLabel(
                      label: tabs[i],
                      active: _tab == i,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FhcAsyncBody<List<_ModuleSpec>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'member.kca.noModules',
                fallback: 'No modules',
              ),
              unavailableTitle: fhcT(
                context,
                'member.kca.modulesUnavailable',
                fallback: 'KCA modules unavailable',
              ),
              builder: (context, modules) {
                final visible =
                    _tab == 0
                        ? modules
                        : modules
                            .where((m) => m.status != _ModuleStatus.notStarted)
                            .toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  children: [
                    if (_tab == 1) ...[
                      _ProgressOverview(modules: modules),
                      const SizedBox(height: 12),
                    ],
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _ModuleRow(
                        spec: visible[i],
                        onTap:
                            visible[i].id.isEmpty
                                ? null
                                : () => fhcPush(
                                  context,
                                  '${FhcRoutes.kcaModule}/${Uri.encodeComponent(visible[i].id)}',
                                ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

enum _ModuleStatus { completed, inProgress, notStarted }

class _ModuleSpec {
  const _ModuleSpec({
    required this.id,
    required this.number,
    required this.title,
    required this.status,
  });

  factory _ModuleSpec.fromJson(
    Map<String, Object?> json, {
    required int fallbackNumber,
  }) {
    final id = '${json['id'] ?? json['public_id'] ?? ''}';
    final sequence = json['sequence'];
    final number =
        sequence is int
            ? sequence
            : sequence is num
            ? sequence.round()
            : fallbackNumber;
    final progress = '${json['progress_state'] ?? json['status'] ?? ''}'
        .toLowerCase();
    final status =
        progress.contains('complete')
            ? _ModuleStatus.completed
            : progress.contains('progress') || progress.contains('active')
            ? _ModuleStatus.inProgress
            : _ModuleStatus.notStarted;
    return _ModuleSpec(
      id: id,
      number: number,
      title: '${json['title'] ?? json['code'] ?? 'Module'}',
      status: status,
    );
  }

  final String id;
  final int number;
  final String title;
  final _ModuleStatus status;
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
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

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({required this.modules});

  final List<_ModuleSpec> modules;

  @override
  Widget build(BuildContext context) {
    final done =
        modules.where((m) => m.status == _ModuleStatus.completed).length;
    final total = modules.length;
    _ModuleSpec? current;
    for (final m in modules) {
      if (m.status == _ModuleStatus.inProgress) {
        current = m;
        break;
      }
    }

    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fhcT(
                    context,
                    'member.kca.yourProgress',
                    fallback: 'Your Progress',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$done / $total',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.greenDark,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              backgroundColor: FhcColors.border,
              valueColor: const AlwaysStoppedAnimation(FhcColors.green),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            current == null
                ? fhcT(
                  context,
                  'member.kca.noModuleInProgress',
                  fallback: 'No module in progress',
                )
                : fhcT(
                  context,
                  'member.kca.moduleInProgress',
                  args: {'n': '${current.number}', 'title': current.title},
                  fallback: 'Module {n} · {title}',
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: FhcColors.muted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.spec, this.onTap});

  final _ModuleSpec spec;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inProgress = spec.status == _ModuleStatus.inProgress;
    final notStarted = spec.status == _ModuleStatus.notStarted;
    final statusLabel = switch (spec.status) {
      _ModuleStatus.completed => fhcT(
        context,
        'member.kca.completed',
        fallback: 'Completed',
      ),
      _ModuleStatus.inProgress => fhcT(
        context,
        'member.kca.inProgress',
        fallback: 'In Progress',
      ),
      _ModuleStatus.notStarted => fhcT(
        context,
        'member.kca.notStarted',
        fallback: 'Not Started',
      ),
    };
    final statusColor = switch (spec.status) {
      _ModuleStatus.completed => FhcColors.green,
      _ModuleStatus.inProgress => FhcColors.gold,
      _ModuleStatus.notStarted => FhcColors.hint,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: FhcColors.white,
            borderRadius: BorderRadius.circular(FhcRadius.card),
            border: Border.all(
              color: inProgress ? FhcColors.green : FhcColors.border,
            ),
            boxShadow: FhcElevation.card,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                _NumberBadge(number: spec.number, status: spec.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fhcT(
                          context,
                          'member.kca.moduleN',
                          args: {'n': '${spec.number}'},
                          fallback: 'Module {n}',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: notStarted ? FhcColors.hint : FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        spec.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: notStarted ? FhcColors.hint : FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      height: 1.1,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: FhcColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, required this.status});

  final int number;
  final _ModuleStatus status;

  @override
  Widget build(BuildContext context) {
    final completed = status == _ModuleStatus.completed;
    final inProgress = status == _ModuleStatus.inProgress;
    final fill =
        completed
            ? FhcColors.green
            : inProgress
            ? FhcColors.kca
            : FhcColors.border;
    final fg = completed || inProgress ? FhcColors.white : FhcColors.hint;

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child:
          completed
              ? const Icon(Icons.check, size: 18, color: FhcColors.white)
              : Text(
                '$number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  height: 1,
                ),
              ),
    );
  }
}

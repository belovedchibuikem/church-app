import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class KcaAssignmentsScreen extends StatefulWidget {
  const KcaAssignmentsScreen({super.key, this.kcaRepository});

  final KcaRepository? kcaRepository;

  @override
  State<KcaAssignmentsScreen> createState() => _KcaAssignmentsScreenState();
}

class _KcaAssignmentsScreenState extends State<KcaAssignmentsScreen> {
  int _tab = 0;
  FhcAsyncValue<List<_Assignment>> _state = const FhcAsyncValue.loading();

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
            'member.kca.assignmentsRequireApi',
            fallback:
                'KCA assignments require the member curriculum API. '
                'No design fixtures are shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.listAssignments();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'member.kca.noAssignmentsEnrollment',
                fallback: 'No assignments for your enrollment yet.',
              ),
            );
          });
          return;
        }
        setState(() {
          _state = FhcAsyncValue.data([
            for (final item in value) _Assignment.fromJson(item),
          ]);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  List<_Assignment> _filter(List<_Assignment> all) {
    return switch (_tab) {
      1 => all.where((a) => a.bucket == _Bucket.submitted).toList(),
      2 => all.where((a) => a.bucket == _Bucket.completed).toList(),
      _ => all.where((a) => a.bucket == _Bucket.pending).toList(),
    };
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
    final counts = switch (_state) {
      FhcAsyncData(:final value) => (
        pending: value.where((a) => a.bucket == _Bucket.pending).length,
        submitted: value.where((a) => a.bucket == _Bucket.submitted).length,
        completed: value.where((a) => a.bucket == _Bucket.completed).length,
      ),
      _ => (pending: 0, submitted: 0, completed: 0),
    };
    final tabs = <(String, int)>[
      (
        fhcT(context, 'member.kca.pending', fallback: 'Pending'),
        counts.pending,
      ),
      (
        fhcT(context, 'member.kca.submitted', fallback: 'Submitted'),
        counts.submitted,
      ),
      (
        fhcT(context, 'member.kca.completed', fallback: 'Completed'),
        counts.completed,
      ),
    ];

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'member.kca.myAssignments',
              fallback: 'MY ASSIGNMENTS',
            ),
            onBack: _back,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _StatusTab(
                      label: '${tabs[i].$1} (${tabs[i].$2})',
                      active: _tab == i,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: FhcAsyncBody<List<_Assignment>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'member.kca.noAssignments',
                fallback: 'No assignments',
              ),
              unavailableTitle: fhcT(
                context,
                'member.kca.assignmentsUnavailable',
                fallback: 'Assignments unavailable',
              ),
              builder: (context, all) {
                final items = _filter(all);
                if (items.isEmpty) {
                  return FhcEmptyState(
                    title: fhcT(
                      context,
                      'member.kca.nothingInThisTab',
                      fallback: 'Nothing in this tab',
                    ),
                    message: fhcT(
                      context,
                      'member.kca.switchTabsOrRefresh',
                      fallback: 'Switch tabs or refresh after new assignments.',
                    ),
                  );
                }
                return ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _AssignmentCard(assignment: items[index]);
                  },
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

enum _Bucket { pending, submitted, completed }

enum _Priority { high, medium, low }

class _Assignment {
  const _Assignment({
    required this.title,
    required this.moduleLabel,
    required this.dateLabel,
    required this.priority,
    required this.bucket,
    required this.icon,
    required this.iconColor,
  });

  factory _Assignment.fromJson(Map<String, Object?> json) {
    final state = '${json['state'] ?? json['status'] ?? ''}'.toLowerCase();
    final tree = json['soul_tree'];
    final treeOpen = tree is Map && tree['open'] == true;
    final bucket =
        treeOpen
            ? _Bucket.pending
            : state.contains('approved') || state.contains('complete')
            ? _Bucket.completed
            : state.contains('submit') || state.contains('review')
            ? _Bucket.submitted
            : _Bucket.pending;
    final module = json['module'];
    final lesson = json['lesson'];
    final moduleTitle =
        module is Map
            ? '${module['title'] ?? module['code'] ?? 'Module'}'
            : 'Module';
    final lessonTitle =
        lesson is Map
            ? '${lesson['title'] ?? lesson['code'] ?? ''}'
            : '';
    final scopeLabel =
        lessonTitle.isEmpty ? moduleTitle : '$moduleTitle · $lessonTitle';
    final due = json['due_at'] ?? json['submitted_at'] ?? json['updated_at'];
    final recorded = tree is Map ? '${tree['recorded_souls'] ?? 0}' : '';
    final required = tree is Map ? '${tree['required_souls'] ?? 0}' : '';
    final kind = '${json['assignment_kind'] ?? ''}';
    return _Assignment(
      title: '${json['title'] ?? 'Assignment'}',
      moduleLabel: treeOpen
          ? '$scopeLabel • souls $recorded/$required (open)'
          : kind == 'soul_winning'
          ? '$scopeLabel • soul tree complete'
          : scopeLabel,
      dateLabel: due == null ? '' : due.toString(),
      priority: switch ('${json['priority'] ?? ''}'.toLowerCase()) {
        'high' => _Priority.high,
        'low' => _Priority.low,
        _ => _Priority.medium,
      },
      bucket: bucket,
      icon: Icons.assignment_outlined,
      iconColor: FhcColors.greenDark,
    );
  }

  final String title;
  final String moduleLabel;
  final String dateLabel;
  final _Priority priority;
  final _Bucket bucket;
  final IconData icon;
  final Color iconColor;
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FhcRadius.sm),
          child: Ink(
            height: 36,
            decoration: BoxDecoration(
              color: active ? FhcColors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(FhcRadius.sm),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? FhcColors.white : FhcColors.muted,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});

  final _Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final date =
        assignment.dateLabel.isEmpty
            ? fhcT(
              context,
              'member.kca.noDueDate',
              fallback: 'No due date',
            )
            : assignment.dateLabel;
    final meta = '${assignment.moduleLabel} • $date';

    return Semantics(
      label: '${assignment.title}, $meta',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: FhcColors.white,
            borderRadius: BorderRadius.circular(FhcRadius.card),
            border: Border.all(color: FhcColors.border),
            boxShadow: FhcElevation.card,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: assignment.iconColor,
                  borderRadius: BorderRadius.circular(FhcRadius.sm),
                ),
                child: Icon(
                  assignment.icon,
                  size: 20,
                  color: FhcColors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
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
              ),
              const SizedBox(width: 8),
              _PriorityPill(priority: assignment.priority),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final _Priority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      _Priority.high => (
        fhcT(context, 'member.kca.priorityHigh', fallback: 'High'),
        FhcColors.red,
      ),
      _Priority.medium => (
        fhcT(context, 'member.kca.priorityMedium', fallback: 'Medium'),
        FhcColors.gold,
      ),
      _Priority.low => (
        fhcT(context, 'member.kca.priorityLow', fallback: 'Low'),
        FhcColors.green,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

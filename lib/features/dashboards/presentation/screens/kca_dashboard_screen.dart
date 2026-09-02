import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class KcaDashboardScreen extends StatefulWidget {
  const KcaDashboardScreen({super.key, this.kcaRepository});

  final KcaRepository? kcaRepository;

  @override
  State<KcaDashboardScreen> createState() => _KcaDashboardScreenState();
}

class _KcaDashboardScreenState extends State<KcaDashboardScreen> {
  FhcAsyncValue<_KcaDash> _state = const FhcAsyncValue.loading();

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
            'errors.kcaDashboardRequiresApi',
            fallback:
                'KCA dashboard requires the member curriculum API. '
                'No design fixtures are shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.getDashboard();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        setState(() => _state = FhcAsyncValue.data(_KcaDash.fromJson(value)));
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      darkStatusBar: true,
      statusBarColor: FhcColors.greenDeep,
      child: Column(
        children: [
          Expanded(
            child: FhcAsyncBody<_KcaDash>(
              value: _state,
              onRetry: _load,
              unavailableTitle: fhcT(
                context,
                'errors.kcaUnavailable',
                fallback: 'KCA unavailable',
              ),
              emptyTitle: fhcT(
                context,
                'member.kcaNotEnrolledTitle',
                fallback: 'Not enrolled',
              ),
              builder: (context, dash) {
                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: _KcaHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      sliver: SliverList.list(
                        children: [
                          _ProgressCard(dash: dash),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _KcaMetric(
                                  icon: Icons.menu_book_outlined,
                                  title: fhcT(
                                    context,
                                    'member.kcaModules',
                                    fallback: 'Modules',
                                  ),
                                  value:
                                      '${dash.modulesWithProgress} / ${dash.modulesTotal}',
                                  onTap:
                                      () => fhcPush(
                                        context,
                                        FhcRoutes.kcaModules,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _KcaMetric(
                                  icon: Icons.assignment_outlined,
                                  title: fhcT(
                                    context,
                                    'member.kcaAssignments',
                                    fallback: 'Assignments',
                                  ),
                                  value: fhcT(
                                    context,
                                    'member.kcaAssignmentsOpen',
                                    args: {'count': '${dash.assignmentsOpen}'},
                                    fallback: '${dash.assignmentsOpen} open',
                                  ),
                                  onTap:
                                      () => fhcPush(
                                        context,
                                        FhcRoutes.kcaAssignments,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _KcaMetric(
                                  icon: Icons.menu_book_outlined,
                                  title: fhcT(
                                    context,
                                    'member.kcaBible',
                                    fallback: 'Bible plan',
                                  ),
                                  value: dash.biblePercent == null
                                      ? '—'
                                      : '${dash.biblePercent}%',
                                  onTap: () => fhcPush(context, FhcRoutes.bible),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _KcaMetric(
                                  icon: Icons.groups_outlined,
                                  title: fhcT(
                                    context,
                                    'member.kcaMentees',
                                    fallback: 'Mentees',
                                  ),
                                  value: dash.isMentor ? 'Open' : '—',
                                  onTap: dash.isMentor
                                      ? () => fhcPush(context, FhcRoutes.kcaMentees)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _KcaMetric(
                                  icon: Icons.event_available_outlined,
                                  title: fhcT(
                                    context,
                                    'member.kcaAttendance',
                                    fallback: 'Attendance',
                                  ),
                                  value: fhcT(
                                    context,
                                    'member.kcaAttendanceRecorded',
                                    args: {
                                      'count': '${dash.attendanceRecorded}',
                                    },
                                    fallback:
                                        '${dash.attendanceRecorded} recorded',
                                  ),
                                  onTap:
                                      () => fhcPush(
                                        context,
                                        FhcRoutes.kcaAttendance,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _KcaMetric(
                                  icon: Icons.school_outlined,
                                  title: fhcT(
                                    context,
                                    'member.kcaMentor',
                                    fallback: 'Mentor',
                                  ),
                                  value: dash.mentorAssigned
                                      ? dash.mentorName
                                      : fhcT(
                                          context,
                                          'member.kcaUnassigned',
                                          fallback: 'Unassigned',
                                        ),
                                  action: dash.mentorAssigned
                                      ? fhcT(
                                          context,
                                          'common.view',
                                          fallback: 'View',
                                        )
                                      : null,
                                  onAction:
                                      dash.mentorAssigned
                                          ? () => fhcPush(
                                            context,
                                            FhcRoutes.kcaMentor,
                                          )
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _KcaMetric(
                                  icon: Icons.flag_outlined,
                                  title: fhcT(
                                    context,
                                    'member.kcaOrientation',
                                    fallback: 'Orientation',
                                  ),
                                  value: fhcT(
                                    context,
                                    'member.kcaOrientationReview',
                                    fallback: 'Review',
                                  ),
                                  onTap: () => fhcPush(
                                    context,
                                    FhcRoutes.kcaOrientation,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!dash.enrolled) ...[
                            const SizedBox(height: 14),
                            Text(
                              fhcT(
                                context,
                                'member.kcaNotEnrolledCopy',
                                fallback:
                                    'You are not enrolled yet. Published modules remain browsable; evidence submit stays OD-008 gated.',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: FhcColors.muted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          FhcBottomNavigation(
            selected: 1,
            onSelected: (i) => fhcTab(context, i),
          ),
        ],
      ),
    );
  }
}

class _KcaDash {
  const _KcaDash({
    required this.enrolled,
    required this.modulesTotal,
    required this.modulesWithProgress,
    required this.assignmentsOpen,
    required this.attendanceRecorded,
    required this.mentorName,
    required this.mentorAssigned,
    required this.isMentor,
    this.biblePercent,
  });

  factory _KcaDash.fromJson(Map<String, Object?> json) {
    final mentor = json['mentor'];
    String mentorName = 'Unassigned';
    var assigned = false;
    if (mentor is Map) {
      assigned = true;
      final given =
          '${mentor['preferred_name'] ?? mentor['given_name'] ?? 'Mentor'}';
      final family = '${mentor['family_name'] ?? ''}'.trim();
      mentorName = family.isEmpty ? given : '$given $family'.trim();
    }
    final activity = json['activity'];
    int? biblePercent;
    if (activity is Map) {
      final bible = activity['bible'];
      if (bible is Map) {
        final enrollment = bible['enrollment'];
        if (enrollment is Map) {
          biblePercent = _asInt(enrollment['percent']);
        }
      }
    }
    return _KcaDash(
      enrolled: json['enrolled'] == true,
      modulesTotal: _asInt(json['modules_total']),
      modulesWithProgress: _asInt(json['modules_with_progress']),
      assignmentsOpen: _asInt(json['assignments_open']),
      attendanceRecorded: _asInt(json['attendance_recorded']),
      mentorName: mentorName,
      mentorAssigned: assigned,
      isMentor: json['is_mentor'] == true,
      biblePercent: biblePercent,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }

  final bool enrolled;
  final int modulesTotal;
  final int modulesWithProgress;
  final int assignmentsOpen;
  final int attendanceRecorded;
  final String mentorName;
  final bool mentorAssigned;
  final bool isMentor;
  final int? biblePercent;
}

class _KcaHeader extends StatelessWidget {
  const _KcaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FhcColors.greenDeep,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fhcT(
                    context,
                    'member.kcaAcademy',
                    fallback: 'Kingdom Change Agents',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              fhcT(
                context,
                'member.kcaLiveCurriculum',
                fallback: 'Your curriculum progress',
              ),
              style: const TextStyle(fontSize: 12, color: Color(0xFFD7E8DC)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.dash});

  final _KcaDash dash;

  @override
  Widget build(BuildContext context) {
    final total = dash.modulesTotal;
    final progress = dash.modulesWithProgress;
    final pct = total == 0 ? 0.0 : progress / total;

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
                    'member.kcaModuleProgress',
                    fallback: 'Module Progress',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.greenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: FhcColors.border,
              valueColor: const AlwaysStoppedAnimation(FhcColors.green),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fhcT(
              context,
              'member.kcaModulesWithActivity',
              args: {'progress': '$progress', 'total': '$total'},
              fallback: '$progress / $total modules with activity',
            ),
            style: const TextStyle(fontSize: 11, color: FhcColors.muted),
          ),
        ],
      ),
    );
  }
}

class _KcaMetric extends StatelessWidget {
  const _KcaMetric({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: FhcColors.white,
            borderRadius: BorderRadius.circular(FhcRadius.card),
            border: Border.all(color: FhcColors.border),
            boxShadow: FhcElevation.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: FhcColors.green),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: FhcColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.ink,
                ),
              ),
              if (action != null && onAction != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: FhcColors.green,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(action!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

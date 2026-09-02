import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../community/data/livestream_repository.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchReportsScreen extends StatelessWidget {
  const ChurchReportsScreen({
    super.key,
    this.homeChurch = false,
    this.homeChurchId,
    this.homeChurchRepository,
  });

  final bool homeChurch;
  final String? homeChurchId;
  final HomeChurchRepository? homeChurchRepository;

  static List<Widget> _fixtureChildren(BuildContext context) => [
    WorkflowField(
      label: fhcT(
        context,
        'homeChurch.reportingPeriod',
        fallback: 'Reporting Period',
      ),
      value: fhcT(context, 'homeChurch.may2025', fallback: 'May 2025'),
      icon: Icons.keyboard_arrow_down,
    ),
    WorkflowSectionTitle(
      fhcT(context, 'homeChurch.overview', fallback: 'Overview'),
    ),
    WorkflowSummary(
      title: fhcT(
        context,
        'homeChurch.may2025Summary',
        fallback: 'May 2025 Summary',
      ),
      metrics: [
        (
          '128',
          fhcT(context, 'homeChurch.attendance', fallback: 'Attendance'),
        ),
        (
          '8',
          fhcT(context, 'homeChurch.firstTimers', fallback: 'First Timers'),
        ),
        (
          '4',
          fhcT(context, 'homeChurch.salvations', fallback: 'Salvations'),
        ),
      ],
    ),
    WorkflowSectionTitle(
      fhcT(context, 'homeChurch.reports', fallback: 'Reports'),
    ),
    WorkflowCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          WorkflowRow(
            title: fhcT(
              context,
              'homeChurch.attendanceReport',
              fallback: 'Attendance Report',
            ),
            leading: Icons.fact_check_outlined,
          ),
          WorkflowRow(
            title: fhcT(
              context,
              'homeChurch.firstTimersReport',
              fallback: 'First Timers Report',
            ),
            leading: Icons.person_add_alt_1_outlined,
          ),
          WorkflowRow(
            title: fhcT(
              context,
              'homeChurch.needsReport',
              fallback: 'Needs Report',
            ),
            leading: Icons.volunteer_activism_outlined,
          ),
          WorkflowRow(
            title: fhcT(
              context,
              'homeChurch.salvationsReport',
              fallback: 'Salvations Report',
            ),
            leading: Icons.favorite_outline,
          ),
          WorkflowRow(
            title: fhcT(
              context,
              'homeChurch.financialReport',
              fallback: 'Financial Report',
            ),
            leading: Icons.account_balance_wallet_outlined,
          ),
          WorkflowRow(
            title: fhcT(
              context,
              'homeChurch.ministryReport',
              fallback: 'Ministry Report',
            ),
            leading: Icons.groups_outlined,
          ),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (homeChurch) {
      return _HomeChurchReportSubmitPage(
        title: fhcT(
          context,
          'homeChurch.homeChurchReports',
          fallback: 'Home Church Reports',
        ),
        homeChurchId: homeChurchId,
        repository: homeChurchRepository,
        fixtureActionLabel: fhcT(
          context,
          'homeChurch.downloadAllReports',
          fallback: 'Download All Reports',
        ),
        fixtureChildren: _fixtureChildren(context),
      );
    }
    return WorkflowPage(
      title: fhcT(context, 'homeChurch.reports', fallback: 'Reports'),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(
        context,
        'homeChurch.generateReport',
        fallback: 'Generate Report',
      ),
      children: _fixtureChildren(context),
    );
  }
}

class FirstTimersScreen extends StatelessWidget {
  const FirstTimersScreen({super.key});

  static const people = [
    ('Jennifer Ade', 'Visited May 17, 2025', 'New'),
    ('Emmanuel Bassey', 'Visited May 17, 2025', 'New'),
    ('Mary Benson', 'Visited May 16, 2025', 'Contacted'),
    ('Peter James', 'Visited May 14, 2025', 'Contacted'),
    ('Grace Ibe', 'Visited May 13, 2025', 'Connected'),
    ('David Brown', 'Visited May 12, 2025', 'Connected'),
  ];

  static String _statusLabel(BuildContext context, String status) {
    return switch (status) {
      'New' => fhcT(context, 'homeChurch.statusNew', fallback: 'New'),
      'Contacted' => fhcT(
        context,
        'homeChurch.statusContacted',
        fallback: 'Contacted',
      ),
      'Connected' => fhcT(
        context,
        'homeChurch.statusConnected',
        fallback: 'Connected',
      ),
      _ => status,
    };
  }

  static String _visitLabel(BuildContext context, String visit) {
    return switch (visit) {
      'Visited May 17, 2025' => fhcT(
        context,
        'homeChurch.visitedMay17',
        fallback: 'Visited May 17, 2025',
      ),
      'Visited May 16, 2025' => fhcT(
        context,
        'homeChurch.visitedMay16',
        fallback: 'Visited May 16, 2025',
      ),
      'Visited May 14, 2025' => fhcT(
        context,
        'homeChurch.visitedMay14',
        fallback: 'Visited May 14, 2025',
      ),
      'Visited May 13, 2025' => fhcT(
        context,
        'homeChurch.visitedMay13',
        fallback: 'Visited May 13, 2025',
      ),
      'Visited May 12, 2025' => fhcT(
        context,
        'homeChurch.visitedMay12',
        fallback: 'Visited May 12, 2025',
      ),
      _ => visit,
    };
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(context, 'homeChurch.firstTimers', fallback: 'First Timers'),
      domain: WorkflowDomain.church,
      children: [
        WorkflowSegments(
          labels: [
            fhcT(context, 'homeChurch.newCount5', fallback: 'New (5)'),
            fhcT(
              context,
              'homeChurch.contactedCount3',
              fallback: 'Contacted (3)',
            ),
            fhcT(
              context,
              'homeChurch.connectedCount4',
              fallback: 'Connected (4)',
            ),
          ],
        ),
        const SizedBox(height: 10),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (final person in people)
                WorkflowRow(
                  title: person.$1,
                  subtitle:
                      '${_visitLabel(context, person.$2)}\n${fhcT(context, 'homeChurch.followUpWithin2Days', fallback: 'Follow up within 2 days')}',
                  leading: Icons.person_outline,
                  trailing: WorkflowPill(
                    _statusLabel(context, person.$3),
                    color:
                        person.$3 == 'New' ? FhcColors.gold : FhcColors.green,
                  ),
                  onTap: () => fhcPush(context, '/altar-call/follow-ups'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeChurchMembersScreen extends StatelessWidget {
  const HomeChurchMembersScreen({super.key});

  static String _roleLabel(BuildContext context, String role) {
    return switch (role) {
      'Leader' => fhcT(context, 'homeChurch.roleLeader', fallback: 'Leader'),
      'Member' => fhcT(context, 'homeChurch.roleMember', fallback: 'Member'),
      'First Timer' => fhcT(
        context,
        'homeChurch.roleFirstTimer',
        fallback: 'First Timer',
      ),
      _ => role,
    };
  }

  static String _joinedLabel(BuildContext context, String joined) {
    return switch (joined) {
      'Joined Apr 12, 2025' => fhcT(
        context,
        'homeChurch.joinedApr12',
        fallback: 'Joined Apr 12, 2025',
      ),
      'Joined Apr 18, 2025' => fhcT(
        context,
        'homeChurch.joinedApr18',
        fallback: 'Joined Apr 18, 2025',
      ),
      'Joined Apr 20, 2025' => fhcT(
        context,
        'homeChurch.joinedApr20',
        fallback: 'Joined Apr 20, 2025',
      ),
      'Joined Apr 21, 2025' => fhcT(
        context,
        'homeChurch.joinedApr21',
        fallback: 'Joined Apr 21, 2025',
      ),
      'Joined May 17, 2025' => fhcT(
        context,
        'homeChurch.joinedMay17',
        fallback: 'Joined May 17, 2025',
      ),
      _ => joined,
    };
  }

  @override
  Widget build(BuildContext context) {
    const members = [
      ('John Abiola', 'Joined Apr 12, 2025', 'Leader'),
      ('Grace Okafor', 'Joined Apr 18, 2025', 'Member'),
      ('Michael Eze', 'Joined Apr 20, 2025', 'Member'),
      ('Blessing Uche', 'Joined Apr 21, 2025', 'Member'),
      ('David Collins', 'Joined May 17, 2025', 'First Timer'),
      ('Esther James', 'Joined May 17, 2025', 'First Timer'),
    ];
    return WorkflowPage(
      title: fhcT(
        context,
        'homeChurch.members',
        fallback: 'Home Church Members',
      ),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(context, 'homeChurch.addMember', fallback: 'Add Member'),
      children: [
        WorkflowField(
          label: fhcT(context, 'common.search', fallback: 'Search'),
          value: fhcT(
            context,
            'homeChurch.searchMembers',
            fallback: 'Search members...',
          ),
          icon: Icons.tune,
        ),
        WorkflowSegments(
          labels: [
            fhcT(context, 'homeChurch.allCount26', fallback: 'All (26)'),
            fhcT(context, 'homeChurch.leadersCount4', fallback: 'Leaders (4)'),
            fhcT(context, 'homeChurch.newCount3', fallback: 'New (3)'),
          ],
        ),
        const SizedBox(height: 10),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (final member in members)
                WorkflowRow(
                  title: member.$1,
                  subtitle: _joinedLabel(context, member.$2),
                  leading: Icons.person_outline,
                  trailing: WorkflowPill(
                    _roleLabel(context, member.$3),
                    color:
                        member.$3 == 'First Timer'
                            ? FhcColors.gold
                            : FhcColors.green,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeChurchAttendanceScreen extends StatelessWidget {
  const HomeChurchAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(context, 'homeChurch.attendance', fallback: 'Attendance'),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(
        context,
        'homeChurch.addAttendance',
        fallback: 'Add Attendance',
      ),
      children: [
        WorkflowField(
          label: fhcT(
            context,
            'homeChurch.serviceDate',
            fallback: 'Service Date',
          ),
          value: fhcT(context, 'homeChurch.may18_2025', fallback: 'May 18, 2025'),
          icon: Icons.keyboard_arrow_down,
        ),
        WorkflowSectionTitle(
          fhcT(
            context,
            'homeChurch.sundayServiceTime',
            fallback: 'Sunday Service  •  9:00 AM',
          ),
        ),
        WorkflowSummary(
          title: fhcT(
            context,
            'homeChurch.attendanceSummary',
            fallback: 'Attendance Summary',
          ),
          metrics: [
            ('128', fhcT(context, 'homeChurch.present', fallback: 'Present')),
            ('16', fhcT(context, 'homeChurch.visitors', fallback: 'Visitors')),
            ('144', fhcT(context, 'homeChurch.total', fallback: 'Total')),
          ],
        ),
        WorkflowSectionTitle(
          fhcT(
            context,
            'homeChurch.recentAttendance',
            fallback: 'Recent Attendance',
          ),
        ),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.may11_2025',
                  fallback: 'May 11, 2025',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.attendanceRow132',
                  fallback: 'Present: 132  •  Visitors: 20  •  Total: 152',
                ),
                leading: Icons.calendar_today_outlined,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.may4_2025',
                  fallback: 'May 4, 2025',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.attendanceRow118',
                  fallback: 'Present: 118  •  Visitors: 14  •  Total: 132',
                ),
                leading: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeChurchActivitiesScreen extends StatelessWidget {
  const HomeChurchActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(context, 'homeChurch.activities', fallback: 'Activities'),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(
        context,
        'homeChurch.addActivity',
        fallback: 'Add Activity',
      ),
      children: [
        WorkflowSegments(
          labels: [
            fhcT(context, 'homeChurch.upcoming', fallback: 'Upcoming'),
            fhcT(context, 'homeChurch.past', fallback: 'Past'),
          ],
        ),
        const SizedBox(height: 10),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.bibleStudy',
                  fallback: 'Study Manuals',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.bibleStudyDetails',
                  fallback: 'May 20, 2025  •  6:00 PM\nThe Garden House',
                ),
                leading: Icons.menu_book_outlined,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.prayerMeeting',
                  fallback: 'Prayer Meeting',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.prayerMeetingDetails',
                  fallback: 'May 22, 2025  •  7:00 PM\nOnline (Zoom)',
                ),
                leading: Icons.volunteer_activism_outlined,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.evangelismOutreach',
                  fallback: 'Evangelism Outreach',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.evangelismOutreachDetails',
                  fallback: 'May 24, 2025  •  10:00 AM\nCommunity Street',
                ),
                leading: Icons.groups_outlined,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.youthFellowship',
                  fallback: 'Youth Fellowship',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.youthFellowshipDetails',
                  fallback: 'May 25, 2025  •  4:00 PM\nChurch Auditorium',
                ),
                leading: Icons.diversity_3_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChurchFinanceScreen extends StatelessWidget {
  const ChurchFinanceScreen({super.key, this.homeChurch = false});

  final bool homeChurch;

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title:
          homeChurch
              ? fhcT(
                context,
                'homeChurch.homeChurchFinance',
                fallback: 'Home Church Finance',
              )
              : fhcT(context, 'homeChurch.finance', fallback: 'Finance'),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(
        context,
        'homeChurch.viewAllTransactions',
        fallback: 'View All Transactions',
      ),
      children: [
        WorkflowField(
          label: fhcT(context, 'homeChurch.period', fallback: 'Period'),
          value: fhcT(context, 'homeChurch.may2025', fallback: 'May 2025'),
          icon: Icons.keyboard_arrow_down,
        ),
        WorkflowSummary(
          title: fhcT(
            context,
            'homeChurch.financialOverview',
            fallback: 'Financial Overview',
          ),
          metrics: [
            ('₦1.25M', fhcT(context, 'homeChurch.income', fallback: 'Income')),
            (
              '₦720K',
              fhcT(context, 'homeChurch.expenses', fallback: 'Expenses'),
            ),
            ('₦530K', fhcT(context, 'homeChurch.balance', fallback: 'Balance')),
          ],
        ),
        WorkflowSectionTitle(
          fhcT(
            context,
            'homeChurch.recentTransactions',
            fallback: 'Recent Transactions',
          ),
        ),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              WorkflowRow(
                title: fhcT(context, 'homeChurch.tithe', fallback: 'Tithe'),
                subtitle: fhcT(
                  context,
                  'homeChurch.may16_2025',
                  fallback: 'May 16, 2025',
                ),
                leading: Icons.account_balance_outlined,
                trailing: const Text(
                  '₦250,000',
                  style: TextStyle(
                    color: FhcColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              WorkflowRow(
                title: fhcT(context, 'homeChurch.offering', fallback: 'Offering'),
                subtitle: fhcT(
                  context,
                  'homeChurch.may16_2025',
                  fallback: 'May 16, 2025',
                ),
                leading: Icons.account_balance_outlined,
                trailing: const Text(
                  '₦170,000',
                  style: TextStyle(
                    color: FhcColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.outreachExpense',
                  fallback: 'Outreach Expense',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.may16_2025',
                  fallback: 'May 16, 2025',
                ),
                leading: Icons.payments_outlined,
                trailing: const Text(
                  '-₦120,000',
                  style: TextStyle(
                    color: FhcColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.churchRent',
                  fallback: 'Church Rent',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.may10_2025',
                  fallback: 'May 10, 2025',
                ),
                leading: Icons.key_outlined,
                trailing: const Text(
                  '-₦200,000',
                  style: TextStyle(
                    color: FhcColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.buildingFund',
                  fallback: 'Building Fund',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.may8_2025',
                  fallback: 'May 8, 2025',
                ),
                leading: Icons.apartment_outlined,
                trailing: const Text(
                  '₦150,000',
                  style: TextStyle(
                    color: FhcColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({
    super.key,
    this.homeChurchId,
    this.homeChurchRepository,
  });

  final String? homeChurchId;
  final HomeChurchRepository? homeChurchRepository;

  @override
  Widget build(BuildContext context) {
    return _HomeChurchReportSubmitPage(
      title: fhcT(
        context,
        'homeChurch.monthlyReport',
        fallback: 'Monthly Report',
      ),
      homeChurchId: homeChurchId,
      repository: homeChurchRepository,
      fixtureActionLabel: fhcT(
        context,
        'homeChurch.submitReport',
        fallback: 'Submit Report',
      ),
      fixtureChildren: [
        WorkflowField(
          label: fhcT(context, 'homeChurch.month', fallback: 'Month'),
          value: fhcT(context, 'homeChurch.may2025', fallback: 'May 2025'),
          icon: Icons.calendar_month_outlined,
        ),
        WorkflowSummary(
          title: fhcT(
            context,
            'homeChurch.mayResults',
            fallback: 'May Results',
          ),
          metrics: [
            (
              '128',
              fhcT(context, 'homeChurch.attendance', fallback: 'Attendance'),
            ),
            (
              '8',
              fhcT(context, 'homeChurch.newMembers', fallback: 'New Members'),
            ),
            (
              '5',
              fhcT(context, 'homeChurch.firstTimers', fallback: 'First Timers'),
            ),
          ],
        ),
        WorkflowSectionTitle(
          fhcT(
            context,
            'homeChurch.reportDetails',
            fallback: 'Report Details',
          ),
        ),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.servicesGatherings',
                  fallback: 'Services & Gatherings',
                ),
                trailing: const Text('12'),
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.leadershipMeetings',
                  fallback: 'Leadership Meetings',
                ),
                trailing: const Text('3'),
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.needsShared',
                  fallback: 'Needs Shared',
                ),
                trailing: const Text('7'),
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.needsMet',
                  fallback: 'Needs Met',
                ),
                trailing: const Text('4'),
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.salvations',
                  fallback: 'Salvations',
                ),
                trailing: const Text('2'),
              ),
            ],
          ),
        ),
        WorkflowSectionTitle(
          fhcT(context, 'homeChurch.reportNotes', fallback: 'Report Notes'),
        ),
        WorkflowField(
          label: fhcT(context, 'homeChurch.notes', fallback: 'Notes'),
          value: fhcT(
            context,
            'homeChurch.reportNotesValue',
            fallback: 'Great month of growth and testimonies. Glory to God!',
          ),
          lines: 3,
        ),
      ],
    );
  }
}

class _HomeChurchReportSubmitPage extends StatefulWidget {
  const _HomeChurchReportSubmitPage({
    required this.title,
    required this.fixtureActionLabel,
    required this.fixtureChildren,
    this.homeChurchId,
    this.repository,
  });

  final String title;
  final String fixtureActionLabel;
  final List<Widget> fixtureChildren;
  final String? homeChurchId;
  final HomeChurchRepository? repository;

  @override
  State<_HomeChurchReportSubmitPage> createState() =>
      _HomeChurchReportSubmitPageState();
}

class _HomeChurchReportSubmitPageState
    extends State<_HomeChurchReportSubmitPage> {
  final _summaryController = TextEditingController();
  final _periodController = TextEditingController();
  bool _submitting = false;
  bool _done = false;
  String? _error;
  bool _useFixtures = false;
  bool _unavailable = false;
  String? _unavailableMessage;
  bool _started = false;
  String? _homeChurchId;

  HomeChurchRepository? get _repo =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.homeChurchRepository;

  bool get _showUnboundFixtures =>
      AppServicesScope.maybeOf(context)?.showUnboundFixtures ?? false;

  String? _resolveId() {
    final fromProp = widget.homeChurchId?.trim();
    if (fromProp != null && fromProp.isNotEmpty) return fromProp;
    return FhcRouteArgs.entityIdOf(context)?.trim();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final id = _resolveId();
    if (id != null && id.isNotEmpty) {
      _homeChurchId = id;
      return;
    }
    if (_showUnboundFixtures) {
      _useFixtures = true;
      return;
    }
    _unavailable = true;
    _unavailableMessage = fhcT(
      context,
      'errors.homeChurchIdRequired',
      fallback:
          'A home church ULID is required (FhcRouteArgs.entityId) to submit a report.',
    );
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _done) return;
    final id = _homeChurchId ?? _resolveId();
    final summary = _summaryController.text.trim();
    if (id == null || id.isEmpty) {
      setState(() {
        _error = fhcT(
          context,
          'errors.homeChurchIdRequired',
          fallback:
              'A home church ULID is required (FhcRouteArgs.entityId) to submit a report.',
        );
      });
      return;
    }
    if (summary.isEmpty) {
      setState(
        () =>
            _error = fhcT(
              context,
              'errors.summaryRequired',
              fallback: 'Summary is required.',
            ),
      );
      return;
    }
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error = fhcT(
          context,
          'errors.homeChurchReportsRequireApi',
          fallback:
              'Home church reports require AppServices.homeChurchRepository. '
              'No fixture submit is available.',
        );
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final period = _periodController.text.trim();
    final result = await repo.submitReport({
      'id': id,
      'home_church_id': id,
      'summary': summary,
      if (period.isNotEmpty) 'period_code': period,
    });
    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        setState(() {
          _submitting = false;
          _done = true;
        });
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = failure is ValidationFailure && failure.errors.isNotEmpty
              ? failure.errors.values.expand((e) => e).join(' ')
              : failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useFixtures) {
      return WorkflowPage(
        title: widget.title,
        domain: WorkflowDomain.church,
        actionLabel: widget.fixtureActionLabel,
        children: widget.fixtureChildren,
      );
    }

    if (_unavailable) {
      return WorkflowPage(
        title: widget.title,
        domain: WorkflowDomain.church,
        children: [
          FhcUnavailableState(
            title: fhcT(
              context,
              'errors.homeChurchReportsUnavailable',
              fallback: 'Home church reports unavailable',
            ),
            message:
                _unavailableMessage ??
                fhcT(
                  context,
                  'errors.homeChurchIdRequiredShort',
                  fallback: 'A home church ULID is required to submit a report.',
                ),
          ),
        ],
      );
    }

    return WorkflowPage(
      title: widget.title,
      domain: WorkflowDomain.church,
      actionLabel: _done
          ? null
          : (_submitting
              ? fhcT(context, 'homeChurch.submitting', fallback: 'Submitting…')
              : fhcT(
                context,
                'homeChurch.submitReport',
                fallback: 'Submit Report',
              )),
      onAction: (_submitting || _done) ? null : _submit,
      children: [
        WorkflowCard(
          color: const Color(0xFFEAF4EF),
          child: Text(
            fhcT(
              context,
              'homeChurch.submitReportHelp',
              fallback:
                  'Submit a home church report via POST /user/home-churches/{id}/reports. '
                  'Summary is required. Period code is optional.',
            ),
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            text: fhcT(context, 'homeChurch.summary', fallback: 'Summary'),
            style: FhcTypography.label,
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: FhcColors.red)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _summaryController,
          minLines: 4,
          maxLines: 8,
          maxLength: 2000,
          enabled: !_submitting && !_done,
          decoration: InputDecoration(
            hintText: fhcT(
              context,
              'homeChurch.summaryHint',
              fallback: 'What happened this period?',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          fhcT(context, 'homeChurch.periodCode', fallback: 'Period code'),
          style: FhcTypography.label,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _periodController,
          enabled: !_submitting && !_done,
          decoration: InputDecoration(
            hintText: fhcT(
              context,
              'homeChurch.periodCodeHint',
              fallback: 'Optional, e.g. 2026-W34',
            ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          FhcErrorState(
            title: fhcT(
              context,
              'errors.unableToSubmitReport',
              fallback: 'Unable to submit report',
            ),
            message: _error!,
            onRetry: _submitting ? null : _submit,
          ),
        ],
        if (_done) ...[
          const SizedBox(height: 12),
          WorkflowCard(
            color: const Color(0xFFEAF4EF),
            child: Text(
              fhcT(
                context,
                'homeChurch.reportSubmitted',
                fallback: 'Report submitted.',
              ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

class ShareNeedScreen extends StatefulWidget {
  const ShareNeedScreen({super.key, this.needRepository});

  final NeedRepository? needRepository;

  @override
  State<ShareNeedScreen> createState() => _ShareNeedScreenState();
}

class _ShareNeedScreenState extends State<ShareNeedScreen> {
  final _summaryController = TextEditingController();
  String _category = 'Pastoral care';
  bool _submitting = false;
  String? _error;
  bool _done = false;

  static const _categories = <String>[
    'Pastoral care',
    'Medical',
    'Financial',
    'Family',
    'Housing',
    'Other',
  ];

  NeedRepository? get _repo =>
      widget.needRepository ??
      AppServicesScope.maybeOf(context)?.needRepository;

  String _categoryLabel(BuildContext context, String value) {
    return switch (value) {
      'Pastoral care' => fhcT(
        context,
        'homeChurch.needCategoryPastoral',
        fallback: 'Pastoral care',
      ),
      'Medical' => fhcT(
        context,
        'homeChurch.needCategoryMedical',
        fallback: 'Medical',
      ),
      'Financial' => fhcT(
        context,
        'homeChurch.needCategoryFinancial',
        fallback: 'Financial',
      ),
      'Family' => fhcT(
        context,
        'homeChurch.needCategoryFamily',
        fallback: 'Family',
      ),
      'Housing' => fhcT(
        context,
        'homeChurch.needCategoryHousing',
        fallback: 'Housing',
      ),
      'Other' => fhcT(
        context,
        'homeChurch.needCategoryOther',
        fallback: 'Other',
      ),
      _ => value,
    };
  }

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final summary = _summaryController.text.trim();
    if (summary.isEmpty) {
      setState(
        () =>
            _error = fhcT(
              context,
              'errors.describeNeed',
              fallback: 'Describe the need before sharing.',
            ),
      );
      return;
    }
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error = fhcT(
          context,
          'errors.shareNeedRequiresApi',
          fallback:
              'Sharing a need requires the needs service. '
              'No fixture submit is available.',
        );
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await repo.create({
      'category': _category,
      'summary': summary,
    });
    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        setState(() {
          _submitting = false;
          _done = true;
        });
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(context, 'homeChurch.shareNeed', fallback: 'Share a Need'),
      domain: WorkflowDomain.church,
      actionLabel: _done
          ? null
          : (_submitting
              ? fhcT(context, 'homeChurch.sharing', fallback: 'Sharing…')
              : fhcT(context, 'homeChurch.shareNeedAction', fallback: 'Share Need')),
      onAction: (_submitting || _done) ? null : _submit,
      children: [
        WorkflowCard(
          color: const Color(0xFFFFF7E6),
          child: Text(
            fhcT(
              context,
              'homeChurch.shareNeedCopy',
              fallback:
                  'When you share a need, your church family can support you in love.',
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF8B5A00)),
          ),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            text: fhcT(context, 'homeChurch.category', fallback: 'Category'),
            style: FhcTypography.label,
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: FhcColors.red)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _category,
          items: [
            for (final c in _categories)
              DropdownMenuItem(value: c, child: Text(_categoryLabel(context, c))),
          ],
          onChanged:
              _submitting || _done
                  ? null
                  : (v) {
                    if (v != null) setState(() => _category = v);
                  },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text: fhcT(
              context,
              'homeChurch.description',
              fallback: 'Description',
            ),
            style: FhcTypography.label,
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: FhcColors.red)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _summaryController,
          minLines: 4,
          maxLines: 6,
          enabled: !_submitting && !_done,
          decoration: InputDecoration(
            hintText: fhcT(
              context,
              'homeChurch.describeNeedHint',
              fallback: 'Describe the need in detail…',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          FhcErrorState(
            title: fhcT(
              context,
              'errors.unableToShareNeed',
              fallback: 'Unable to share need',
            ),
            message: _error!,
            onRetry: _submitting ? null : _submit,
          ),
        ],
        if (_done) ...[
          const SizedBox(height: 12),
          FhcEmptyState(
            title: fhcT(context, 'homeChurch.needShared', fallback: 'Need shared'),
            message: fhcT(
              context,
              'homeChurch.needSharedCopy',
              fallback: 'Your pastoral need was submitted to the church API.',
            ),
          ),
        ],
      ],
    );
  }
}

class NeedsManagementScreen extends StatefulWidget {
  const NeedsManagementScreen({super.key, this.needRepository});

  final NeedRepository? needRepository;

  @override
  State<NeedsManagementScreen> createState() => _NeedsManagementScreenState();
}

class _NeedsManagementScreenState extends State<NeedsManagementScreen> {
  FhcAsyncValue<List<JsonObject>> _state = const FhcAsyncValue.loading();

  NeedRepository? get _repo =>
      widget.needRepository ??
      AppServicesScope.maybeOf(context)?.needRepository;

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
            'errors.needsRequireApi',
            fallback:
                'Needs require the needs service. '
                'No design fixtures are shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.listOwn();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'homeChurch.noNeedsYetCopy',
                fallback: 'You have not shared a pastoral need yet.',
              ),
            );
          });
          return;
        }
        setState(() => _state = FhcAsyncValue.data(value));
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(
        context,
        'homeChurch.needsManagement',
        fallback: 'Needs Management',
      ),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(context, 'homeChurch.addNeed', fallback: 'Add Need'),
      onAction: () => fhcPush(context, FhcRoutes.needRequest),
      children: [
        SizedBox(
          height: 420,
          child: FhcAsyncBody<List<JsonObject>>(
            value: _state,
            onRetry: _load,
            emptyTitle: fhcT(
              context,
              'homeChurch.noNeedsYet',
              fallback: 'No needs yet',
            ),
            unavailableTitle: fhcT(
              context,
              'errors.needsUnavailable',
              fallback: 'Needs unavailable',
            ),
            builder: (context, needs) {
              return ListView.separated(
                itemCount: needs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final need = needs[index];
                  final summary =
                      '${need['summary'] ?? fhcT(context, 'homeChurch.need', fallback: 'Need')}';
                  final category =
                      '${need['category'] ?? fhcT(context, 'homeChurch.needCategoryPastoralShort', fallback: 'Pastoral')}';
                  final status =
                      '${need['status'] ?? fhcT(context, 'homeChurch.needStatusOpen', fallback: 'open')}';
                  return WorkflowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$category · $status',
                          style: FhcTypography.caption,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class OnlineChurchScreen extends StatefulWidget {
  const OnlineChurchScreen({super.key});

  @override
  State<OnlineChurchScreen> createState() => _OnlineChurchScreenState();
}

class _OnlineChurchScreenState extends State<OnlineChurchScreen> {
  final _repo = LivestreamRepository();
  JsonObject? _stream;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.getCurrent();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result case AppSuccess(:final value)) {
        _stream = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = '${_stream?['status'] ?? ''}'.toLowerCase();
    final title = (_stream?['title'] as String?) ??
        fhcT(context, 'homeChurch.onlineChurch', fallback: 'Online Church');
    final subtitle = [
      _stream?['church_name'],
      _stream?['host_name'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');

    return WorkflowPage(
      title: fhcT(context, 'homeChurch.onlineChurch', fallback: 'Online Church'),
      domain: WorkflowDomain.church,
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator.adaptive()),
          )
        else ...[
          WorkflowSummary(
            title: title,
            subtitle: subtitle.isEmpty
                ? fhcT(
                    context,
                    'homeChurch.welcomeOnlineChurchCopy',
                    fallback:
                        'Join live services and connect from anywhere in the world.',
                  )
                : subtitle,
            metrics: [
              if (status.isNotEmpty) ('Status', status.toUpperCase()),
            ],
            imageAsset: 'assets/images/live_worship.png',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => fhcPush(context, FhcRoutes.live),
            child: Text(
              status == 'live'
                  ? fhcT(
                      context,
                      'homeChurch.joinLiveService',
                      fallback: 'Join Live Service',
                    )
                  : fhcT(
                      context,
                      'homeChurch.openLiveRoom',
                      fallback: 'Open live room',
                    ),
            ),
          ),
          if (_stream == null) ...[
            const SizedBox(height: 12),
            Text(
              fhcT(
                context,
                'online.noLiveNow',
                fallback:
                    'No live service is on air right now. Check sermons for recent messages.',
              ),
              style: const TextStyle(color: FhcColors.muted, fontSize: 12),
            ),
          ],
        ],
      ],
    );
  }
}

class AltarCallScreen extends StatelessWidget {
  const AltarCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(context, 'homeChurch.altarCall', fallback: 'Altar Call'),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(context, 'common.continue', fallback: 'Continue'),
      onAction: () => fhcPush(context, '/altar-call/submitted'),
      children: [
        WorkflowSummary(
          title: fhcT(
            context,
            'homeChurch.altarCallTitle',
            fallback: 'Surrender your life to Jesus Christ today',
          ),
          subtitle: fhcT(
            context,
            'homeChurch.altarCallSubtitle',
            fallback: 'He is calling you.  •  Romans 10:13',
          ),
          metrics: const [],
          imageAsset: 'assets/images/prayer_hero.png',
        ),
        WorkflowSectionTitle(
          fhcT(
            context,
            'homeChurch.selectDecision',
            fallback: 'Select your decision',
          ),
        ),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.giveLifeToChrist',
                  fallback: 'I want to give my life to Christ',
                ),
                leading: Icons.radio_button_checked,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.rededicateLife',
                  fallback: 'I want to rededicate my life',
                ),
                leading: Icons.radio_button_off,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.joinThisChurch',
                  fallback: 'I want to join this church',
                ),
                leading: Icons.group_add_outlined,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.serveGod',
                  fallback: 'I want to serve God',
                ),
                leading: Icons.volunteer_activism_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AltarCallSubmittedScreen extends StatelessWidget {
  const AltarCallSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(
        context,
        'homeChurch.altarCallSubmission',
        fallback: 'Altar Call Submission',
      ),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(context, 'common.done', fallback: 'Done'),
      onAction: () => fhcGo(context, FhcRoutes.churchHome),
      children: [
        const SizedBox(height: 12),
        const Center(
          child: Icon(Icons.check_circle, size: 76, color: FhcColors.green),
        ),
        const SizedBox(height: 14),
        Text(
          fhcT(
            context,
            'homeChurch.thankYouDecision',
            fallback: 'Thank you for your decision!',
          ),
          textAlign: TextAlign.center,
          style: FhcTypography.title,
        ),
        const SizedBox(height: 8),
        Text(
          fhcT(
            context,
            'homeChurch.rejoiceWithYou',
            fallback:
                'We rejoice with you. A minister will reach out to you shortly.',
          ),
          textAlign: TextAlign.center,
          style: FhcTypography.body,
        ),
        WorkflowSectionTitle(
          fhcT(
            context,
            'homeChurch.whatHappensNext',
            fallback: 'What happens next?',
          ),
        ),
        WorkflowCard(
          child: Column(
            children: [
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.ministerWillContact',
                  fallback: 'A minister will contact you',
                ),
                leading: Icons.phone_outlined,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.discipleshipResources',
                  fallback: 'You will receive discipleship resources',
                ),
                leading: Icons.menu_book_outlined,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.welcomeSessionInvite',
                  fallback: 'You will be invited to a welcome session',
                ),
                leading: Icons.groups_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AltarCallFollowupsScreen extends StatelessWidget {
  const AltarCallFollowupsScreen({super.key});

  static String _followupStatus(BuildContext context, String status) {
    return switch (status) {
      'Contacted' => fhcT(
        context,
        'homeChurch.statusContacted',
        fallback: 'Contacted',
      ),
      'Follow-up' => fhcT(
        context,
        'homeChurch.statusFollowUp',
        fallback: 'Follow-up',
      ),
      'Discipleship' => fhcT(
        context,
        'homeChurch.statusDiscipleship',
        fallback: 'Discipleship',
      ),
      'Welcome' => fhcT(
        context,
        'homeChurch.statusWelcome',
        fallback: 'Welcome',
      ),
      _ => status,
    };
  }

  static String _decidedLabel(BuildContext context, String decided) {
    return switch (decided) {
      'Decided on May 16, 2025' => fhcT(
        context,
        'homeChurch.decidedMay16',
        fallback: 'Decided on May 16, 2025',
      ),
      'Decided on May 15, 2025' => fhcT(
        context,
        'homeChurch.decidedMay15',
        fallback: 'Decided on May 15, 2025',
      ),
      'Decided on May 14, 2025' => fhcT(
        context,
        'homeChurch.decidedMay14',
        fallback: 'Decided on May 14, 2025',
      ),
      'Decided on May 13, 2025' => fhcT(
        context,
        'homeChurch.decidedMay13',
        fallback: 'Decided on May 13, 2025',
      ),
      _ => decided,
    };
  }

  @override
  Widget build(BuildContext context) {
    const converts = [
      ('John Emmanuel', 'Decided on May 16, 2025', 'Contacted'),
      ('Glory Samuel', 'Decided on May 15, 2025', 'Follow-up'),
      ('Mercy John', 'Decided on May 14, 2025', 'Discipleship'),
      ('David Okoro', 'Decided on May 13, 2025', 'Welcome'),
    ];
    return WorkflowPage(
      title: fhcT(
        context,
        'homeChurch.altarCallFollowUp',
        fallback: 'Altar Call Follow-up',
      ),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(
        context,
        'homeChurch.addFollowUp',
        fallback: 'Add Follow-up',
      ),
      children: [
        WorkflowSegments(
          labels: [
            fhcT(
              context,
              'homeChurch.myFollowUps',
              fallback: 'My Follow-ups',
            ),
            fhcT(
              context,
              'homeChurch.allNewConverts',
              fallback: 'All New Converts',
            ),
          ],
        ),
        const SizedBox(height: 10),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (final convert in converts)
                WorkflowRow(
                  title: convert.$1,
                  subtitle: _decidedLabel(context, convert.$2),
                  leading: Icons.person_outline,
                  trailing: WorkflowPill(_followupStatus(context, convert.$3)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class CounselingRequestScreen extends StatelessWidget {
  const CounselingRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(
        context,
        'homeChurch.counselingRequest',
        fallback: 'Counseling Request',
      ),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(
        context,
        'homeChurch.submitRequest',
        fallback: 'Submit Request',
      ),
      children: [
        WorkflowSummary(
          title: fhcT(
            context,
            'homeChurch.weAreHereForYou',
            fallback: 'We are here for you',
          ),
          subtitle: fhcT(
            context,
            'homeChurch.counselingCopy',
            fallback: "Let's talk and find the help you need.",
          ),
          metrics: const [],
          imageAsset: 'assets/images/connect_people.png',
        ),
        const SizedBox(height: 14),
        WorkflowField(
          label: fhcT(
            context,
            'homeChurch.counselingType',
            fallback: 'Counseling Type',
          ),
          value: fhcT(
            context,
            'homeChurch.personalEmotional',
            fallback: 'Personal & Emotional',
          ),
          required: true,
          icon: Icons.keyboard_arrow_down,
        ),
        WorkflowField(
          label: fhcT(
            context,
            'homeChurch.preferredDate',
            fallback: 'Preferred Date',
          ),
          value: fhcT(context, 'homeChurch.may27_2025', fallback: 'May 27, 2025'),
          required: true,
          icon: Icons.calendar_today_outlined,
        ),
        WorkflowField(
          label: fhcT(
            context,
            'homeChurch.preferredTime',
            fallback: 'Preferred Time',
          ),
          value: fhcT(context, 'homeChurch.tenAm', fallback: '10:00 AM'),
          required: true,
          icon: Icons.keyboard_arrow_down,
        ),
        WorkflowField(
          label: fhcT(
            context,
            'homeChurch.briefDescription',
            fallback: 'Brief Description',
          ),
          value: fhcT(
            context,
            'homeChurch.counselingDescriptionValue',
            fallback: 'I need guidance on handling stress and anxiety.',
          ),
          lines: 4,
          required: true,
        ),
      ],
    );
  }
}

class TestimonySubmissionScreen extends StatelessWidget {
  const TestimonySubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(
        context,
        'homeChurch.shareYourTestimony',
        fallback: 'Share Your Testimony',
      ),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(
        context,
        'homeChurch.submitTestimony',
        fallback: 'Submit Testimony',
      ),
      children: [
        WorkflowSummary(
          title: fhcT(
            context,
            'homeChurch.giveGloryToGod',
            fallback: 'Give glory to God!',
          ),
          subtitle: fhcT(
            context,
            'homeChurch.testimonyCopy',
            fallback: 'Share how God has been faithful.',
          ),
          metrics: const [],
          imageAsset: 'assets/images/prayer_answered_church.png',
        ),
        const SizedBox(height: 14),
        WorkflowField(
          label: fhcT(context, 'homeChurch.title', fallback: 'Title'),
          value: fhcT(
            context,
            'homeChurch.testimonyTitleValue',
            fallback: 'God Provided in a Miracle Way',
          ),
          required: true,
        ),
        WorkflowField(
          label: fhcT(context, 'homeChurch.category', fallback: 'Category'),
          value: fhcT(
            context,
            'homeChurch.financialBreakthrough',
            fallback: 'Financial Breakthrough',
          ),
          required: true,
          icon: Icons.keyboard_arrow_down,
        ),
        WorkflowField(
          label: fhcT(
            context,
            'homeChurch.yourTestimony',
            fallback: 'Your Testimony',
          ),
          value: fhcT(
            context,
            'homeChurch.testimonyBodyValue',
            fallback:
                'I had no money to pay my rent, but God sent help through a brother in church at the right time. Praise God!',
          ),
          lines: 5,
          required: true,
        ),
        WorkflowUploadBox(
          label: fhcT(
            context,
            'homeChurch.addPhotosOptional',
            fallback: 'Add photos (Optional)',
          ),
        ),
      ],
    );
  }
}

class LeadershipDashboardScreen extends StatelessWidget {
  const LeadershipDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(
        context,
        'homeChurch.leadershipDashboard',
        fallback: 'Leadership Dashboard',
      ),
      domain: WorkflowDomain.church,
      showBack: false,
      children: [
        WorkflowSummary(
          title: fhcT(
            context,
            'homeChurch.kingdomOverviewMay2025',
            fallback: 'Kingdom Overview  •  May 2025',
          ),
          metrics: [
            (
              '128',
              fhcT(context, 'homeChurch.churches', fallback: 'Churches'),
            ),
            (
              '2,458',
              fhcT(context, 'homeChurch.membersLabel', fallback: 'Members'),
            ),
            ('1,245', fhcT(context, 'homeChurch.kca', fallback: 'KCA')),
            ('8,765', fhcT(context, 'homeChurch.souls', fallback: 'Souls')),
          ],
        ),
        WorkflowSectionTitle(
          fhcT(context, 'homeChurch.approvals', fallback: 'Approvals'),
        ),
        WorkflowCard(
          child: Column(
            children: [
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.homeChurchApplications',
                  fallback: 'Home Church Applications',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.pending12',
                  fallback: '12 Pending',
                ),
                leading: Icons.home_work_outlined,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.kcaCertifications',
                  fallback: 'KCA Certifications',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.pending8',
                  fallback: '8 Pending',
                ),
                leading: Icons.workspace_premium_outlined,
              ),
            ],
          ),
        ),
        WorkflowSectionTitle(
          fhcT(context, 'homeChurch.alerts', fallback: 'Alerts'),
        ),
        WorkflowCard(
          child: Column(
            children: [
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.missionReportOverdue',
                  fallback: 'Mission Report Overdue',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.reportsRequireAttention',
                  fallback: '5 reports require attention',
                ),
                leading: Icons.warning_amber_outlined,
                accent: FhcColors.red,
              ),
              WorkflowRow(
                title: fhcT(
                  context,
                  'homeChurch.newSoulFollowUp',
                  fallback: 'New Soul Follow-up',
                ),
                subtitle: fhcT(
                  context,
                  'homeChurch.pendingAssignments18',
                  fallback: '18 pending assignments',
                ),
                leading: Icons.person_add_alt_1_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RecordAttendanceScreen extends StatelessWidget {
  const RecordAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(
        context,
        'homeChurch.recordAttendance',
        fallback: 'Record Attendance',
      ),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(
        context,
        'homeChurch.saveAttendance',
        fallback: 'Save Attendance',
      ),
      children: [
        WorkflowCard(
          child: WorkflowRow(
            title: fhcT(
              context,
              'homeChurch.sundayService',
              fallback: 'Sunday Service',
            ),
            subtitle: fhcT(
              context,
              'homeChurch.sundayServiceMeta',
              fallback: 'May 18, 2025 • 9:00 AM • The Garden House',
            ),
            leading: Icons.radio_button_checked,
          ),
        ),
        const SizedBox(height: 12),
        WorkflowSummary(
          title: fhcT(
            context,
            'homeChurch.attendanceSummary',
            fallback: 'Attendance Summary',
          ),
          metrics: [
            ('126', fhcT(context, 'homeChurch.present', fallback: 'Present')),
            ('12', fhcT(context, 'homeChurch.visitors', fallback: 'Visitors')),
            ('138', fhcT(context, 'homeChurch.total', fallback: 'Total')),
          ],
        ),
        WorkflowSectionTitle(
          fhcT(context, 'homeChurch.method', fallback: 'Method'),
        ),
        WorkflowSegments(
          labels: [
            fhcT(context, 'homeChurch.manualEntry', fallback: 'Manual Entry'),
            fhcT(context, 'homeChurch.qrScan', fallback: 'QR Scan'),
          ],
        ),
        WorkflowSectionTitle(
          fhcT(context, 'homeChurch.addAttendees', fallback: 'Add Attendees'),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    () => fhcApiUnavailable(
                      context,
                      action: fhcT(
                        context,
                        'homeChurch.addAttendeeManuallyAction',
                        fallback: 'Adding an attendee manually',
                      ),
                    ),
                icon: const Icon(Icons.person_add_alt),
                label: Text(
                  fhcT(
                    context,
                    'homeChurch.addManually',
                    fallback: 'Add Manually',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    () => fhcApiUnavailable(
                      context,
                      action: fhcT(
                        context,
                        'homeChurch.scanAttendanceQrAction',
                        fallback: 'Scanning an attendance QR code',
                      ),
                    ),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(
                  fhcT(
                    context,
                    'homeChurch.scanQrCode',
                    fallback: 'Scan QR Code',
                  ),
                ),
              ),
            ),
          ],
        ),
        WorkflowSectionTitle(
          fhcT(
            context,
            'homeChurch.recentCheckIns',
            fallback: 'Recent Check-ins',
          ),
        ),
        const WorkflowCard(
          child: Column(
            children: [
              WorkflowRow(
                title: 'Jane Esther',
                subtitle: '9:02 AM',
                trailing: Icon(Icons.check, color: FhcColors.green),
              ),
              WorkflowRow(
                title: 'Michael Eze',
                subtitle: '9:03 AM',
                trailing: Icon(Icons.check, color: FhcColors.green),
              ),
              WorkflowRow(
                title: 'Grace Okafor',
                subtitle: '9:03 AM',
                trailing: Icon(Icons.check, color: FhcColors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

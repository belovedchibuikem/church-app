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
import '../../data/kca_repository.dart';

class KcaEvidenceUploadScreen extends StatelessWidget {
  const KcaEvidenceUploadScreen({super.key});

  Future<void> _submit(BuildContext context) async {
    final repo = AppServicesScope.maybeOf(context)?.kcaRepository;
    if (repo != null) {
      final result = await repo.submitEvidence(const <String, Object?>{});
      if (!context.mounted) return;
      if (result case AppError(:final failure)) {
        await fhcApiUnavailable(
          context,
          action: failure.message,
        );
        return;
      }
    }
    if (!context.mounted) return;
    await fhcApiUnavailable(
      context,
      action: 'Submitting KCA evidence',
    );
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Upload Evidence',
      domain: WorkflowDomain.kca,
      actionLabel: 'Upload Evidence',
      onAction: () => _submit(context),
      children: const [
        WorkflowCard(
          color: Color(0xFFEAF4EF),
          child: Row(
            children: [
              Icon(Icons.verified_outlined, color: FhcColors.green),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload photos, videos or documents that show your kingdom impact.',
                  style: TextStyle(fontSize: 11, color: FhcColors.greenDark),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        WorkflowField(
          label: 'Activity Type',
          value: 'Select activity type',
          required: true,
          icon: Icons.keyboard_arrow_down,
        ),
        WorkflowField(
          label: 'Description',
          value: 'Tell us what happened...',
          lines: 4,
          required: true,
        ),
        WorkflowUploadBox(),
      ],
    );
  }
}

class KcaSubmissionsScreen extends StatelessWidget {
  const KcaSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Door to Door Evangelism', 'Submitted May 18, 2025', 'Under Review'),
      ('Youth Outreach Program', 'Submitted May 17, 2025', 'Under Review'),
      ('Community Clean Up', 'Submitted May 10, 2025', 'Approved'),
      ('Food Distribution', 'Submitted May 8, 2025', 'Approved'),
      ('Prison Outreach', 'Submitted May 3, 2025', 'Rejected'),
    ];
    return WorkflowPage(
      title: 'My Submissions',
      domain: WorkflowDomain.kca,
      children: [
        const WorkflowSegments(
          labels: ['Under Review (2)', 'Approved (4)', 'Rejected (1)'],
        ),
        const SizedBox(height: 10),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (final item in items)
                WorkflowRow(
                  title: item.$1,
                  subtitle: item.$2,
                  leading: Icons.assignment_outlined,
                  trailing: WorkflowPill(
                    item.$3,
                    color:
                        item.$3 == 'Rejected'
                            ? FhcColors.red
                            : item.$3 == 'Approved'
                            ? FhcColors.green
                            : FhcColors.gold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class KcaCertificationProgressScreen extends StatelessWidget {
  const KcaCertificationProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Certification Progress',
      domain: WorkflowDomain.kca,
      actionLabel: 'View All Requirements',
      children: const [
        WorkflowSummary(
          title: 'Level 2',
          subtitle: 'Kingdom Change Agent\nYou are 60% to Level 3',
          metrics: [('60%', 'Progress')],
        ),
        WorkflowSectionTitle('Requirements'),
        WorkflowCard(
          child: Column(
            children: [
              WorkflowProgress(
                label: 'Impact Activities',
                value: .60,
                trailing: '12 / 20',
              ),
              WorkflowProgress(
                label: 'Lives Discipled',
                value: .30,
                trailing: '3 / 10',
              ),
              WorkflowProgress(
                label: 'Training Completed',
                value: .66,
                trailing: '2 / 3',
              ),
              WorkflowProgress(
                label: 'Evidence Approved',
                value: .40,
                trailing: '4 / 10',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class KcaAdmissionStatusScreen extends StatelessWidget {
  const KcaAdmissionStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Admission Status',
      domain: WorkflowDomain.kca,
      actionLabel: 'View Details',
      children: [
        const WorkflowSegments(labels: ['1', '2', '3', '4']),
        const WorkflowSectionTitle('Application ID'),
        const WorkflowCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KCA-2025-00156', style: FhcTypography.titleSmall),
                    Text(
                      'Submitted on May 15, 2025',
                      style: FhcTypography.caption,
                    ),
                  ],
                ),
              ),
              WorkflowPill('Admitted'),
            ],
          ),
        ),
        const WorkflowSectionTitle('Status Progress'),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: const [
              WorkflowRow(
                title: 'Application Received',
                subtitle: 'May 15, 2025',
                leading: Icons.check_circle,
                trailing: WorkflowPill('Done'),
              ),
              WorkflowRow(
                title: 'Under Review',
                subtitle: 'May 16 - May 18, 2025',
                leading: Icons.check_circle,
                trailing: WorkflowPill('Done'),
              ),
              WorkflowRow(
                title: 'Admitted',
                subtitle: 'May 19, 2025',
                leading: Icons.check_circle,
                trailing: WorkflowPill('Done'),
              ),
              WorkflowRow(
                title: 'Orientation',
                subtitle: 'Pending',
                leading: Icons.radio_button_unchecked,
                trailing: SizedBox.shrink(),
              ),
              WorkflowRow(
                title: 'Enrolled',
                subtitle: 'Pending',
                leading: Icons.radio_button_unchecked,
                trailing: SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class KcaAttendanceScreen extends StatefulWidget {
  const KcaAttendanceScreen({super.key, this.kcaRepository});

  final KcaRepository? kcaRepository;

  @override
  State<KcaAttendanceScreen> createState() => _KcaAttendanceScreenState();
}

class _KcaAttendanceScreenState extends State<KcaAttendanceScreen> {
  FhcAsyncValue<List<_AttendanceRow>> _state = const FhcAsyncValue.loading();

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
        _state = const FhcAsyncValue.unavailable(
          message:
              'KCA attendance requires the member curriculum API. '
              'No design fixtures are shown.',
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.listAttendance();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _state = const FhcAsyncValue.empty(
              message:
                  'No attendance sessions are recorded for your enrollment yet.',
            );
          });
          return;
        }
        setState(() {
          _state = FhcAsyncValue.data([
            for (final item in value) _AttendanceRow.fromJson(item),
          ]);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      switch (_state) {
        FhcAsyncLoading() => const SizedBox(
          height: 180,
          child: FhcLoadingState(),
        ),
        FhcAsyncUnavailable(:final message) => FhcUnavailableState(
          title: 'Attendance unavailable',
          message:
              message ??
              'KCA attendance requires the member curriculum API.',
        ),
        FhcAsyncEmpty(:final message) => FhcEmptyState(
          title: 'No attendance yet',
          message:
              message ??
              'No attendance sessions are recorded for your enrollment yet.',
        ),
        FhcAsyncError(:final failure) => FhcErrorState(
          title: fhcT(
            context,
            'errors.somethingWentWrong',
            fallback: 'Something went wrong',
          ),
          message: failure.message,
          onRetry: _load,
        ),
        FhcAsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkflowSummary(
              title: 'Your enrollment',
              metrics: [
                (
                  '${value.where((r) => r.status.toLowerCase().contains('present')).length}',
                  'Present',
                ),
                (
                  '${value.where((r) => r.status.toLowerCase().contains('absent')).length}',
                  'Absent',
                ),
                (
                  '${value.isEmpty ? 0 : ((value.where((r) => r.status.toLowerCase().contains('present')).length / value.length) * 100).round()}%',
                  'Rate',
                ),
              ],
            ),
            const WorkflowSectionTitle('Sessions'),
            WorkflowCard(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (final row in value)
                    WorkflowRow(
                      title: row.sessionLabel,
                      subtitle: row.lessonLabel,
                      leading:
                          row.status.toLowerCase().contains('absent')
                              ? Icons.event_busy_outlined
                              : Icons.event_available_outlined,
                      trailing: WorkflowPill(
                        row.statusLabel,
                        color:
                            row.status.toLowerCase().contains('absent')
                                ? FhcColors.red
                                : FhcColors.green,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      },
    ];

    return WorkflowPage(
      title: 'Attendance',
      domain: WorkflowDomain.kca,
      children: children,
    );
  }
}

class _AttendanceRow {
  const _AttendanceRow({
    required this.sessionLabel,
    required this.lessonLabel,
    required this.status,
    required this.statusLabel,
  });

  factory _AttendanceRow.fromJson(Map<String, Object?> json) {
    final status = '${json['status'] ?? 'recorded'}';
    final lesson = json['lesson'];
    final lessonLabel =
        lesson is Map
            ? '${lesson['title'] ?? lesson['code'] ?? 'Lesson'}'
            : 'Session';
    final sessionOn = json['session_on'] ?? json['recorded_at'] ?? 'Session';
    return _AttendanceRow(
      sessionLabel: '$sessionOn',
      lessonLabel: lessonLabel,
      status: status,
      statusLabel:
          status.isEmpty
              ? 'Recorded'
              : '${status[0].toUpperCase()}${status.substring(1)}',
    );
  }

  final String sessionLabel;
  final String lessonLabel;
  final String status;
  final String statusLabel;
}

class KcaMenteesScreen extends StatelessWidget {
  const KcaMenteesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const mentees = [
      ('Jane Esther', 'New Convert', .70),
      ('Michael Bassey', 'Level 1 Student', .60),
      ('Glory Samuel', 'Level 1 Student', .40),
      ('David Okoro', 'Level 2 Student', .80),
      ('Mercy John', 'Level 1 Student', .50),
    ];
    return WorkflowPage(
      title: 'My Mentees',
      domain: WorkflowDomain.kca,
      actionLabel: 'View All Mentees',
      children: [
        const WorkflowSummary(
          title: 'Mentor Overview',
          metrics: [('18', 'Total Mentees'), ('15', 'Active')],
        ),
        const SizedBox(height: 10),
        for (final mentee in mentees)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WorkflowCard(
              child: Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person_outline)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentee.$1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(mentee.$2, style: FhcTypography.caption),
                        WorkflowProgress(label: 'Progress', value: mentee.$3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class KcaMentorReviewScreen extends StatelessWidget {
  const KcaMentorReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Review Evidence',
      domain: WorkflowDomain.kca,
      actionLabel: 'Submit Review',
      onAction:
          () => fhcApiUnavailable(
            context,
            action: 'Submitting a KCA evidence review (OD-008)',
          ),
      children: const [
        WorkflowCard(
          child: WorkflowRow(
            title: 'Michael Bassey',
            subtitle: 'Level 1 Student',
            leading: Icons.person_outline,
            trailing: SizedBox.shrink(),
          ),
        ),
        WorkflowSectionTitle('Submission'),
        WorkflowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kingdom Impact Assignment',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text('Submitted: May 18, 2025', style: FhcTypography.caption),
            ],
          ),
        ),
        WorkflowSectionTitle('Evidence'),
        WorkflowSummary(
          title: '3 evidence photos uploaded',
          subtitle: 'Community outreach and discipleship activity',
          metrics: [],
          imageAsset: 'assets/images/crusade_crowd.png',
        ),
        WorkflowSectionTitle('Mentor Feedback'),
        WorkflowField(
          label: 'Feedback',
          value: 'Write your feedback...',
          lines: 4,
        ),
        WorkflowSegments(labels: ['Approve', 'Resubmit', 'Needs Attention']),
      ],
    );
  }
}

class KcaFinalAssessmentScreen extends StatelessWidget {
  const KcaFinalAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Final Assessment',
      domain: WorkflowDomain.kca,
      actionLabel: 'View Details',
      children: const [
        WorkflowCard(
          child: WorkflowRow(
            title: 'Grace Samuel',
            subtitle: 'Level 2 Student',
            leading: Icons.person_outline,
            trailing: SizedBox.shrink(),
          ),
        ),
        WorkflowSectionTitle('Assessment'),
        WorkflowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Final Examination',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: Text('Score', style: FhcTypography.caption)),
                  Text('85 / 100', style: FhcTypography.titleSmall),
                  SizedBox(width: 12),
                  WorkflowPill('Passed'),
                ],
              ),
            ],
          ),
        ),
        WorkflowSectionTitle('Feedback'),
        WorkflowCard(
          child: Text(
            "Well done! You've demonstrated good understanding and application of the principles.",
            style: FhcTypography.body,
          ),
        ),
        WorkflowSectionTitle('Assessed by'),
        WorkflowCard(
          child: WorkflowRow(
            title: 'Pastor Daniel',
            subtitle: 'May 20, 2025',
            leading: Icons.person_outline,
            trailing: SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class KcaCertificateScreen extends StatelessWidget {
  const KcaCertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Certificate',
      domain: WorkflowDomain.kca,
      actionLabel: 'Download Certificate',
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEE),
            border: Border.all(color: FhcColors.gold, width: 3),
          ),
          child: const Column(
            children: [
              Icon(Icons.workspace_premium, size: 54, color: FhcColors.gold),
              SizedBox(height: 12),
              Text(
                'FAMILY HOUSE CONNECT',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'KINGDOM CHANGE AGENT\nCERTIFICATE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.greenDark,
                ),
              ),
              SizedBox(height: 18),
              Text('This is to certify that'),
              SizedBox(height: 8),
              Text(
                'Grace Samuel',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'has successfully completed the\nKingdom Change Agent Training\nLevel 2',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18),
              Text(
                'May 20, 2025',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pastor Daniel\nLead Pastor',
                    textAlign: TextAlign.center,
                  ),
                  Icon(Icons.verified, size: 48, color: FhcColors.gold),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class KcaCertificateVerifyScreen extends StatefulWidget {
  const KcaCertificateVerifyScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<KcaCertificateVerifyScreen> createState() =>
      _KcaCertificateVerifyScreenState();
}

class _KcaCertificateVerifyScreenState
    extends State<KcaCertificateVerifyScreen> {
  late final TextEditingController _codeController;
  KcaRepository? _repository;

  bool _loading = false;
  bool? _verified;
  String? _message;
  Map<String, Object?>? _facts;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    if ((widget.initialCode ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository ??=
        AppServicesScope.maybeOf(context)?.kcaRepository ?? HttpKcaRepository();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _verified = false;
        _facts = null;
        _message = 'Enter a certificate verification code.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    final result = await (_repository ?? HttpKcaRepository()).verifyCertificate(
      code,
    );
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        final ok = value['verified'] == true;
        setState(() {
          _loading = false;
          _verified = ok;
          _facts = ok ? value : null;
          _message =
              ok
                  ? 'This certificate is valid.'
                  : 'This certificate could not be verified.';
        });
      case AppError(:final failure):
        setState(() {
          _loading = false;
          _verified = false;
          _facts = null;
          _message = failure.message;
        });
    }
  }

  void _reset() {
    setState(() {
      _codeController.clear();
      _verified = null;
      _facts = null;
      _message = null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final facts = _facts;
    final verified = _verified;

    return WorkflowPage(
      title: 'Verify Certificate',
      domain: WorkflowDomain.kca,
      actionLabel: verified == true ? 'Verify Another' : 'Verify Certificate',
      onAction: _loading
          ? () {}
          : (verified == true ? _reset : _verify),
      children: [
        WorkflowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verification code',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                enabled: !_loading && verified != true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verify(),
                decoration: const InputDecoration(
                  hintText: 'Paste or type the certificate code',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        if (_loading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator.adaptive()),
        ] else if (verified == true && facts != null) ...[
          const SizedBox(height: 14),
          const WorkflowSummary(
            title: 'Certificate is Valid',
            metrics: [],
            color: FhcColors.green,
          ),
          const WorkflowSectionTitle('Certificate Details'),
          WorkflowCard(
            child: Column(
              children: [
                WorkflowRow(
                  title: 'Certificate No.',
                  subtitle: '${facts['certificate_number'] ?? '—'}',
                  leading: Icons.numbers_outlined,
                  trailing: const SizedBox.shrink(),
                ),
                WorkflowRow(
                  title: 'Completion Date',
                  subtitle: '${facts['completion_on'] ?? '—'}',
                  leading: Icons.calendar_today_outlined,
                  trailing: const SizedBox.shrink(),
                ),
                WorkflowRow(
                  title: 'Issued At',
                  subtitle: '${facts['issued_at'] ?? '—'}',
                  leading: Icons.verified_outlined,
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            Center(child: Text(_message!, style: FhcTypography.caption)),
          ],
        ] else if (verified == false) ...[
          const SizedBox(height: 14),
          WorkflowSummary(
            title: 'Certificate Not Verified',
            subtitle: _message ?? 'The code did not match a valid certificate.',
            metrics: const [],
            color: FhcColors.red,
          ),
        ],
      ],
    );
  }
}

class KcaAlumniDirectoryScreen extends StatefulWidget {
  const KcaAlumniDirectoryScreen({super.key, this.dashboard = false});

  final bool dashboard;

  @override
  State<KcaAlumniDirectoryScreen> createState() =>
      _KcaAlumniDirectoryScreenState();
}

class _KcaAlumniDirectoryScreenState extends State<KcaAlumniDirectoryScreen> {
  final _search = TextEditingController();
  FhcAsyncValue<List<JsonObject>> _state = const FhcAsyncValue.loading();
  final Set<String> _following = {};
  String? _busyId;

  KcaRepository? get _repo =>
      AppServicesScope.maybeOf(context)?.kcaRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message:
              'KCA directory requires the authenticated directory API. '
              'No fixture alumni list is shown.',
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final following = await repo.listFollowing();
    if (following case AppSuccess(:final value)) {
      _following
        ..clear()
        ..addAll(
          value.map((p) => '${p['id'] ?? p['person_id'] ?? ''}').where(
            (id) => id.isNotEmpty,
          ),
        );
    }

    final q = _search.text.trim();
    final result = await repo.listDirectory({
      if (q.isNotEmpty) 'q': q,
    });
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _state = value.isEmpty
              ? const FhcAsyncValue.empty(message: 'No people found.')
              : FhcAsyncValue.data(value);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  String _name(JsonObject person) {
    final preferred = '${person['preferred_name'] ?? ''}'.trim();
    final given = '${person['given_name'] ?? ''}'.trim();
    final family = '${person['family_name'] ?? ''}'.trim();
    final display = '${person['display_name'] ?? person['name'] ?? ''}'.trim();
    if (display.isNotEmpty) return display;
    final parts = [
      if (preferred.isNotEmpty) preferred,
      if (preferred.isEmpty && given.isNotEmpty) given,
      if (family.isNotEmpty) family,
    ];
    return parts.isEmpty ? 'Member' : parts.join(' ');
  }

  String _subtitle(JsonObject person) {
    final level = '${person['level'] ?? person['kca_level'] ?? ''}'.trim();
    final place = '${person['locality'] ?? person['location'] ?? ''}'.trim();
    return [if (level.isNotEmpty) level, if (place.isNotEmpty) place]
        .join('  •  ');
  }

  Future<void> _toggleFollow(JsonObject person) async {
    final repo = _repo;
    final id = '${person['id'] ?? person['person_id'] ?? ''}'.trim();
    if (repo == null || id.isEmpty || _busyId != null) return;
    setState(() => _busyId = id);
    final following = _following.contains(id);
    final result =
        following ? await repo.unfollow(id) : await repo.follow(id);
    if (!mounted) return;
    setState(() => _busyId = null);
    switch (result) {
      case AppSuccess():
        setState(() {
          if (following) {
            _following.remove(id);
          } else {
            _following.add(id);
          }
        });
      case AppError(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: widget.dashboard ? 'Alumni' : 'KCA Alumni',
      domain: WorkflowDomain.kca,
      actionLabel: 'Refresh',
      onAction: _load,
      children: [
        if (!widget.dashboard) ...[
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'Search alumni…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 420,
          child: FhcAsyncBody<List<JsonObject>>(
            value: _state,
            onRetry: _load,
            emptyTitle: 'No directory results',
            unavailableTitle: 'Directory unavailable',
            builder: (context, people) {
              return ListView.separated(
                itemCount: people.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final person = people[index];
                  final id = '${person['id'] ?? person['person_id'] ?? ''}';
                  final following = _following.contains(id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: FhcColors.mint,
                      child: Icon(Icons.person_outline, color: FhcColors.green),
                    ),
                    title: Text(
                      _name(person),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _subtitle(person).isEmpty ? '—' : _subtitle(person),
                      style: FhcTypography.caption,
                    ),
                    trailing: TextButton(
                      onPressed: _busyId == id
                          ? null
                          : () => _toggleFollow(person),
                      child: Text(following ? 'Unfollow' : 'Follow'),
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

class KcaOpportunitiesScreen extends StatelessWidget {
  const KcaOpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const opportunities = [
      (
        'Children Outreach Project',
        'Support a children outreach in rural communities.',
        'Ongoing',
      ),
      (
        'Bible Study Facilitator',
        'Help facilitate online Bible studies.',
        'Apply',
      ),
      (
        'Community Development',
        'Join a community development initiative.',
        'Apply',
      ),
      (
        'Media Volunteer',
        'Help in media production and digital outreach.',
        'Apply',
      ),
    ];
    return WorkflowPage(
      title: 'Opportunities',
      domain: WorkflowDomain.kca,
      actionLabel: 'View All Opportunities',
      children: [
        const WorkflowSegments(
          labels: ['Projects', 'Mentorship', 'Volunteers', 'Jobs'],
        ),
        const SizedBox(height: 10),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (final item in opportunities)
                WorkflowRow(
                  title: item.$1,
                  subtitle: item.$2,
                  leading: Icons.work_outline,
                  trailing: WorkflowPill(item.$3),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

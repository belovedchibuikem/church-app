import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/geography_select.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/kca_enrolment_draft_store.dart';

enum KcaLifecycleKind {
  churchInfo,
  walkWithChrist,
  whyJoin,
  interests,
  commitments,
  personalCommitment,
  guardianConsent,
  recommendation,
  applicationReview,
  admissionLetter,
  orientation,
  practicalService,
  writtenAssessments,
  spiritualAssignment,
  selfReview,
  administratorReview,
  lockedModule,
  physicalAssignment,
  mentorDashboard,
  lecturerWorkspace,
  mentorIntervention,
  admissionDecision,
}

class KcaLifecycleScreen extends StatefulWidget {
  const KcaLifecycleScreen({super.key, required this.kind});

  final KcaLifecycleKind kind;

  @override
  State<KcaLifecycleScreen> createState() => _KcaLifecycleScreenState();
}

class _KcaLifecycleScreenState extends State<KcaLifecycleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _draft = KcaEnrolmentDraftStore();
  final Map<String, TextEditingController> _controllers = {};
  bool _submitting = false;
  bool _hydrated = false;
  bool _fieldsReady = false;
  bool _letterLoading = false;
  bool _letterDownloading = false;
  bool _letterAccepting = false;
  bool _letterAcceptConfirmed = false;
  Map<String, Object?>? _admissionLetter;
  int _choiceIndex = 0;
  final Set<int> _checked = {};
  final Set<int> _interests = {};

  KcaLifecycleKind get kind => widget.kind;

  bool get _isEnrolmentStep => switch (kind) {
        KcaLifecycleKind.churchInfo ||
        KcaLifecycleKind.walkWithChrist ||
        KcaLifecycleKind.whyJoin ||
        KcaLifecycleKind.interests ||
        KcaLifecycleKind.commitments ||
        KcaLifecycleKind.personalCommitment ||
        KcaLifecycleKind.guardianConsent ||
        KcaLifecycleKind.recommendation =>
          true,
        _ => false,
      };

  int? get _enrolmentStep => switch (kind) {
        KcaLifecycleKind.churchInfo => 1,
        KcaLifecycleKind.walkWithChrist => 2,
        KcaLifecycleKind.whyJoin => 3,
        KcaLifecycleKind.interests => 4,
        KcaLifecycleKind.commitments => 5,
        KcaLifecycleKind.personalCommitment => 6,
        KcaLifecycleKind.guardianConsent => 7,
        KcaLifecycleKind.recommendation => 8,
        _ => null,
      };

  TextEditingController _c(String key, [String initial = '']) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: initial),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hydrated && _isEnrolmentStep) {
      _hydrated = true;
      _hydrate();
    }
    if (kind == KcaLifecycleKind.admissionLetter && _admissionLetter == null && !_letterLoading) {
      _letterLoading = true;
      _loadAdmissionLetter();
    }
  }

  Future<void> _loadAdmissionLetter() async {
    final repo = AppServicesScope.maybeOf(context)?.kcaRepository;
    if (repo == null) {
      if (mounted) setState(() => _letterLoading = false);
      return;
    }
    final result = await repo.getAdmissionLetter();
    if (!mounted) return;
    setState(() {
      _letterLoading = false;
      if (result case AppSuccess(:final value)) {
        _admissionLetter = value;
        final applicantName = '${value['applicant_name'] ?? ''}'.trim();
        if (applicantName.isNotEmpty) {
          _c('letter_signature', applicantName);
        }
      }
    });
  }

  Future<void> _acceptAdmissionLetter() async {
    if (_letterAccepting || _admissionLetter == null) return;
    if (!_letterAcceptConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'member.kca.acceptanceRequired',
              fallback: 'Please confirm that you have read and accept the admission letter.',
            ),
          ),
        ),
      );
      return;
    }

    final signature = _c('letter_signature').text.trim();
    if (signature.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'member.kca.signatureRequired',
              fallback: 'Please type your signature.',
            ),
          ),
        ),
      );
      return;
    }

    final repo = AppServicesScope.maybeOf(context)?.kcaRepository;
    if (repo == null) return;

    setState(() => _letterAccepting = true);
    final body = <String, Object?>{
      'applicant_signature_name': signature,
    };
    final requiresGuardian = _admissionLetter?['requires_guardian_confirmation'] == true;
    if (requiresGuardian) {
      final guardianName = _c('letter_guardian_name').text.trim();
      final guardianSignature = _c('letter_guardian_signature').text.trim();
      final guardianPhone = _c('letter_guardian_phone').text.trim();
      if (guardianName.isNotEmpty) body['guardian_name'] = guardianName;
      if (guardianSignature.isNotEmpty) {
        body['guardian_signature_name'] = guardianSignature;
      }
      if (guardianPhone.isNotEmpty) body['guardian_phone'] = guardianPhone;
    }

    final result = await repo.acceptAdmissionLetter(body);
    if (!mounted) return;
    setState(() => _letterAccepting = false);
    switch (result) {
      case AppSuccess(:final value):
        setState(() => _admissionLetter = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fhcT(
                context,
                'member.kca.letterAccepted',
                fallback: 'Admission letter accepted.',
              ),
            ),
          ),
        );
      case AppError(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  Future<void> _hydrate() async {
    final step = _enrolmentStep;
    if (step == null) {
      if (mounted) setState(() => _fieldsReady = true);
      return;
    }

    final repo = AppServicesScope.maybeOf(context)?.kcaRepository;
    if (repo != null) {
      final current = await repo.getCurrentApplication();
      if (current case AppSuccess(:final value)) {
        final data = value['application_data'];
        if (data is Map) {
          await _draft.hydrateFromApplicationData(
            Map<String, Object?>.from(
              data.map((k, v) => MapEntry('$k', v)),
            ),
          );
        } else if (value.isNotEmpty) {
          await _draft.hydrateFromApplicationData(value);
        }
      }
    }

    final fields = await _draft.loadStep(step);
    if (!mounted) return;
    setState(() {
      for (final entry in fields.entries) {
        _c(entry.key).text = entry.value;
      }
      final choice = int.tryParse(fields['choice_index'] ?? '');
      if (choice != null) _choiceIndex = choice;
      final checked = fields['checked_indexes'];
      if (checked != null && checked.isNotEmpty) {
        _checked
          ..clear()
          ..addAll(
            checked.split(',').map(int.tryParse).whereType<int>(),
          );
      }
      final interests = fields['interest_indexes'];
      if (interests != null && interests.isNotEmpty) {
        _interests
          ..clear()
          ..addAll(
            interests.split(',').map(int.tryParse).whereType<int>(),
          );
      }
      _fieldsReady = true;
    });
  }

  Map<String, String> _collectStepFields() {
    final fields = <String, String>{
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
    };
    fields['choice_index'] = '$_choiceIndex';
    fields['checked_indexes'] = (_checked.toList()..sort()).join(',');
    fields['interest_indexes'] = (_interests.toList()..sort()).join(',');
    return fields;
  }

  Future<void> _persistDraft({bool pushServer = false}) async {
    final step = _enrolmentStep;
    if (step == null) return;
    final fields = _collectStepFields();
    await _draft.saveStep(step, fields);

    if (!pushServer) return;
    if (!mounted) return;
    final repo = AppServicesScope.maybeOf(context)?.kcaRepository;
    if (repo == null) return;
    final all = await _draft.loadAll();
    await repo.submitApplication(
      <String, Object?>{...all, 'source': 'mobile_enrolment_wizard'},
      finalize: false,
    );
  }

  @override
  void dispose() {
    if (_isEnrolmentStep) {
      // Best-effort local save; ignore async result.
      final step = _enrolmentStep;
      if (step != null) {
        _draft.saveStep(step, _collectStepFields());
      }
    }
    for (final c in _controllers.values) {
      c.dispose();
    }
    _draft.dispose();
    super.dispose();
  }

  Future<void> _handleAction(_KcaSpec spec) async {
    if (kind == KcaLifecycleKind.admissionLetter) {
      await _handleAdmissionLetterAction(spec);
      return;
    }

    if (spec.next == null) return;

    if (_isEnrolmentStep) {
      final fixtures =
          AppServicesScope.maybeOf(context)?.showUnboundFixtures ?? false;
      final form = _formKey.currentState;
      if (!fixtures && form != null && !form.validate()) return;
      await _persistDraft(pushServer: kind != KcaLifecycleKind.recommendation);
      if (!mounted) return;
    }

    if (kind == KcaLifecycleKind.recommendation) {
      if (_submitting) return;
      final repo = AppServicesScope.maybeOf(context)?.kcaRepository;
      if (repo == null) {
        await fhcApiUnavailable(
          context,
          action: fhcT(
            context,
            'member.kca.submitApplication',
            fallback: 'Submit Application',
          ),
        );
        return;
      }

      setState(() => _submitting = true);
      final all = await _draft.loadAll();
      if (!mounted) return;
      final result = await repo.submitApplication(
        <String, Object?>{
          ...all,
          'source': 'mobile_enrolment_wizard',
          'steps_completed': '8',
          'channel': 'flutter',
          'submitted_at': DateTime.now().toUtc().toIso8601String(),
        },
        finalize: true,
      );
      if (!mounted) return;
      setState(() => _submitting = false);

      switch (result) {
        case AppSuccess():
          await _draft.clear();
          if (!mounted) return;
          fhcPush(context, spec.next!);
        case AppError(:final failure):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
      }
      return;
    }

    fhcPush(context, spec.next!);
  }

  Future<void> _handleAdmissionLetterAction(_KcaSpec spec) async {
    if (_admissionLetter == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'member.kca.letterPending',
              fallback: 'Your admission letter is being prepared by KCA administration.',
            ),
          ),
        ),
      );
      return;
    }

    final accepted = _admissionLetter?['acceptance_status'] == 'accepted';
    if (!accepted) {
      await _acceptAdmissionLetter();
      return;
    }

    final downloaded = await _downloadAdmissionLetter();
    if (!mounted || !downloaded) return;
    if (spec.next != null) {
      fhcPush(context, spec.next!);
    }
  }

  Future<bool> _downloadAdmissionLetter() async {
    if (_letterDownloading) return false;
    if (_admissionLetter == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'member.kca.letterPending',
              fallback: 'Your admission letter is being prepared by KCA administration.',
            ),
          ),
        ),
      );
      return false;
    }

    final repo = AppServicesScope.maybeOf(context)?.kcaRepository;
    if (repo == null) {
      await fhcApiUnavailable(
        context,
        action: fhcT(
          context,
          'member.kca.downloadLetter',
          fallback: 'Download Letter',
        ),
      );
      return false;
    }

    setState(() => _letterDownloading = true);
    final result = await repo.downloadAdmissionLetter();
    if (!mounted) return false;
    setState(() => _letterDownloading = false);

    switch (result) {
      case AppSuccess(:final value):
        final rawBytes = value['bytes'];
        late final Uint8List normalized;
        if (rawBytes is Uint8List) {
          normalized = rawBytes;
        } else if (rawBytes is List<int>) {
          normalized = Uint8List.fromList(rawBytes);
        } else if (rawBytes is List) {
          normalized = Uint8List.fromList(
            rawBytes.map((entry) => (entry as num).toInt()).toList(growable: false),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download failed: empty file.')),
          );
          return false;
        }

        final directory = await getApplicationDocumentsDirectory();
        final file = File(
          '${directory.path}/kca-admission-letter-${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(normalized, flush: true);

        final opened = await OpenFile.open(file.path);
        if (opened.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                fhcT(
                  context,
                  'member.kca.letterSavedLocally',
                  fallback: 'Admission letter saved on this device.',
                ),
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                fhcT(
                  context,
                  'member.kca.letterDownloadReady',
                  fallback: 'Admission letter downloaded.',
                ),
              ),
            ),
          );
        }
        return true;
      case AppError(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec(context, kind);
    final body = [
      if (spec.step != null) _stepper(context, spec.step!, spec.total ?? 8),
      ..._content(context, kind),
    ];
    return WorkflowPage(
      title: spec.title,
      domain: WorkflowDomain.kca,
      actionLabel: _submitting
          ? fhcT(context, 'common.submitting', fallback: 'Submitting…')
          : kind == KcaLifecycleKind.admissionLetter && _letterDownloading
              ? fhcT(context, 'common.downloading', fallback: 'Downloading…')
              : spec.action,
      onAction: _submitting || _letterDownloading
          ? null
          : kind == KcaLifecycleKind.admissionLetter
              ? (_admissionLetter == null ? null : () => _handleAction(spec))
              : spec.next == null
                  ? null
                  : () => _handleAction(spec),
      children: [
        if (_isEnrolmentStep)
          Form(key: _formKey, child: Column(children: body))
        else
          ...body,
      ],
    );
  }

  _KcaSpec _spec(BuildContext context, KcaLifecycleKind value) {
    final enrolment = fhcT(
      context,
      'member.kca.enrolment',
      fallback: 'KCA Enrolment',
    );
    final next = fhcT(context, 'common.next', fallback: 'Next');
    final student = fhcT(
      context,
      'member.kca.student',
      fallback: 'KCA Student',
    );
    return switch (value) {
      KcaLifecycleKind.churchInfo => _KcaSpec(
        enrolment,
        next,
        '/kca/enrollment/2',
        1,
      ),
      KcaLifecycleKind.walkWithChrist => _KcaSpec(
        enrolment,
        next,
        '/kca/enrollment/3',
        2,
      ),
      KcaLifecycleKind.whyJoin => _KcaSpec(
        enrolment,
        next,
        '/kca/enrollment/4',
        3,
      ),
      KcaLifecycleKind.interests => _KcaSpec(
        enrolment,
        next,
        '/kca/enrollment/5',
        4,
      ),
      KcaLifecycleKind.commitments => _KcaSpec(
        enrolment,
        next,
        '/kca/enrollment/6',
        5,
      ),
      KcaLifecycleKind.personalCommitment => _KcaSpec(
        enrolment,
        next,
        '/kca/enrollment/7',
        6,
      ),
      KcaLifecycleKind.guardianConsent => _KcaSpec(
        enrolment,
        next,
        '/kca/enrollment/8',
        7,
      ),
      KcaLifecycleKind.recommendation => _KcaSpec(
        enrolment,
        fhcT(
          context,
          'member.kca.submitApplication',
          fallback: 'Submit Application',
        ),
        '/kca/application-review',
        8,
      ),
      KcaLifecycleKind.applicationReview => _KcaSpec(
        fhcT(
          context,
          'member.kca.applicationReview',
          fallback: 'KCA Application Review',
        ),
        fhcT(context, 'member.kca.trackStatus', fallback: 'Track Status'),
        '/kca/admission-letter',
        null,
      ),
      KcaLifecycleKind.admissionLetter => _KcaSpec(
        fhcT(
          context,
          'member.kca.admissionLetter',
          fallback: 'KCA Admission Letter',
        ),
        _admissionLetter?['acceptance_status'] == 'accepted'
            ? fhcT(context, 'member.kca.downloadLetter', fallback: 'Download Letter')
            : fhcT(context, 'member.kca.acceptToContinue', fallback: 'Accept to continue'),
        _admissionLetter?['acceptance_status'] == 'accepted' ? '/kca/orientation' : null,
        null,
      ),
      KcaLifecycleKind.orientation => _KcaSpec(
        fhcT(context, 'member.kca.kcaOrientation', fallback: 'KCA Orientation'),
        fhcT(
          context,
          'member.kca.startOrientation',
          fallback: 'Start Orientation',
        ),
        '/kca/practical-service',
        null,
      ),
      KcaLifecycleKind.practicalService => _KcaSpec(
        fhcT(
          context,
          'member.kca.practicalServiceTitle',
          fallback: 'KCA Practical Service',
        ),
        fhcT(
          context,
          'member.kca.addAnotherDepartment',
          fallback: 'Add Another Department',
        ),
        null,
        null,
      ),
      KcaLifecycleKind.writtenAssessments => _KcaSpec(
        fhcT(
          context,
          'member.kca.writtenAssessments',
          fallback: 'Written Assessments',
        ),
        null,
        null,
        null,
      ),
      KcaLifecycleKind.spiritualAssignment => _KcaSpec(
        fhcT(
          context,
          'member.kca.spiritualAssignment',
          fallback: 'Spiritual Assignment',
        ),
        fhcT(
          context,
          'member.kca.viewFullJournal',
          fallback: 'View Full Journal',
        ),
        null,
        null,
      ),
      KcaLifecycleKind.selfReview => _KcaSpec(
        fhcT(context, 'member.kca.selfReview', fallback: 'Self Review'),
        fhcT(
          context,
          'member.kca.submitSelfReview',
          fallback: 'Submit Self Review',
        ),
        null,
        null,
      ),
      KcaLifecycleKind.administratorReview => _KcaSpec(
        fhcT(
          context,
          'member.kca.administratorReview',
          fallback: 'Administrator Review',
        ),
        fhcT(context, 'member.kca.submitReview', fallback: 'Submit Review'),
        null,
        null,
      ),
      KcaLifecycleKind.lockedModule => _KcaSpec(
        student,
        fhcT(
          context,
          'member.kca.viewMyProgress',
          fallback: 'View My Progress',
        ),
        '/kca/certification',
        17,
        21,
      ),
      KcaLifecycleKind.physicalAssignment => _KcaSpec(
        student,
        fhcT(
          context,
          'member.kca.submitPracticalAssignment',
          fallback: 'Submit Practical Assignment',
        ),
        '/kca/submissions',
        18,
        21,
      ),
      KcaLifecycleKind.mentorDashboard => _KcaSpec(
        fhcT(
          context,
          'member.kca.mentorDashboard',
          fallback: 'Mentor Dashboard',
        ),
        fhcT(
          context,
          'member.kca.viewAllStudents',
          fallback: 'View All Students',
        ),
        '/kca/mentees',
        null,
      ),
      KcaLifecycleKind.lecturerWorkspace => _KcaSpec(
        fhcT(context, 'member.kca.lecturer', fallback: 'KCA Lecturer'),
        fhcT(
          context,
          'member.kca.startLiveSession',
          fallback: 'Start Live Session',
        ),
        null,
        null,
      ),
      KcaLifecycleKind.mentorIntervention => _KcaSpec(
        fhcT(context, 'member.kca.kcaMentor', fallback: 'KCA Mentor'),
        fhcT(
          context,
          'member.kca.markInterventionComplete',
          fallback: 'Mark Intervention Complete',
        ),
        null,
        null,
      ),
      KcaLifecycleKind.admissionDecision => _KcaSpec(
        fhcT(context, 'member.kca.admissions', fallback: 'KCA Admissions'),
        null,
        null,
        null,
      ),
    };
  }

  List<Widget> _content(
    BuildContext context,
    KcaLifecycleKind value,
  ) => switch (value) {
    KcaLifecycleKind.churchInfo => [
      _heading(
        fhcT(
          context,
          'member.kca.churchInformation',
          fallback: 'Church Information',
        ),
        fhcT(
          context,
          'member.kca.churchInformationCopy',
          fallback: 'Tell us about your local church.',
        ),
      ),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.churchMinistry',
          fallback: 'Church / Ministry',
        ),
        controller: _c('church_ministry'),
        required: true,
      ),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.churchAddress',
          fallback: 'Church Address',
        ),
        controller: _c('church_address'),
        required: true,
      ),
      if (!_fieldsReady)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator.adaptive()),
        )
      else
        GeographySelect(
          key: const ValueKey('kca-church-geography'),
          countryController: _c('country'),
          countryLabelController: _c('country_label'),
          regionController: _c('region'),
          localityController: _c('locality'),
          required: true,
        ),
      WorkflowTextField(
        label: fhcT(context, 'member.kca.pastorsName', fallback: 'Pastor’s Name'),
        controller: _c('pastors_name'),
      ),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.pastorsPhone',
          fallback: 'Pastor’s Phone',
        ),
        controller: _c('pastors_phone'),
        keyboardType: TextInputType.phone,
      ),
      WorkflowTextField(
        label: fhcT(context, 'member.kca.email', fallback: 'Email'),
        controller: _c('email'),
        keyboardType: TextInputType.emailAddress,
      ),
    ],
    KcaLifecycleKind.walkWithChrist => [
      _heading(
        fhcT(
          context,
          'member.kca.walkWithChrist',
          fallback: 'Walk with Christ',
        ),
        fhcT(
          context,
          'member.kca.walkWithChristCopy',
          fallback: 'Where are you in your walk with Christ?',
        ),
      ),
      _choiceList([
        fhcT(
          context,
          'member.kca.justAcceptedChrist',
          fallback: 'I just accepted Christ',
        ),
        fhcT(
          context,
          'member.kca.growingInFaith',
          fallback: 'I am growing in my faith',
        ),
        fhcT(
          context,
          'member.kca.strongInFaith',
          fallback: 'I am strong in my faith',
        ),
        fhcT(
          context,
          'member.kca.wantToKnowMore',
          fallback: 'I want to know more about Christ',
        ),
      ], _choiceIndex),
      WorkflowTextField(
        label: fhcT(context, 'member.kca.tellUsMore', fallback: 'Tell us more'),
        controller: _c('walk_more'),
        lines: 3,
      ),
    ],
    KcaLifecycleKind.whyJoin => [
      _heading(
        fhcT(context, 'member.kca.whyJoinKca', fallback: 'Why Join KCA?'),
        fhcT(
          context,
          'member.kca.whyJoinKcaCopy',
          fallback:
              'What is your reason for joining the Kingdom Change Agent training?',
        ),
      ),
      _choiceList([
        fhcT(
          context,
          'member.kca.toGrowSpiritually',
          fallback: 'To grow spiritually',
        ),
        fhcT(
          context,
          'member.kca.toServeBetter',
          fallback: 'To serve better in church',
        ),
        fhcT(
          context,
          'member.kca.toImpactCommunity',
          fallback: 'To impact my community',
        ),
        fhcT(
          context,
          'member.kca.toPrepareForMinistry',
          fallback: 'To prepare for ministry',
        ),
        fhcT(context, 'member.kca.other', fallback: 'Other'),
      ], _choiceIndex),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.tellUsMoreOptional',
          fallback: 'Tell us more (Optional)',
        ),
        controller: _c('why_join_more'),
        lines: 3,
      ),
    ],
    KcaLifecycleKind.interests => [
      _heading(
        fhcT(
          context,
          'member.kca.serviceInterests',
          fallback: 'Service & Kingdom Interests',
        ),
        fhcT(
          context,
          'member.kca.serviceInterestsCopy',
          fallback: 'What are you passionate about? Select all that apply.',
        ),
      ),
      _interestGrid(context),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.otherPleaseSpecify',
          fallback: 'Other (Please specify)',
        ),
        controller: _c('interests_other'),
      ),
    ],
    KcaLifecycleKind.commitments => [
      _heading(
        fhcT(
          context,
          'member.kca.commitmentRequirements',
          fallback: 'Commitment Requirements',
        ),
        fhcT(
          context,
          'member.kca.commitmentRequirementsCopy',
          fallback: 'KCA requires commitment to these areas:',
        ),
      ),
      _checkList([
        fhcT(
          context,
          'member.kca.commitAttendClasses',
          fallback: 'Attend all classes and complete assignments',
        ),
        fhcT(
          context,
          'member.kca.commitServeDepartments',
          fallback: 'Serve in at least two departments',
        ),
        fhcT(
          context,
          'member.kca.commitWalkWithChrist',
          fallback: 'Maintain a growing walk with Christ',
        ),
        fhcT(
          context,
          'member.kca.commitUpholdValues',
          fallback: 'Uphold the values and doctrines of Family House Connect',
        ),
        fhcT(
          context,
          'member.kca.commitCompleteTraining',
          fallback: 'Complete the training within the stipulated time',
        ),
      ]),
      _notice(
        fhcT(
          context,
          'member.kca.commitmentNotice',
          fallback:
              'Your commitment is key to your success and impact in this training.',
        ),
      ),
    ],
    KcaLifecycleKind.personalCommitment => [
      _heading(
        fhcT(
          context,
          'member.kca.personalCommitment',
          fallback: 'Personal Commitment',
        ),
        fhcT(
          context,
          'member.kca.personalCommitmentCopy',
          fallback: 'Please read and confirm your commitment.',
        ),
      ),
      _notice(
        fhcT(
          context,
          'member.kca.personalCommitmentText',
          fallback:
              'I commit to faithfully participate in the Kingdom Change Agent Training, complete all requirements, serve wholeheartedly and uphold the values of Family House Connect.',
        ),
      ),
      _checkList([
        fhcT(
          context,
          'member.kca.agreePersonalCommitment',
          fallback: 'I have read and agree to the personal commitment above.',
        ),
      ]),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.signatureFullName',
          fallback: 'Signature (Type your full name)',
        ),
        controller: _c('signature_name'),
        required: true,
      ),
      WorkflowTextField(
        label: fhcT(context, 'member.kca.date', fallback: 'Date'),
        controller: _c('signature_date'),
        icon: Icons.calendar_today_outlined,
        required: true,
      ),
    ],
    KcaLifecycleKind.guardianConsent => [
      _heading(
        fhcT(
          context,
          'member.kca.guardianConsent',
          fallback: 'Parent / Guardian Consent',
        ),
        fhcT(
          context,
          'member.kca.guardianConsentCopy',
          fallback: 'Section for applicants below 18 years.',
        ),
      ),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.guardianFullName',
          fallback: 'Guardian Full Name',
        ),
        controller: _c('guardian_name'),
      ),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.relationshipToApplicant',
          fallback: 'Relationship to Applicant',
        ),
        controller: _c('guardian_relationship'),
      ),
      WorkflowTextField(
        label: fhcT(context, 'member.kca.phoneNumber', fallback: 'Phone Number'),
        controller: _c('guardian_phone'),
        keyboardType: TextInputType.phone,
      ),
      WorkflowTextField(
        label: fhcT(
          context,
          'auth.emailAddress',
          fallback: 'Email Address',
        ),
        controller: _c('guardian_email'),
        keyboardType: TextInputType.emailAddress,
      ),
      _notice(
        fhcT(
          context,
          'member.kca.guardianConsentText',
          fallback:
              'I give consent for my child to participate in the Kingdom Change Agent Training Program.',
        ),
      ),
      _checkList([
        fhcT(
          context,
          'member.kca.iAgreeAndConsent',
          fallback: 'I agree and consent.',
        ),
      ]),
    ],
    KcaLifecycleKind.recommendation => [
      _heading(
        fhcT(
          context,
          'member.kca.leadershipRecommendation',
          fallback: 'Church / Leadership Recommendation',
        ),
        fhcT(
          context,
          'member.kca.leadershipRecommendationCopy',
          fallback: 'Recommendation by your pastor or leader.',
        ),
      ),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.recommenderFullName',
          fallback: 'Recommender Full Name',
        ),
        controller: _c('recommender_name'),
        required: true,
      ),
      WorkflowTextField(
        label: fhcT(context, 'member.kca.position', fallback: 'Position'),
        controller: _c('recommender_position'),
        required: true,
      ),
      WorkflowTextField(
        label: fhcT(context, 'member.kca.phoneNumber', fallback: 'Phone Number'),
        controller: _c('recommender_phone'),
        required: true,
        keyboardType: TextInputType.phone,
      ),
      WorkflowTextField(
        label: fhcT(
          context,
          'auth.emailAddress',
          fallback: 'Email Address',
        ),
        controller: _c('recommender_email'),
        keyboardType: TextInputType.emailAddress,
      ),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.recommendation',
          fallback: 'Recommendation',
        ),
        controller: _c('recommendation_level'),
      ),
      WorkflowTextField(
        label: fhcT(
          context,
          'member.kca.additionalComments',
          fallback: 'Additional Comments',
        ),
        controller: _c('recommendation_comments'),
        lines: 3,
      ),
    ],
    KcaLifecycleKind.applicationReview => [
      const SizedBox(height: 16),
      const Center(
        child: Icon(
          Icons.rate_review_outlined,
          size: 90,
          color: FhcColors.green,
        ),
      ),
      _heading(
        fhcT(
          context,
          'member.kca.applicationUnderReview',
          fallback: 'Application Under Review',
        ),
        fhcT(
          context,
          'member.kca.applicationUnderReviewCopy',
          fallback:
              'Thank you! Your application has been received and is being reviewed.',
        ),
      ),
      _details([
        (
          fhcT(
            context,
            'member.kca.applicationId',
            fallback: 'Application ID',
          ),
          'KCA-2025-00156',
        ),
        (
          fhcT(context, 'member.kca.submittedOn', fallback: 'Submitted on'),
          'May 18, 2025',
        ),
      ]),
      WorkflowSectionTitle(
        fhcT(
          context,
          'member.kca.whatHappensNext',
          fallback: 'What happens next?',
        ),
      ),
      _checkList([
        fhcT(
          context,
          'member.kca.reviewByAdmin',
          fallback: 'Review by KCA Administration',
        ),
        fhcT(
          context,
          'member.kca.notifiedOfDecision',
          fallback: 'You will be notified of the decision',
        ),
        fhcT(
          context,
          'member.kca.prepareForOrientation',
          fallback: 'Prepare for orientation',
        ),
      ]),
    ],
    KcaLifecycleKind.admissionLetter => [
      _success(
        fhcT(
          context,
          'member.kca.congratulations',
          fallback: 'Congratulations!',
        ),
        fhcT(
          context,
          'member.kca.admittedToProgram',
          fallback:
              'You have been admitted to the Kingdom Change Agent Training Program.',
        ),
      ),
      if (_letterLoading)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_admissionLetter == null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            fhcT(
              context,
              'member.kca.letterPending',
              fallback: 'Your admission letter is being prepared by KCA administration.',
            ),
          ),
        )
      else
        ...[
          if (('${_admissionLetter?['letter_body'] ?? ''}').trim().isNotEmpty)
            WorkflowCard(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(4),
                  child: SelectableText(
                    '${_admissionLetter?['letter_body'] ?? ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                  ),
                ),
              ),
            ),
          _details([
            (
              fhcT(context, 'member.kca.applicantName', fallback: 'Applicant Name'),
              '${_admissionLetter?['applicant_name'] ?? '—'}',
            ),
            (
              fhcT(context, 'member.kca.kcaId', fallback: 'Reference'),
              '${_admissionLetter?['reference_code'] ?? '—'}',
            ),
            (
              fhcT(context, 'member.kca.admissionDate', fallback: 'Admission Date'),
              '${_admissionLetter?['issued_at'] ?? '—'}',
            ),
            (
              fhcT(context, 'member.kca.nextStep', fallback: 'Next Step'),
              fhcT(
                context,
                'member.kca.attendOrientation',
                fallback: 'Attend Orientation',
              ),
            ),
          ]),
          if (_admissionLetter?['acceptance_status'] == 'accepted')
            _success(
              fhcT(
                context,
                'member.kca.letterAcceptedTitle',
                fallback: 'Letter accepted',
              ),
              fhcT(
                context,
                'member.kca.letterAcceptedCopy',
                fallback: 'Your signed acceptance is recorded on this admission letter.',
              ),
            )
          else
            WorkflowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    fhcT(
                      context,
                      'member.kca.acceptAdmission',
                      fallback: 'Accept admission',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fhcT(
                      context,
                      'member.kca.acceptAdmissionCopy',
                      fallback:
                          'Read the letter above carefully, then sign below to confirm your acceptance.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      fhcT(
                        context,
                        'member.kca.acceptanceConfirm',
                        fallback: 'I have read and accept this admission letter.',
                      ),
                    ),
                    value: _letterAcceptConfirmed,
                    onChanged: (value) => setState(
                      () => _letterAcceptConfirmed = value ?? false,
                    ),
                  ),
                  TextFormField(
                    controller: _c('letter_signature'),
                    decoration: InputDecoration(
                      labelText: fhcT(
                        context,
                        'member.kca.signatureName',
                        fallback: 'Type your full name as signature',
                      ),
                    ),
                  ),
                  if (_admissionLetter?['requires_guardian_confirmation'] == true) ...[
                    const SizedBox(height: 12),
                    Text(
                      fhcT(
                        context,
                        'member.kca.guardianConfirmation',
                        fallback: 'Parent/Guardian confirmation',
                      ),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextFormField(
                      controller: _c('letter_guardian_name'),
                      decoration: InputDecoration(
                        labelText: fhcT(
                          context,
                          'member.kca.guardianName',
                          fallback: 'Parent/Guardian name',
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _c('letter_guardian_signature'),
                      decoration: InputDecoration(
                        labelText: fhcT(
                          context,
                          'member.kca.guardianSignature',
                          fallback: 'Parent/Guardian signature',
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _c('letter_guardian_phone'),
                      decoration: InputDecoration(
                        labelText: fhcT(
                          context,
                          'member.kca.guardianPhone',
                          fallback: 'Parent/Guardian phone',
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _letterAccepting ? null : () => _acceptAdmissionLetter(),
                    child: Text(
                      _letterAccepting
                          ? fhcT(context, 'common.submitting', fallback: 'Submitting…')
                          : fhcT(
                              context,
                              'member.kca.submitAcceptance',
                              fallback: 'Submit acceptance',
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
    ],
    KcaLifecycleKind.orientation => [
      WorkflowSummary(
        title: fhcT(
          context,
          'member.kca.orientationProgram',
          fallback: 'Orientation Program',
        ),
        subtitle: fhcT(
          context,
          'member.kca.orientationWelcome',
          fallback: 'Welcome to KCA! Get started with your orientation.',
        ),
        metrics: const [],
        imageAsset: 'assets/images/connect_people.png',
      ),
      _rows([
        (
          fhcT(
            context,
            'member.kca.programOverview',
            fallback: 'Program Overview',
          ),
          fhcT(
            context,
            'member.kca.aboutTheTraining',
            fallback: 'About the training',
          ),
        ),
        (
          fhcT(
            context,
            'member.kca.rulesGuidelines',
            fallback: 'Rules & Guidelines',
          ),
          fhcT(
            context,
            'member.kca.whatYouNeedToKnow',
            fallback: 'What you need to know',
          ),
        ),
        (
          fhcT(context, 'member.kca.learningPath', fallback: 'Learning Path'),
          fhcT(
            context,
            'member.kca.yourJourneyAhead',
            fallback: 'Your journey ahead',
          ),
        ),
        (
          fhcT(
            context,
            'member.kca.meetYourMentors',
            fallback: 'Meet Your Mentors',
          ),
          fhcT(
            context,
            'member.kca.connectWithMentors',
            fallback: 'Connect with your mentors',
          ),
        ),
      ]),
    ],
    KcaLifecycleKind.practicalService => [
      _heading(
        fhcT(
          context,
          'member.kca.practicalService',
          fallback: 'Practical Service',
        ),
        fhcT(
          context,
          'member.kca.practicalServiceCopy',
          fallback: 'Serve in at least two departments.',
        ),
      ),
      _rows([
        (
          fhcT(
            context,
            'member.kca.evangelismTeam',
            fallback: 'Evangelism Team',
          ),
          fhcT(
            context,
            'member.kca.evangelismTeamMeta',
            fallback: 'Outreach & Soul Winning • Active',
          ),
        ),
        (
          fhcT(context, 'member.kca.mediaTeam', fallback: 'Media Team'),
          fhcT(
            context,
            'member.kca.mediaTeamMeta',
            fallback: 'Photography & Content • Active',
          ),
        ),
      ]),
      WorkflowSectionTitle(
        fhcT(context, 'member.kca.serviceSummary', fallback: 'Service Summary'),
      ),
      WorkflowSummary(
        title: fhcT(context, 'member.kca.onTrack', fallback: 'On Track'),
        metrics: [
          (
            '2',
            fhcT(context, 'member.kca.departments', fallback: 'Departments'),
          ),
          (
            '48',
            fhcT(context, 'member.kca.hoursServed', fallback: 'Hours Served'),
          ),
          (
            '✓',
            fhcT(context, 'member.kca.status', fallback: 'Status'),
          ),
        ],
      ),
    ],
    KcaLifecycleKind.writtenAssessments => [
      _heading(
        fhcT(
          context,
          'member.kca.writtenAssessments',
          fallback: 'Written Assessments',
        ),
        fhcT(
          context,
          'member.kca.writtenAssessmentsCopy',
          fallback: 'Complete all four assessments.',
        ),
      ),
      _rows([
        (
          fhcT(
            context,
            'member.kca.biblicalFoundations',
            fallback: 'Biblical Foundations',
          ),
          fhcT(
            context,
            'member.kca.scoreCompleted',
            args: {'score': '88%'},
            fallback: 'Score: {score} • Completed',
          ),
        ),
        (
          fhcT(
            context,
            'member.kca.kingdomPrinciples',
            fallback: 'Kingdom Principles',
          ),
          fhcT(
            context,
            'member.kca.scoreCompleted',
            args: {'score': '82%'},
            fallback: 'Score: {score} • Completed',
          ),
        ),
        (
          fhcT(
            context,
            'member.kca.ministryMission',
            fallback: 'Ministry & Mission',
          ),
          fhcT(context, 'member.kca.inProgress', fallback: 'In Progress'),
        ),
        (
          fhcT(
            context,
            'member.kca.leadershipStewardship',
            fallback: 'Leadership & Stewardship',
          ),
          fhcT(context, 'member.kca.pending', fallback: 'Pending'),
        ),
      ]),
      WorkflowSectionTitle(
        fhcT(context, 'member.kca.overallProgress', fallback: 'Overall Progress'),
      ),
      WorkflowProgress(
        label: fhcT(context, 'member.kca.assessments', fallback: 'Assessments'),
        value: .5,
        trailing: '50%',
      ),
    ],
    KcaLifecycleKind.spiritualAssignment => [
      _heading(
        fhcT(
          context,
          'member.kca.spiritualAssignment',
          fallback: 'Spiritual Assignment',
        ),
        fhcT(
          context,
          'member.kca.spiritualAssignmentCopy',
          fallback: 'Deepen your relationship with God.',
        ),
      ),
      _details([
        (
          fhcT(context, 'member.kca.assignment', fallback: 'Assignment'),
          fhcT(
            context,
            'member.kca.dailyPrayerFasting',
            fallback: 'Daily Prayer & Fasting',
          ),
        ),
        (
          fhcT(context, 'member.kca.duration', fallback: 'Duration'),
          fhcT(
            context,
            'member.kca.durationDays',
            args: {'days': '30'},
            fallback: '{days} days',
          ),
        ),
        (
          fhcT(context, 'member.kca.progress', fallback: 'Progress'),
          fhcT(
            context,
            'member.kca.dayOf',
            args: {'current': '18', 'total': '30'},
            fallback: 'Day {current} of {total}',
          ),
        ),
      ]),
      WorkflowProgress(
        label: fhcT(
          context,
          'member.kca.prayerAndFasting',
          fallback: 'Prayer & fasting',
        ),
        value: .6,
        trailing: '18 / 30',
      ),
      WorkflowSectionTitle(
        fhcT(
          context,
          'member.kca.journalEntryLatest',
          fallback: 'Journal Entry (Latest)',
        ),
      ),
      _notice(
        fhcT(
          context,
          'member.kca.journalSample',
          fallback:
              'God has been teaching me about patience and trusting His timing.',
        ),
      ),
      Text(
        fhcT(
          context,
          'member.kca.lastUpdated',
          args: {'date': 'May 28, 2025'},
          fallback: 'Last Updated: {date}',
        ),
        style: FhcTypography.caption,
      ),
    ],
    KcaLifecycleKind.selfReview => [
      _heading(
        fhcT(
          context,
          'member.kca.studentSelfReview',
          fallback: 'Student Self Review',
        ),
        fhcT(
          context,
          'member.kca.studentSelfReviewCopy',
          fallback: 'Review your growth and performance.',
        ),
      ),
      for (final label in [
        fhcT(
          context,
          'member.kca.spiritualGrowth',
          fallback: 'Spiritual Growth',
        ),
        fhcT(
          context,
          'member.kca.classParticipation',
          fallback: 'Class Participation',
        ),
        fhcT(context, 'member.kca.assignments', fallback: 'Assignments'),
        fhcT(
          context,
          'member.kca.practicalService',
          fallback: 'Practical Service',
        ),
        fhcT(
          context,
          'member.kca.timeManagement',
          fallback: 'Time Management',
        ),
      ])
        _rating(label, 4),
      WorkflowField(
        label: fhcT(context, 'member.kca.reflection', fallback: 'Reflection'),
        value:
            'I have grown in faith and learned so much. I will keep improving.',
        lines: 4,
      ),
    ],
    KcaLifecycleKind.administratorReview => [
      _profile(
        'Jane Esther',
        fhcT(
          context,
          'member.kca.trainingAdministrator',
          fallback: 'Training Administrator',
        ),
      ),
      _details([
        (
          fhcT(context, 'member.kca.studentLabel', fallback: 'Student'),
          'Glory Samuel',
        ),
        (fhcT(context, 'member.kca.kcaId', fallback: 'KCA ID'), 'KCA-2025-00156'),
      ]),
      WorkflowSectionTitle(
        fhcT(
          context,
          'member.kca.overallEvaluation',
          fallback: 'Overall Evaluation',
        ),
      ),
      _rating(
        fhcT(context, 'member.kca.goodProgress', fallback: 'Good Progress'),
        4,
      ),
      WorkflowField(
        label: fhcT(context, 'member.kca.comments', fallback: 'Comments'),
        value:
            'Glory is doing well. Keep improving in assignments and class engagement.',
        lines: 4,
      ),
      WorkflowField(
        label: fhcT(context, 'member.kca.decision', fallback: 'Decision'),
        value: fhcT(context, 'member.kca.approved', fallback: 'Approved'),
      ),
    ],
    KcaLifecycleKind.lockedModule => [
      _success(
        fhcT(
          context,
          'member.kca.moduleLocked',
          args: {'n': '4'},
          fallback: 'Module {n} Locked',
        ),
        fhcT(
          context,
          'member.kca.moduleLockedCopy',
          fallback: 'Complete the required prerequisites to unlock this module.',
        ),
      ),
      WorkflowSectionTitle(
        fhcT(context, 'member.kca.prerequisites', fallback: 'Prerequisites'),
      ),
      _rows([
        (
          fhcT(
            context,
            'member.kca.moduleCompleted',
            args: {'n': '3'},
            fallback: 'Module {n} Completed',
          ),
          fhcT(context, 'member.kca.completed', fallback: 'Completed'),
        ),
        (
          fhcT(
            context,
            'member.kca.assignmentSubmitted',
            fallback: 'Assignment Submitted',
          ),
          fhcT(context, 'member.kca.completed', fallback: 'Completed'),
        ),
        (
          fhcT(context, 'member.kca.mentorApproval', fallback: 'Mentor Approval'),
          fhcT(context, 'member.kca.pending', fallback: 'Pending'),
        ),
        (
          fhcT(
            context,
            'member.kca.quizPassed',
            fallback: 'Quiz Passed (70% or higher)',
          ),
          fhcT(context, 'member.kca.pending', fallback: 'Pending'),
        ),
        (
          fhcT(
            context,
            'member.kca.spiritualExerciseCompleted',
            fallback: 'Spiritual Exercise Completed',
          ),
          fhcT(context, 'member.kca.completed', fallback: 'Completed'),
        ),
      ]),
      _notice(
        fhcT(
          context,
          'member.kca.completePrerequisites',
          fallback: 'Complete remaining prerequisites to unlock this module.',
        ),
      ),
    ],
    KcaLifecycleKind.physicalAssignment => [
      _heading(
        fhcT(
          context,
          'member.kca.physicalAssignment',
          fallback: 'Physical Assignment',
        ),
        fhcT(
          context,
          'member.kca.physicalAssignmentCopy',
          fallback: 'Practical ministry service in the field.',
        ),
      ),
      _details([
        (
          fhcT(context, 'member.kca.assignment', fallback: 'Assignment'),
          fhcT(
            context,
            'member.kca.communityOutreachFollowUp',
            fallback: 'Community Outreach & Follow-up',
          ),
        ),
        (
          fhcT(context, 'member.kca.instructions', fallback: 'Instructions'),
          fhcT(
            context,
            'member.kca.physicalAssignmentInstructions',
            fallback:
                'Plan the outreach, engage people and follow up within 7 days.',
          ),
        ),
        (
          fhcT(context, 'member.kca.dueDate', fallback: 'Due Date'),
          'May 31, 2025',
        ),
        (
          fhcT(
            context,
            'member.kca.expectedEvidence',
            fallback: 'Expected Evidence',
          ),
          fhcT(
            context,
            'member.kca.expectedEvidenceCopy',
            fallback: 'Photos, video, attendance list and report',
          ),
        ),
        (
          fhcT(context, 'member.kca.status', fallback: 'Status'),
          fhcT(context, 'member.kca.inProgress', fallback: 'In Progress'),
        ),
      ]),
      WorkflowSectionTitle(
        fhcT(context, 'member.kca.uploadEvidence', fallback: 'Upload Evidence'),
      ),
      WorkflowUploadBox(
        label: fhcT(
          context,
          'member.kca.tapToUpload',
          fallback: 'Tap to upload or drag files here',
        ),
      ),
    ],
    KcaLifecycleKind.mentorDashboard => [
      _profile(
        'Pastor Daniel John',
        fhcT(
          context,
          'member.kca.welcomeBackMentor',
          fallback: 'Welcome Back! • KCA Mentor',
        ),
      ),
      WorkflowSummary(
        title: fhcT(context, 'member.kca.myStudents', fallback: 'My Students'),
        metrics: [
          (
            '24',
            fhcT(context, 'member.kca.students', fallback: 'Students'),
          ),
          (
            '18',
            fhcT(context, 'member.kca.active', fallback: 'Active'),
          ),
          (
            '6',
            fhcT(context, 'member.kca.completed', fallback: 'Completed'),
          ),
        ],
      ),
      WorkflowSectionTitle(
        fhcT(context, 'member.kca.myTasks', fallback: 'My Tasks'),
      ),
      _rows([
        (
          fhcT(context, 'member.kca.reviewEvidence', fallback: 'Review Evidence'),
          fhcT(
            context,
            'member.kca.pendingCount',
            args: {'count': '5'},
            fallback: '{count} Pending',
          ),
        ),
        (
          fhcT(context, 'member.kca.mentorSessions', fallback: 'Mentor Sessions'),
          fhcT(
            context,
            'member.kca.todayCount',
            args: {'count': '2'},
            fallback: '{count} Today',
          ),
        ),
        (
          fhcT(context, 'member.kca.followUps', fallback: 'Follow-ups'),
          fhcT(
            context,
            'member.kca.pendingCount',
            args: {'count': '7'},
            fallback: '{count} Pending',
          ),
        ),
      ]),
    ],
    KcaLifecycleKind.lecturerWorkspace => [
      _heading(
        fhcT(
          context,
          'member.kca.lessonDeliveryWorkspace',
          fallback: 'Lesson Delivery Workspace',
        ),
        fhcT(
          context,
          'member.kca.lessonDeliveryCopy',
          fallback: 'Teach, engage and evaluate your class.',
        ),
      ),
      _rows([
        (
          fhcT(context, 'member.kca.currentLesson', fallback: 'Current Lesson'),
          fhcT(
            context,
            'member.kca.currentLessonMeta',
            fallback: 'The Power of Prayer & Fasting • Live Session',
          ),
        ),
      ]),
      WorkflowSectionTitle(
        fhcT(context, 'member.kca.classOverview', fallback: 'Class Overview'),
      ),
      WorkflowSummary(
        title: fhcT(context, 'member.kca.currentClass', fallback: 'Current Class'),
        metrics: [
          (
            '48',
            fhcT(context, 'member.kca.enrolled', fallback: 'Enrolled'),
          ),
          (
            '42',
            fhcT(context, 'member.kca.present', fallback: 'Present'),
          ),
          (
            '4',
            fhcT(context, 'member.kca.absent', fallback: 'Absent'),
          ),
          (
            '87%',
            fhcT(context, 'member.kca.attendance', fallback: 'Attendance'),
          ),
        ],
      ),
      WorkflowSectionTitle(
        fhcT(context, 'member.kca.resources', fallback: 'Resources'),
      ),
      _rows([
        (
          fhcT(
            context,
            'member.kca.lessonSlidesPdf',
            fallback: 'Lesson Slides (PDF)',
          ),
          '2.4 MB',
        ),
        (
          fhcT(
            context,
            'member.kca.prayerFastingGuide',
            fallback: 'Prayer & Fasting Guide',
          ),
          '1.1 MB',
        ),
      ]),
      _interestGrid(
        context,
        labels: [
          fhcT(context, 'member.kca.quizHandoff', fallback: 'Quiz Handoff'),
          fhcT(
            context,
            'member.kca.assignmentHandoff',
            fallback: 'Assignment Handoff',
          ),
          fhcT(context, 'member.kca.sessionNotes', fallback: 'Session Notes'),
        ],
      ),
    ],
    KcaLifecycleKind.mentorIntervention => [
      _heading(
        fhcT(
          context,
          'member.kca.studentNeedsAttention',
          fallback: 'Student Needs Attention',
        ),
        fhcT(
          context,
          'member.kca.studentNeedsAttentionCopy',
          fallback: 'Review issues and take timely action.',
        ),
      ),
      _profile(
        'Daniel John',
        fhcT(
          context,
          'member.kca.needsAttentionMeta',
          args: {'id': 'KCA-2025-00112'},
          fallback: 'KCA ID: {id} • Needs Attention',
        ),
      ),
      WorkflowSectionTitle(
        fhcT(context, 'member.kca.issuesDetected', fallback: 'Issues Detected'),
      ),
      _rows([
        (
          fhcT(
            context,
            'member.kca.poorAttendance',
            args: {'rate': '58%'},
            fallback: 'Poor Attendance ({rate})',
          ),
          fhcT(context, 'member.kca.priorityHigh', fallback: 'High'),
        ),
        (
          fhcT(
            context,
            'member.kca.failedModuleTwice',
            fallback: 'Failed Module Twice',
          ),
          fhcT(context, 'member.kca.priorityHigh', fallback: 'High'),
        ),
        (
          fhcT(
            context,
            'member.kca.overdueAssignment',
            args: {'days': '7'},
            fallback: 'Overdue Assignment ({days} days)',
          ),
          fhcT(context, 'member.kca.priorityMedium', fallback: 'Medium'),
        ),
        (
          fhcT(
            context,
            'member.kca.repeatedResubmission',
            fallback: 'Repeated Resubmission',
          ),
          fhcT(context, 'member.kca.priorityMedium', fallback: 'Medium'),
        ),
      ]),
      WorkflowField(
        label: fhcT(context, 'member.kca.mentorNotes', fallback: 'Mentor Notes'),
        value:
            'Daniel is struggling with consistency and time management. He needs encouragement and a structured plan.',
        lines: 4,
      ),
      _checkList([
        fhcT(
          context,
          'member.kca.scheduleMentoringSession',
          fallback: 'Schedule a one-on-one mentoring session',
        ),
        fhcT(
          context,
          'member.kca.reviewStudyPlan',
          fallback: 'Review study plan and commitments',
        ),
        fhcT(
          context,
          'member.kca.provideLearningResources',
          fallback: 'Provide additional learning resources',
        ),
        fhcT(
          context,
          'member.kca.prayAndSetGoals',
          fallback: 'Pray together and set improvement goals',
        ),
      ]),
    ],
    KcaLifecycleKind.admissionDecision => [
      _success(
        fhcT(
          context,
          'member.kca.decisionAccepted',
          fallback: 'Decision: Accepted',
        ),
        fhcT(
          context,
          'member.kca.decisionAcceptedCopy',
          fallback:
              'Congratulations! You have been accepted into the Kingdom Change Agents Training Program.',
        ),
      ),
      _details([
        (
          fhcT(context, 'member.kca.decisionDate', fallback: 'Decision Date'),
          'May 18, 2025',
        ),
        (
          fhcT(context, 'member.kca.reviewedBy', fallback: 'Reviewed By'),
          'Mary Johnson • Admissions Administrator',
        ),
        (
          fhcT(context, 'member.kca.remarks', fallback: 'Remarks'),
          'Strong commitment to ministry and Kingdom impact.',
        ),
        (
          fhcT(
            context,
            'member.kca.assignedMentor',
            fallback: 'Assigned Mentor',
          ),
          'Pastor Tunde Adeyemi',
        ),
        (
          fhcT(
            context,
            'member.kca.orientationDate',
            fallback: 'Orientation Date',
          ),
          'May 28, 2025 • 10:00 AM',
        ),
        (
          fhcT(
            context,
            'member.kca.programStartDate',
            fallback: 'Program Start Date',
          ),
          'June 2, 2025',
        ),
      ]),
      WorkflowSectionTitle(
        fhcT(context, 'member.kca.nextSteps', fallback: 'Next Steps'),
      ),
      _checkList([
        fhcT(
          context,
          'member.kca.confirmAcceptanceBy',
          args: {'date': 'May 24, 2025'},
          fallback: 'Confirm acceptance by {date}',
        ),
        fhcT(
          context,
          'member.kca.attendOrientation',
          fallback: 'Attend orientation',
        ),
        fhcT(
          context,
          'member.kca.completeOnboarding',
          fallback: 'Complete onboarding materials',
        ),
      ]),
      WorkflowSegments(
        labels: [
          fhcT(context, 'member.kca.accepted', fallback: 'Accepted'),
          fhcT(context, 'member.kca.deferred', fallback: 'Deferred'),
          fhcT(context, 'member.kca.notAccepted', fallback: 'Not Accepted'),
        ],
      ),
    ],
  };

  Widget _stepper(BuildContext context, int current, int total) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var index = 1; index <= (total > 8 ? 8 : total); index++)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 23,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        index <= (current > 8 ? current % 8 + 1 : current)
                            ? FhcColors.green
                            : FhcColors.canvas,
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color:
                          index <= (current > 8 ? current % 8 + 1 : current)
                              ? Colors.white
                              : FhcColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          fhcT(
            context,
            'member.kca.stepOf',
            args: {'current': '$current', 'total': '$total'},
            fallback: 'Step {current} of {total}',
          ),
          style: FhcTypography.caption,
        ),
      ],
    ),
  );

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: FhcTypography.body),
      ],
    ),
  );

  Widget _choiceList(List<String> labels, int selected) => Column(
    children: [
      for (var index = 0; index < labels.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: InkWell(
            onTap: () => setState(() => _choiceIndex = index),
            borderRadius: BorderRadius.circular(FhcRadius.card),
            child: WorkflowCard(
              color: index == selected ? FhcColors.mint : Colors.white,
              child: Row(
                children: [
                  Icon(
                    index == selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: FhcColors.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      labels[index],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget _interestGrid(BuildContext context, {List<String>? labels}) {
    final values =
        labels ??
        [
          fhcT(
            context,
            'member.kca.interestTeaching',
            fallback: 'Teaching / Training',
          ),
          fhcT(
            context,
            'member.kca.interestEvangelism',
            fallback: 'Evangelism / Outreach',
          ),
          fhcT(
            context,
            'member.kca.interestWorship',
            fallback: 'Worship / Music',
          ),
          fhcT(
            context,
            'member.kca.interestMedia',
            fallback: 'Media / Tech',
          ),
          fhcT(
            context,
            'member.kca.interestChildren',
            fallback: 'Children Ministry',
          ),
          fhcT(
            context,
            'member.kca.interestYouth',
            fallback: 'Youth Ministry',
          ),
          fhcT(
            context,
            'member.kca.interestAdministration',
            fallback: 'Administration',
          ),
          fhcT(
            context,
            'member.kca.interestCounselling',
            fallback: 'Counselling',
          ),
          fhcT(context, 'member.kca.interestCommunity', fallback: 'Community'),
        ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.05,
      children: [
        for (var index = 0; index < values.length; index++)
          InkWell(
            onTap: () => setState(() {
              if (_interests.contains(index)) {
                _interests.remove(index);
              } else {
                _interests.add(index);
              }
            }),
            borderRadius: BorderRadius.circular(FhcRadius.card),
            child: WorkflowCard(
              color: _interests.contains(index)
                  ? FhcColors.mint
                  : Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _interests.contains(index)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: FhcColors.green,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    values[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _checkList(List<String> labels) => WorkflowCard(
    child: Column(
      children: [
        for (var index = 0; index < labels.length; index++)
          InkWell(
            onTap: () => setState(() {
              if (_checked.contains(index)) {
                _checked.remove(index);
              } else {
                _checked.add(index);
              }
            }),
            child: WorkflowRow(
              title: labels[index],
              leading: _checked.contains(index)
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              trailing: const SizedBox.shrink(),
            ),
          ),
      ],
    ),
  );
  Widget _rows(List<(String, String)> values) => WorkflowCard(
    child: Column(
      children: [
        for (final value in values)
          WorkflowRow(title: value.$1, subtitle: value.$2),
      ],
    ),
  );
  Widget _notice(String text) => Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FhcColors.orange.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        const Icon(Icons.lightbulb_outline, color: FhcColors.orange),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: FhcTypography.body)),
      ],
    ),
  );
  Widget _success(String title, String subtitle) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: FhcColors.greenDark,
      borderRadius: BorderRadius.circular(FhcRadius.card),
    ),
    child: Column(
      children: [
        const Icon(Icons.check_circle_outline, size: 62, color: Colors.white),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
      ],
    ),
  );
  Widget _details(List<(String, String)> values) => WorkflowCard(
    child: Column(
      children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Expanded(child: Text(value.$1, style: FhcTypography.caption)),
                Expanded(
                  child: Text(
                    value.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  Widget _profile(String name, String subtitle) => WorkflowCard(
    child: Row(
      children: [
        const CircleAvatar(
          radius: 27,
          backgroundColor: FhcColors.mint,
          child: Icon(Icons.person, color: FhcColors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(subtitle, style: FhcTypography.caption),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _rating(String label, int stars) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        for (var index = 0; index < 5; index++)
          Icon(
            index < stars ? Icons.star : Icons.star_border,
            size: 20,
            color: FhcColors.orange,
          ),
      ],
    ),
  );
}

class _KcaSpec {
  const _KcaSpec(this.title, this.action, this.next, this.step, [this.total]);
  final String title;
  final String? action;
  final String? next;
  final int? step;
  final int? total;
}

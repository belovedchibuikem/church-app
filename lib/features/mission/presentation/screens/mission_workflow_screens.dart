import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/mission_repository.dart';

class MissionPartnersScreen extends StatelessWidget {
  const MissionPartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const partners = [
      ('Hope Africa Mission', 'Kenya', true),
      ('Light for All', 'Philippines', true),
      ('Grace Outreach', 'USA', true),
      ('Water of Life', 'Tanzania', true),
      ('Faith Builders', 'Ghana', false),
      ('Compassion Works', 'Brazil', true),
    ];
    return WorkflowPage(
      title: 'Mission Partners',
      domain: WorkflowDomain.mission,
      actionLabel: 'Add Mission Partner',
      children: [
        const WorkflowSummary(
          title: 'Partner Network',
          metrics: [
            ('18', 'Total Partners'),
            ('14', 'Active'),
            ('7', 'Countries'),
          ],
        ),
        const SizedBox(height: 10),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (final partner in partners)
                WorkflowRow(
                  title: partner.$1,
                  subtitle: partner.$2,
                  leading: Icons.public_outlined,
                  trailing: WorkflowPill(partner.$3 ? 'Active' : 'Inactive'),
                  onTap: () => fhcPush(context, '/mission/partner'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class MissionPartnerDetailsScreen extends StatelessWidget {
  const MissionPartnerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Mission Partner Details',
      domain: WorkflowDomain.mission,
      actionLabel: 'Support Mission',
      onAction: () => fhcPush(context, '/mission/support'),
      children: [
        const WorkflowSummary(
          title: 'Hope Africa Mission',
          subtitle: 'Kenya',
          metrics: [],
          imageAsset: 'assets/images/mission_banner.png',
        ),
        const WorkflowSectionTitle('About'),
        const Text(
          'Reaching communities with the gospel and humanitarian help.',
          style: FhcTypography.body,
        ),
        const SizedBox(height: 12),
        const WorkflowSummary(
          title: 'Impact',
          metrics: [
            ('24', 'Partners'),
            ('850', 'Lives Impacted'),
            ('4', 'Projects'),
          ],
        ),
        const WorkflowSectionTitle('Current Need'),
        const WorkflowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build a Classroom Block',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              WorkflowProgress(
                label: 'Raised: ₦1,200,000 of ₦2,000,000',
                value: .60,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SupportMissionScreen extends StatelessWidget {
  const SupportMissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Support Mission',
      domain: WorkflowDomain.mission,
      actionLabel: 'Support Now',
      children: const [
        WorkflowSummary(
          title: 'Hope Africa Mission',
          subtitle:
              'Kenya\nReaching communities with the gospel and humanitarian help.',
          metrics: [],
          imageAsset: 'assets/images/mission_banner.png',
        ),
        WorkflowSectionTitle('Current Need'),
        WorkflowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build a Classroom Block',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              WorkflowProgress(
                label: 'Raised: ₦1,200,000 of ₦2,000,000',
                value: .60,
              ),
            ],
          ),
        ),
        WorkflowSectionTitle('Your Support'),
        WorkflowSegments(labels: ['₦5,000', '₦10,000', '₦20,000'], selected: 0),
        SizedBox(height: 12),
        WorkflowField(label: 'Other Amount', value: '₦  0.00'),
        WorkflowRow(
          title: 'Make it recurring',
          leading: Icons.repeat,
          trailing: Switch(value: false, onChanged: null),
        ),
      ],
    );
  }
}

class InviteCrusadeScreen extends StatelessWidget {
  const InviteCrusadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Invite Us for a Crusade',
      domain: WorkflowDomain.mission,
      actionLabel: 'Continue',
      onAction: () => fhcPush(context, '/mission/request-status'),
      children: const [
        WorkflowSummary(
          title: "Let's reach your city for Christ together.",
          subtitle: 'We would love to partner with you in a powerful crusade.',
          metrics: [],
          imageAsset: 'assets/images/crusade_crowd.png',
        ),
        WorkflowSectionTitle('Event Details'),
        WorkflowField(
          label: 'Full Name',
          value: 'Pastor John Doe',
          required: true,
        ),
        WorkflowField(
          label: 'Email Address',
          value: 'john.doe@gmail.com',
          required: true,
        ),
        WorkflowField(
          label: 'Phone Number',
          value: '+234 812 345 6789',
          required: true,
        ),
        WorkflowField(
          label: 'Church / Organization',
          value: 'Grace Family Church',
          required: true,
        ),
        WorkflowField(label: 'City', value: 'Lagos', required: true),
      ],
    );
  }
}

class CrusadeRequestStatusScreen extends StatelessWidget {
  const CrusadeRequestStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Crusade Request',
      domain: WorkflowDomain.mission,
      actionLabel: 'View Details',
      children: [
        const WorkflowCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request ID', style: FhcTypography.caption),
                    Text(
                      'CRS-2025-00078',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Submitted on May 16, 2025',
                      style: FhcTypography.caption,
                    ),
                  ],
                ),
              ),
              WorkflowPill('Pending', color: FhcColors.gold),
            ],
          ),
        ),
        const WorkflowSectionTitle('Status Progress'),
        WorkflowCard(
          child: Column(
            children: const [
              WorkflowRow(
                title: 'Request Submitted',
                subtitle: 'May 16, 2025',
                leading: Icons.check_circle,
                trailing: WorkflowPill('Done'),
              ),
              WorkflowRow(
                title: 'Under Review',
                subtitle: 'Our team is reviewing your request.',
                leading: Icons.timelapse,
                trailing: WorkflowPill('Current', color: FhcColors.gold),
              ),
              WorkflowRow(
                title: 'Approved',
                leading: Icons.radio_button_unchecked,
                trailing: SizedBox.shrink(),
              ),
              WorkflowRow(
                title: 'Scheduled',
                leading: Icons.radio_button_unchecked,
                trailing: SizedBox.shrink(),
              ),
              WorkflowRow(
                title: 'Completed',
                leading: Icons.radio_button_unchecked,
                trailing: SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const WorkflowSectionTitle('Request Summary'),
        const WorkflowCard(
          child: Column(
            children: [
              WorkflowRow(
                title: 'Location',
                subtitle: 'Lagos, Nigeria',
                leading: Icons.location_on_outlined,
              ),
              WorkflowRow(
                title: 'Proposed Date',
                subtitle: 'June 20 - 22, 2025',
                leading: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddSoulScreen extends StatefulWidget {
  const AddSoulScreen({super.key, this.repository});

  final MissionRepository? repository;

  @override
  State<AddSoulScreen> createState() => _AddSoulScreenState();
}

class _AddSoulScreenState extends State<AddSoulScreen> {
  late final TextEditingController _crusadeId;
  late final TextEditingController _givenName;
  late final TextEditingController _familyName;
  late final TextEditingController _preferredName;
  late final TextEditingController _personId;
  bool _submitting = false;
  String? _error;
  String? _successId;

  MissionRepository? get _repo =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.missionRepository;

  @override
  void initState() {
    super.initState();
    _crusadeId = TextEditingController();
    _givenName = TextEditingController();
    _familyName = TextEditingController();
    _preferredName = TextEditingController();
    _personId = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_crusadeId.text.isEmpty) {
      final fromRoute = FhcRouteArgs.entityIdOf(context);
      if (fromRoute != null && looksLikeMissionUlid(fromRoute)) {
        _crusadeId.text = fromRoute;
      }
    }
  }

  @override
  void dispose() {
    _crusadeId.dispose();
    _givenName.dispose();
    _familyName.dispose();
    _preferredName.dispose();
    _personId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error =
            'Mission repository is not wired. Soul capture was not submitted.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _successId = null;
    });

    final personId = _personId.text.trim();
    final result = await repo.createSoul({
      'crusade_id': _crusadeId.text.trim(),
      if (personId.isNotEmpty) 'person_id': personId,
      'given_name': _givenName.text.trim(),
      'family_name': _familyName.text.trim(),
      if (_preferredName.text.trim().isNotEmpty)
        'preferred_name': _preferredName.text.trim(),
    });

    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        final id = (value['id'] as String?)?.trim();
        setState(() {
          _submitting = false;
          _successId = id;
        });
        if (id != null && id.isNotEmpty) {
          fhcPush(context, '/mission/soul/$id');
        }
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
      title: 'Add a Soul',
      domain: WorkflowDomain.mission,
      actionLabel: _submitting ? 'Saving…' : 'Save Soul',
      onAction: _submitting ? () {} : _save,
      children: [
        const WorkflowSectionTitle('Capture against crusade'),
        _EditableField(
          label: 'Crusade ID (ULID)',
          controller: _crusadeId,
          required: true,
          hint: 'From crusade detail',
        ),
        _EditableField(
          label: 'Person ID (optional ULID)',
          controller: _personId,
          hint: 'Skip names if linking an existing person',
        ),
        const WorkflowSectionTitle('Personal Information'),
        _EditableField(
          label: 'Given name',
          controller: _givenName,
          required: true,
        ),
        _EditableField(
          label: 'Family name',
          controller: _familyName,
          required: true,
        ),
        _EditableField(
          label: 'Preferred name (optional)',
          controller: _preferredName,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: FhcColors.red, fontSize: 12),
          ),
        ],
        if (_successId != null) ...[
          const SizedBox(height: 8),
          Text(
            'Captured soul journey $_successId',
            style: const TextStyle(color: FhcColors.green, fontSize: 12),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Uses POST /admin/mission/crusades/{crusade}/souls. '
          'No invented soul IDs — success only after the platform returns data.id.',
          style: FhcTypography.caption,
        ),
      ],
    );
  }
}

class SoulProfileScreen extends StatefulWidget {
  const SoulProfileScreen({super.key, this.repository});

  final MissionRepository? repository;

  @override
  State<SoulProfileScreen> createState() => _SoulProfileScreenState();
}

class _SoulProfileScreenState extends State<SoulProfileScreen> {
  bool _loading = true;
  String? _error;
  String? _soulId;
  JsonObject? _soul;

  MissionRepository? get _repo =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.missionRepository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = FhcRouteArgs.entityIdOf(context) ??
        missionSoulIdFromRoute(ModalRoute.of(context)?.settings.name);
    setState(() {
      _soulId = id;
      _loading = true;
      _error = null;
      _soul = null;
    });

    if (id == null || !looksLikeMissionUlid(id)) {
      setState(() {
        _loading = false;
        _error =
            'Open a soul from the follow-up list. Soul detail needs a real journey ULID — none was provided.';
      });
      return;
    }

    final repo = _repo;
    if (repo == null) {
      setState(() {
        _loading = false;
        _error = 'Mission repository is not wired.';
      });
      return;
    }

    final result = await repo.getSoul(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _soul = value;
          _loading = false;
        });
      case AppError(:final failure):
        setState(() {
          _loading = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _soulId;
    return WorkflowPage(
      title: 'Soul Profile & Follow-up',
      domain: WorkflowDomain.mission,
      actionLabel: 'Assign Mentor',
      onAction: id != null && looksLikeMissionUlid(id)
          ? () => fhcPush(context, '${FhcRoutes.mentorAssignment}?id=$id')
          : () => fhcApiUnavailable(
                context,
                action: missionSoulOpsUnavailableAction,
              ),
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator.adaptive()),
          )
        else if (_soul != null) ...[
          WorkflowCard(
            child: WorkflowRow(
              title: (_soul!['id'] as String?) ?? 'Soul journey',
              subtitle:
                  'Status: ${(_soul!['status'] as String?) ?? '—'} · Crusade: ${(_soul!['crusade_id'] as String?) ?? '—'}',
              leading: Icons.person_outline,
              trailing: const SizedBox.shrink(),
            ),
          ),
        ] else ...[
          WorkflowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id == null ? 'No soul selected' : 'Soul $id',
                  style: FhcTypography.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ??
                      'Soul detail is not available separately. List and capture responses remain the source of truth.',
                  style: FhcTypography.caption,
                ),
                if (id != null && looksLikeMissionUlid(id)) ...[
                  const SizedBox(height: 12),
                  FhcPrimaryButton(
                    label: 'Assign Mentor',
                    onPressed: () => fhcPush(
                      context,
                      '${FhcRoutes.mentorAssignment}?id=$id',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const WorkflowSectionTitle('Follow-up'),
        if (id != null && looksLikeMissionUlid(id))
          SoulFollowUpForm(
            soulId: id,
            mentorAssignmentId:
                (_soul?['mentor_assignment_id'] as String?)?.trim(),
            repository: _repo,
          )
        else
          const WorkflowCard(
            child: Text(
              'Open a soul from the follow-up list to record or complete '
              'follow-up. A journey ULID is required.',
              style: FhcTypography.caption,
            ),
          ),
      ],
    );
  }
}

class AssignMentorScreen extends StatefulWidget {
  const AssignMentorScreen({super.key, this.repository});

  final MissionRepository? repository;

  @override
  State<AssignMentorScreen> createState() => _AssignMentorScreenState();
}

class _AssignMentorScreenState extends State<AssignMentorScreen> {
  late final TextEditingController _soulId;
  late final TextEditingController _teamAssignmentId;
  bool _submitting = false;
  String? _error;
  String? _info;

  MissionRepository? get _repo =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.missionRepository;

  @override
  void initState() {
    super.initState();
    _soulId = TextEditingController();
    _teamAssignmentId = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_soulId.text.isEmpty) {
      final fromRoute = FhcRouteArgs.entityIdOf(context) ??
          missionSoulIdFromRoute(ModalRoute.of(context)?.settings.name);
      if (fromRoute != null && looksLikeMissionUlid(fromRoute)) {
        _soulId.text = fromRoute;
      }
    }
  }

  @override
  void dispose() {
    _soulId.dispose();
    _teamAssignmentId.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error = 'Mission repository is not wired. Assignment was not submitted.';
        _info = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _info = null;
    });

    final result = await repo.assignMentor(
      _soulId.text.trim(),
      _teamAssignmentId.text.trim(),
    );

    if (!mounted) return;
    switch (result) {
      case AppSuccess():
        setState(() {
          _submitting = false;
          _info =
              'Mentor assignment accepted for soul ${_soulId.text.trim()}.';
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
      title: 'Assign Mentor',
      domain: WorkflowDomain.mission,
      actionLabel: _submitting ? 'Assigning…' : 'Assign Mentor',
      onAction: _submitting ? () {} : _assign,
      children: [
        const WorkflowSectionTitle('Server assignment'),
        _EditableField(
          label: 'Soul journey ID (ULID)',
          controller: _soulId,
          required: true,
          hint: 'From capture or souls list',
        ),
        _EditableField(
          label: 'Mission team assignment ID (ULID)',
          controller: _teamAssignmentId,
          required: true,
          hint: 'mission_team_assignment_id — not a display name',
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: FhcColors.red, fontSize: 12),
          ),
        ],
        if (_info != null) ...[
          const SizedBox(height: 8),
          Text(
            _info!,
            style: const TextStyle(color: FhcColors.green, fontSize: 12),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Uses POST /admin/mission/souls/{soul}/mentor-assignment. '
          'Success is shown only after a 2xx response — no invented mentor names.',
          style: FhcTypography.caption,
        ),
      ],
    );
  }
}

class SoulFollowUpForm extends StatefulWidget {
  const SoulFollowUpForm({
    super.key,
    required this.soulId,
    this.mentorAssignmentId,
    this.repository,
  });

  final String soulId;
  final String? mentorAssignmentId;
  final MissionRepository? repository;

  @override
  State<SoulFollowUpForm> createState() => _SoulFollowUpFormState();
}

class _SoulFollowUpFormState extends State<SoulFollowUpForm> {
  late final TextEditingController _mentorAssignmentId;
  late final TextEditingController _channelCode;
  late final TextEditingController _outcomeCode;
  late final TextEditingController _occurredAt;
  late final TextEditingController _reasonCode;
  bool _recording = false;
  bool _completing = false;
  String? _error;
  String? _info;

  MissionRepository? get _repo =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.missionRepository;

  @override
  void initState() {
    super.initState();
    _mentorAssignmentId = TextEditingController(
      text: widget.mentorAssignmentId ?? '',
    );
    _channelCode = TextEditingController();
    _outcomeCode = TextEditingController();
    _occurredAt = TextEditingController(
      text: DateTime.now()
          .toUtc()
          .subtract(const Duration(seconds: 1))
          .toIso8601String(),
    );
    _reasonCode = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant SoulFollowUpForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mentorAssignmentId != null &&
        widget.mentorAssignmentId != oldWidget.mentorAssignmentId &&
        _mentorAssignmentId.text.trim().isEmpty) {
      _mentorAssignmentId.text = widget.mentorAssignmentId!;
    }
  }

  @override
  void dispose() {
    _mentorAssignmentId.dispose();
    _channelCode.dispose();
    _outcomeCode.dispose();
    _occurredAt.dispose();
    _reasonCode.dispose();
    super.dispose();
  }

  Future<void> _record() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error =
            'Mission repository is not wired. Follow-up was not submitted.';
        _info = null;
      });
      return;
    }
    setState(() {
      _recording = true;
      _error = null;
      _info = null;
    });
    final result = await repo.recordFollowUp(widget.soulId, {
      'mentor_assignment_id': _mentorAssignmentId.text.trim(),
      'channel_code': _channelCode.text.trim(),
      'outcome_code': _outcomeCode.text.trim(),
      'occurred_at': _occurredAt.text.trim(),
    });
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _recording = false;
          _info =
              'Follow-up recorded (${value['id'] ?? value['outcome_code'] ?? 'accepted'}).';
        });
      case AppError(:final failure):
        setState(() {
          _recording = false;
          _error = failure.message;
        });
    }
  }

  Future<void> _complete() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error =
            'Mission repository is not wired. Completion was not submitted.';
        _info = null;
      });
      return;
    }
    setState(() {
      _completing = true;
      _error = null;
      _info = null;
    });
    final result = await repo.completeFollowUp(widget.soulId, {
      'reason_code': _reasonCode.text.trim(),
    });
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _completing = false;
          _info =
              'Follow-up completed (${value['status'] ?? value['id'] ?? 'accepted'}).';
        });
      case AppError(:final failure):
        setState(() {
          _completing = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _recording || _completing;
    return WorkflowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POST /admin/mission/souls/{soul}/follow-ups and '
            'follow-up-completion. Success is shown only after a 2xx '
            'response — no invented timeline.',
            style: FhcTypography.caption,
          ),
          const SizedBox(height: 12),
          _EditableField(
            label: 'Mentor assignment ID (ULID)',
            controller: _mentorAssignmentId,
            required: true,
            hint: 'From assign mentor response',
          ),
          _EditableField(
            label: 'Channel code',
            controller: _channelCode,
            required: true,
            hint: 'e.g. phone',
          ),
          _EditableField(
            label: 'Outcome code',
            controller: _outcomeCode,
            required: true,
            hint: 'e.g. connected',
          ),
          _EditableField(
            label: 'Occurred at (ISO-8601)',
            controller: _occurredAt,
            required: true,
            hint: 'Must be now or earlier',
          ),
          FhcPrimaryButton(
            label: _recording ? 'Recording…' : 'Record follow-up',
            onPressed: busy ? null : _record,
          ),
          const SizedBox(height: 16),
          _EditableField(
            label: 'Completion reason code',
            controller: _reasonCode,
            required: true,
            hint: 'e.g. discipleship_connected',
          ),
          FhcPrimaryButton(
            label: _completing ? 'Completing…' : 'Complete follow-up',
            onPressed: busy ? null : _complete,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: FhcColors.red, fontSize: 12),
            ),
          ],
          if (_info != null) ...[
            const SizedBox(height: 8),
            Text(
              _info!,
              style: const TextStyle(color: FhcColors.green, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: FhcTypography.label,
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: FhcColors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: FhcColors.hint),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FhcColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FhcColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MissionTeamsScreen extends StatelessWidget {
  const MissionTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const teams = [
      ('Evangelism Team', 'Sharing the Gospel in the streets', 12),
      ('Prayer Warriors', 'Interceding for nations', 18),
      ('Media Team', 'Sound, Video & Livestream', 10),
      ('Logistics Team', 'Planning & Coordination', 15),
      ('Counseling Team', 'Soul Care & Support', 8),
      ('Follow-up Team', 'New Convert Care', 14),
    ];
    return WorkflowPage(
      title: 'Mission Teams',
      domain: WorkflowDomain.mission,
      children: [
        const WorkflowField(
          label: 'Search',
          value: 'Search teams...',
          icon: Icons.tune,
        ),
        const WorkflowSegments(labels: ['All', 'Active', 'Upcoming', 'Mine']),
        const SizedBox(height: 10),
        WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (final team in teams)
                WorkflowRow(
                  title: team.$1,
                  subtitle: team.$2,
                  leading: Icons.groups_outlined,
                  trailing: WorkflowPill('${team.$3}'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class MissionSupportRequestScreen extends StatelessWidget {
  const MissionSupportRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Request Support',
      domain: WorkflowDomain.mission,
      actionLabel: 'Submit Request',
      children: const [
        WorkflowField(
          label: 'Support Type',
          value: 'Financial Support',
          required: true,
          icon: Icons.keyboard_arrow_down,
        ),
        WorkflowField(
          label: 'Project / Need',
          value: 'Build a Classroom Block',
          required: true,
        ),
        WorkflowField(
          label: 'Description',
          value:
              'We need support to build a classroom block for our community outreach school.',
          lines: 4,
          required: true,
        ),
        WorkflowField(
          label: 'Amount Needed (₦)',
          value: '2,000,000',
          required: true,
        ),
        WorkflowField(
          label: 'Target Date',
          value: 'Aug 30, 2025',
          required: true,
          icon: Icons.calendar_today_outlined,
        ),
        WorkflowUploadBox(label: 'Add documents or photos'),
      ],
    );
  }
}

class MissionAssignmentsScreen extends StatelessWidget {
  const MissionAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'My Assignments',
      domain: WorkflowDomain.mission,
      actionLabel: 'Next',
      children: const [
        WorkflowSegments(labels: ['Project', '2', '3', '4']),
        WorkflowSectionTitle('Personal Information'),
        WorkflowField(
          label: 'Full Name',
          value: 'John Emmanuel',
          required: true,
        ),
        WorkflowField(
          label: 'Date of Birth',
          value: 'June 12, 2001',
          required: true,
          icon: Icons.calendar_today_outlined,
        ),
        WorkflowSegments(labels: ['Male', 'Female']),
        SizedBox(height: 12),
        WorkflowField(
          label: 'Phone Number',
          value: '+234 810 123 4567',
          required: true,
        ),
        WorkflowField(
          label: 'Email Address',
          value: 'jemmanuel@example.com',
          required: true,
        ),
      ],
    );
  }
}

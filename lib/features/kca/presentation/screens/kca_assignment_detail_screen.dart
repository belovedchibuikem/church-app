import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../kca_assignment_kind.dart';

class KcaAssignmentDetailScreen extends StatefulWidget {
  const KcaAssignmentDetailScreen({
    super.key,
    this.assignmentId,
    this.kcaRepository,
  });

  final String? assignmentId;
  final KcaRepository? kcaRepository;

  @override
  State<KcaAssignmentDetailScreen> createState() =>
      _KcaAssignmentDetailScreenState();
}

class _KcaAssignmentDetailScreenState extends State<KcaAssignmentDetailScreen> {
  FhcAsyncValue<JsonObject> _state = const FhcAsyncValue.loading();
  bool _busy = false;
  String? _status;
  final _givenName = TextEditingController();
  final _familyName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();
  String? _parentId;

  KcaRepository? get _repo =>
      widget.kcaRepository ??
      AppServicesScope.maybeOf(context)?.kcaRepository;

  String? get _resolvedId {
    final explicit = widget.assignmentId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final fromArgs = FhcRouteArgs.entityIdOf(context);
    if (fromArgs != null && fromArgs.trim().isNotEmpty) return fromArgs.trim();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is FhcRouteArgs && args.extra is String) {
      final extra = (args.extra as String).trim();
      if (extra.isNotEmpty) return extra;
    }
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final id = args['id'] ?? args['assignmentId'] ?? args['entityId'];
      if (id is String && id.trim().isNotEmpty) return id.trim();
    }

    final name = ModalRoute.of(context)?.settings.name ?? '';
    final uri = Uri.tryParse(name);
    final queryId = uri?.queryParameters['id'];
    if (queryId != null && queryId.trim().isNotEmpty) return queryId.trim();

    final parts = name.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 3 && parts[0] == 'kca' && parts[1] == 'assignment') {
      return parts[2].split('?').first;
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) {
      _load();
    }
  }

  @override
  void dispose() {
    _givenName.dispose();
    _familyName.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = _repo;
    final id = _resolvedId;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.kca.assignmentRequireApi',
            fallback:
                'Assignment detail requires the member curriculum API. '
                'No design fixtures are shown.',
          ),
        );
      });
      return;
    }
    if (id == null || id.isEmpty) {
      setState(() {
        _state = FhcAsyncValue.error(
          const ValidationFailure('Assignment id is required.'),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.getAssignment(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _state = FhcAsyncValue.data(value);
          _status = null;
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.kcaAssignments);
    }
  }

  Future<void> _recordSoul(JsonObject assignment) async {
    final repo = _repo;
    final id = '${assignment['id'] ?? ''}'.trim();
    final given = _givenName.text.trim();
    if (repo == null || id.isEmpty) return;
    if (given.isEmpty) {
      setState(() => _status = 'Enter the soul’s given name.');
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await repo.recordSoulWin(id, {
      'given_name': given,
      if (_familyName.text.trim().isNotEmpty)
        'family_name': _familyName.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      if (_parentId != null && _parentId!.isNotEmpty) 'parent_id': _parentId,
    });
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case AppSuccess():
        _givenName.clear();
        _familyName.clear();
        _phone.clear();
        _email.clear();
        _notes.clear();
        _parentId = null;
        await _load();
      case AppError(:final failure):
        setState(() => _status = failure.message);
    }
  }

  Future<void> _pickAndUpload(JsonObject assignment, {required bool video}) async {
    final repo = _repo;
    final id = '${assignment['id'] ?? ''}'.trim();
    if (repo == null || id.isEmpty) return;
    final kind = parseKcaAssignmentKind(assignment['assignment_kind']);
    final picked = await FilePicker.pickFiles(
      withData: true,
      type: video
          ? FileType.video
          : kind == KcaAssignmentKind.written
          ? FileType.custom
          : FileType.image,
      allowedExtensions:
          video
              ? null
              : kind == KcaAssignmentKind.written
              ? const ['jpg', 'jpeg', 'png', 'pdf']
              : null,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _status = 'That file could not be read. Try another photo or video.');
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await repo.submitEvidence({
      'assignment_id': id,
      'filename': file.name,
      'bytes': bytes,
    });
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _status =
              value['queued'] == true
                  ? 'Saved on this device. It will upload when you are online.'
                  : 'Photo or video was submitted.';
        });
        await _load();
      case AppError(:final failure):
        setState(() => _status = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'member.kca.assignmentDetail',
              fallback: 'ASSIGNMENT',
            ),
            onBack: _back,
          ),
          Expanded(
            child: FhcAsyncBody<JsonObject>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'member.kca.assignmentMissing',
                fallback: 'Assignment unavailable',
              ),
              unavailableTitle: fhcT(
                context,
                'member.kca.assignmentUnavailable',
                fallback: 'Assignment unavailable',
              ),
              builder: (context, assignment) => _body(assignment),
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }

  Widget _body(JsonObject assignment) {
    final kind = parseKcaAssignmentKind(assignment['assignment_kind']);
    final title = '${assignment['title'] ?? 'Assignment'}';
    final state = '${assignment['state'] ?? ''}';
    final module = assignment['module'];
    final lesson = assignment['lesson'];
    final moduleTitle =
        module is Map ? '${module['title'] ?? module['code'] ?? ''}' : '';
    final lessonTitle =
        lesson is Map ? '${lesson['title'] ?? lesson['code'] ?? ''}' : '';
    final due = '${assignment['due_at'] ?? ''}'.trim();
    final tree = assignment['soul_tree'];
    final treeMap = tree is Map ? Map<String, Object?>.from(tree) : null;
    final evidence = assignment['evidence'];
    final evidenceItems =
        evidence is List
            ? [
                for (final item in evidence)
                  if (item is Map)
                    <String, Object?>{
                      for (final entry in item.entries)
                        '${entry.key}': entry.value,
                    },
              ]
            : const <Map<String, Object?>>[];
    final requiresMedia =
        assignment['requires_media'] == true ||
        kcaAssignmentRequiresMedia(kind);
    final canAct =
        !state.contains('approved') &&
        !state.contains('final') &&
        !state.contains('admin');

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _HeaderCard(
          title: title,
          kind: kind,
          state: state,
          moduleTitle: moduleTitle,
          lessonTitle: lessonTitle,
          due: due,
        ),
        if (_status != null) ...[
          const SizedBox(height: 12),
          Text(
            _status!,
            style: const TextStyle(fontSize: 13, color: FhcColors.ink, height: 1.3),
          ),
        ],
        if (kind == KcaAssignmentKind.soulWinning) ...[
          const SizedBox(height: 16),
          _SoulTreeCard(
            tree: treeMap,
            parentId: _parentId,
            givenName: _givenName,
            familyName: _familyName,
            phone: _phone,
            email: _email,
            notes: _notes,
            busy: _busy || !canAct,
            onParentChanged: (value) => setState(() => _parentId = value),
            onSave: () => _recordSoul(assignment),
          ),
        ] else ...[
          const SizedBox(height: 16),
          _KindGuidance(kind: kind),
        ],
        if (requiresMedia) ...[
          const SizedBox(height: 16),
          _MediaCard(
            kind: kind,
            evidence: evidenceItems,
            busy: _busy || !canAct,
            onPhoto: () => _pickAndUpload(assignment, video: false),
            onVideo: () => _pickAndUpload(assignment, video: true),
          ),
        ],
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.kind,
    required this.state,
    required this.moduleTitle,
    required this.lessonTitle,
    required this.due,
  });

  final String title;
  final KcaAssignmentKind kind;
  final String state;
  final String moduleTitle;
  final String lessonTitle;
  final String due;

  @override
  Widget build(BuildContext context) {
    final scope = [
      if (moduleTitle.isNotEmpty) moduleTitle,
      if (lessonTitle.isNotEmpty) lessonTitle,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FhcColors.white,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        border: Border.all(color: FhcColors.border),
        boxShadow: FhcElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kcaAssignmentKindColor(kind),
                  borderRadius: BorderRadius.circular(FhcRadius.sm),
                ),
                child: Icon(
                  kcaAssignmentKindIcon(kind),
                  size: 20,
                  color: FhcColors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: kcaAssignmentKindLabel(kind)),
              if (state.isNotEmpty) _Chip(label: state.replaceAll('_', ' ')),
            ],
          ),
          if (scope.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              scope,
              style: const TextStyle(fontSize: 13, color: FhcColors.muted, height: 1.3),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            due.isEmpty
                ? fhcT(context, 'member.kca.noDueDate', fallback: 'No due date')
                : due,
            style: const TextStyle(fontSize: 12, color: FhcColors.muted),
          ),
        ],
      ),
    );
  }
}

class _KindGuidance extends StatelessWidget {
  const _KindGuidance({required this.kind});

  final KcaAssignmentKind kind;

  @override
  Widget build(BuildContext context) {
    final message = switch (kind) {
      KcaAssignmentKind.practical =>
        'This practical assignment needs photo or video evidence of the work you completed.',
      KcaAssignmentKind.written =>
        'This written assignment accepts a document, photo, or scan of your work.',
      KcaAssignmentKind.standard =>
        'Review this assignment and complete it according to your lesson instructions.',
      KcaAssignmentKind.soulWinning =>
        'Record each soul in the winning tree. Photos or videos can be attached below.',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FhcColors.white,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        border: Border.all(color: FhcColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: FhcColors.ink, height: 1.35),
      ),
    );
  }
}

class _SoulTreeCard extends StatelessWidget {
  const _SoulTreeCard({
    required this.tree,
    required this.parentId,
    required this.givenName,
    required this.familyName,
    required this.phone,
    required this.email,
    required this.notes,
    required this.busy,
    required this.onParentChanged,
    required this.onSave,
  });

  final Map<String, Object?>? tree;
  final String? parentId;
  final TextEditingController givenName;
  final TextEditingController familyName;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController notes;
  final bool busy;
  final ValueChanged<String?> onParentChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final recorded = '${tree?['recorded_souls'] ?? 0}';
    final required = '${tree?['required_souls'] ?? 0}';
    final complete = tree?['complete'] == true;
    final open = tree?['open'] == true;
    final nodes = flattenKcaSoulTree(tree?['tree']);
    final parentItems = [
      const DropdownMenuItem<String>(
        value: '',
        child: Text('First generation (no parent)'),
      ),
      for (final node in nodes)
        DropdownMenuItem<String>(
          value: '${node['id'] ?? ''}',
          child: Text(
            [
              '${node['given_name'] ?? 'Soul'}',
              if ('${node['family_name'] ?? ''}'.trim().isNotEmpty)
                '${node['family_name']}',
              '(depth ${node['depth'] ?? 1})',
            ].join(' '),
          ),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FhcColors.white,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        border: Border.all(color: FhcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Soul-winning tree',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            complete
                ? 'Required souls are complete ($recorded/$required).'
                : 'Record $recorded of $required required souls. Keep going until every generation is filled.',
            style: const TextStyle(fontSize: 13, color: FhcColors.muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (nodes.isEmpty)
            const Text(
              'No souls recorded yet. Add the first soul you won.',
              style: TextStyle(fontSize: 13, color: FhcColors.ink),
            )
          else
            ...nodes.map((node) {
              final children = node['children'];
              final childCount = children is List ? children.length : 0;
              return Padding(
                padding: EdgeInsets.only(
                  left: (((node['depth'] as num?)?.toInt() ?? 1) - 1) * 12.0,
                  bottom: 8,
                ),
                child: Text(
                  '${node['given_name'] ?? 'Soul'} ${node['family_name'] ?? ''} · depth ${node['depth'] ?? 1} · $childCount discipled'
                      .trim(),
                  style: const TextStyle(fontSize: 13, color: FhcColors.ink, height: 1.3),
                ),
              );
            }),
          if (open) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: parentId ?? '',
              items: parentItems,
              onChanged: busy ? null : (value) => onParentChanged(value?.isEmpty == true ? null : value),
              decoration: const InputDecoration(
                labelText: 'Won through (parent soul)',
              ),
            ),
            const SizedBox(height: 8),
            FhcField(
              label: 'Given name',
              hint: 'First name',
              controller: givenName,
            ),
            const SizedBox(height: 8),
            FhcField(
              label: 'Family name',
              hint: 'Optional',
              controller: familyName,
            ),
            const SizedBox(height: 8),
            FhcField(
              label: 'Phone',
              hint: 'Optional',
              controller: phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            FhcField(
              label: 'Email',
              hint: 'Optional',
              controller: email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            FhcField(
              label: 'Notes',
              hint: 'Optional follow-up notes',
              controller: notes,
            ),
            const SizedBox(height: 12),
            FhcPrimaryButton(
              label: busy ? 'Saving…' : 'Record soul',
              onPressed: busy ? null : onSave,
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.kind,
    required this.evidence,
    required this.busy,
    required this.onPhoto,
    required this.onVideo,
  });

  final KcaAssignmentKind kind;
  final List<Map<String, Object?>> evidence;
  final bool busy;
  final VoidCallback onPhoto;
  final VoidCallback onVideo;

  @override
  Widget build(BuildContext context) {
    final photoLabel = kind == KcaAssignmentKind.written
        ? 'Upload photo or document'
        : 'Upload photo';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FhcColors.white,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        border: Border.all(color: FhcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photos and videos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            kind == KcaAssignmentKind.soulWinning
                ? 'Attach photos or videos of the souls you won or the work you did. The assignment stays open until the tree is complete.'
                : 'Upload the pictures or videos this assignment requires.',
            style: const TextStyle(fontSize: 13, color: FhcColors.muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          FhcPrimaryButton(
            label: busy ? 'Uploading…' : photoLabel,
            onPressed: busy ? null : onPhoto,
          ),
          const SizedBox(height: 8),
          FhcPrimaryButton(
            label: busy ? 'Uploading…' : 'Upload video',
            onPressed: busy ? null : onVideo,
          ),
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final item in evidence)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${item['filename'] ?? 'Evidence'} · ${item['submitted_at'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: FhcColors.ink),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FhcColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: FhcColors.greenDark,
        ),
      ),
    );
  }
}

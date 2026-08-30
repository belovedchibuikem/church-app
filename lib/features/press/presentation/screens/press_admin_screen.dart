import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

/// Press admin create: optional content file → platform file asset → publication.
class PressAdminScreen extends StatefulWidget {
  const PressAdminScreen({super.key, this.repository});

  final PressRepository? repository;

  @override
  State<PressAdminScreen> createState() => _PressAdminScreenState();
}

class _PressAdminScreenState extends State<PressAdminScreen> {
  final _title = TextEditingController();
  String _format = 'pdf';
  bool _submitting = false;
  String? _message;
  String? _fileName;
  List<int>? _fileBytes;
  String? _uploadedAssetId;

  PressRepository? get _repo =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.pressRepository;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'epub',
        'mp3',
        'm4a',
        'wav',
        'mp4',
        'mov',
        'webm',
      ],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _message = 'Could not read the selected file into memory.';
        _fileName = null;
        _fileBytes = null;
        _uploadedAssetId = null;
      });
      return;
    }
    setState(() {
      _fileName = file.name;
      _fileBytes = bytes;
      _uploadedAssetId = null;
      _message = null;
      final lower = file.name.toLowerCase();
      if (lower.endsWith('.mp3') ||
          lower.endsWith('.m4a') ||
          lower.endsWith('.wav')) {
        _format = 'audio';
      } else if (lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.webm')) {
        _format = 'video';
      } else {
        _format = 'pdf';
      }
    });
  }

  Future<void> _submit() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _message =
            'Press admin create requires an authenticated press repository.';
      });
      return;
    }
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _message = 'Title is required.');
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
    });

    String? contentAssetId = _uploadedAssetId;
    final bytes = _fileBytes;
    final name = _fileName;
    if (contentAssetId == null && bytes != null && name != null) {
      final uploaded = await repo.uploadAdminFile(
        bytes: bytes,
        filename: name,
        purpose: 'press_content',
        classification: 'internal',
      );
      if (!mounted) return;
      switch (uploaded) {
        case AppSuccess(:final value):
          contentAssetId = '${value['id'] ?? ''}'.trim();
          if (contentAssetId.isEmpty) {
            setState(() {
              _submitting = false;
              _message = 'Upload succeeded without a file asset id.';
            });
            return;
          }
          _uploadedAssetId = contentAssetId;
        case AppError(:final failure):
          setState(() {
            _submitting = false;
            _message = failure.message;
          });
          return;
      }
    }

    final result = await repo.createPublication({
      'title': title,
      'format': _format,
      'publisher_name': 'Family House Press',
      'language_code': 'en',
      'category': _format == 'audio' || _format == 'video' ? 'sermon' : 'book',
      'description': 'Created from Family House Connect mobile press admin.',
      if (contentAssetId != null && contentAssetId.isNotEmpty)
        'content_file_asset_id': contentAssetId,
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _message = contentAssetId == null
              ? 'Created publication ${value['id'] ?? ''} (metadata only).'
              : 'Created publication ${value['id'] ?? ''} with file asset '
                  '$contentAssetId.';
          _fileBytes = null;
          _fileName = null;
          _uploadedAssetId = null;
          _title.clear();
        });
      case AppError(:final failure):
        setState(() => _message = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(context, 'press.admin', fallback: 'Press Admin'),
      domain: WorkflowDomain.press,
      actionLabel: _submitting
          ? fhcT(context, 'common.submitting', fallback: 'Submitting…')
          : fhcT(context, 'press.createPublication', fallback: 'Create'),
      onAction: _submitting ? null : _submit,
      children: [
        Text(
          fhcT(
            context,
            'press.adminUploadCopy',
            fallback:
                'Upload a content file to POST /admin/platform/files, then '
                'create the publication with that asset id. Requires '
                'platform.files.manage and press.publications.manage.',
          ),
          style: FhcTypography.body,
        ),
        const SizedBox(height: 16),
        WorkflowTextField(
          label: fhcT(context, 'press.title', fallback: 'Title'),
          controller: _title,
          required: true,
        ),
        Text(
          fhcT(context, 'press.format', fallback: 'Format'),
          style: FhcTypography.label,
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _format,
          items: const [
            DropdownMenuItem(value: 'pdf', child: Text('PDF')),
            DropdownMenuItem(value: 'audio', child: Text('Audio')),
            DropdownMenuItem(value: 'video', child: Text('Video')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _format = value);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _submitting ? null : _pickFile,
          icon: const Icon(Icons.upload_file),
          label: Text(
            _fileName == null
                ? fhcT(
                    context,
                    'press.chooseContentFile',
                    fallback: 'Choose content file',
                  )
                : _fileName!,
          ),
        ),
        if (_fileName != null) ...[
          const SizedBox(height: 8),
          Text(
            '${_fileBytes?.length ?? 0} bytes'
            '${_uploadedAssetId == null ? '' : ' · asset $_uploadedAssetId'}',
            style: FhcTypography.caption,
          ),
          TextButton(
            onPressed: _submitting
                ? null
                : () => setState(() {
                      _fileName = null;
                      _fileBytes = null;
                      _uploadedAssetId = null;
                    }),
            child: Text(
              fhcT(context, 'press.clearFile', fallback: 'Clear file'),
            ),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 16),
          Text(_message!, style: FhcTypography.caption),
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => fhcPush(context, FhcRoutes.press),
          child: Text(
            fhcT(context, 'press.backToLibrary', fallback: 'Back to library'),
          ),
        ),
      ],
    );
  }
}

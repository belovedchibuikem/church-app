import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../../shared/widgets/recent_mfa_challenge_sheet.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/profile_repository.dart';

/// Full-screen profile editor with photo upload via POST /user/files +
/// PUT /user/profile (`avatar_file_asset_id`).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.repository});

  final ProfileRepository? repository;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  LaravelProfileRepository? _repository;

  final _givenCtrl = TextEditingController();
  final _middleCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  final _preferredCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _email;
  String? _avatarFileId;
  Uint8List? _avatarBytes;
  Uint8List? _pendingPhotoBytes;
  String? _pendingPhotoName;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fromScope = AppServicesScope.maybeOf(context)?.profileRepository;
    _repository ??=
        widget.repository is LaravelProfileRepository
            ? widget.repository as LaravelProfileRepository
            : fromScope is LaravelProfileRepository
            ? fromScope
            : createProfileRepository() as LaravelProfileRepository;
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    _givenCtrl.dispose();
    _middleCtrl.dispose();
    _familyCtrl.dispose();
    _preferredCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await repository.getProfile();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        final profile = value['profile'];
        final profileMap =
            profile is Map
                ? Map<String, Object?>.from(
                  profile.map((k, v) => MapEntry('$k', v)),
                )
                : const <String, Object?>{};
        _givenCtrl.text = '${profileMap['given_name'] ?? ''}';
        _middleCtrl.text = '${profileMap['middle_name'] ?? ''}';
        _familyCtrl.text = '${profileMap['family_name'] ?? ''}';
        _preferredCtrl.text = '${profileMap['preferred_name'] ?? ''}';
        final avatarId = (profileMap['avatar_file_id'] as String?)?.trim();
        setState(() {
          _email = value['email'] as String?;
          _avatarFileId = avatarId;
          _loading = false;
        });
        if (avatarId != null && avatarId.isNotEmpty) {
          await _loadAvatar(avatarId);
        }
      case AppError(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  Future<void> _loadAvatar(String fileId) async {
    final repository = _repository;
    if (repository == null) return;
    final result = await repository.downloadAvatarBytes(fileId);
    if (!mounted) return;
    if (result case AppSuccess(:final value)) {
      setState(() => _avatarBytes = value);
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'account.unableToReadPhoto',
              fallback: 'Unable to read that photo. Try another image.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _pendingPhotoBytes = Uint8List.fromList(bytes);
      _pendingPhotoName = file.name;
    });
  }

  Future<void> _save() async {
    final repository = _repository;
    if (repository == null || _saving) return;

    final given = _givenCtrl.text.trim();
    final family = _familyCtrl.text.trim();
    if (given.isEmpty || family.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'account.nameRequired',
              fallback: 'Given name and family name are required.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    String? avatarId = _avatarFileId;
    final pending = _pendingPhotoBytes;
    if (pending != null) {
      var upload = await repository.uploadAvatar(
        bytes: pending,
        filename: _pendingPhotoName ?? 'avatar.jpg',
      );
      if (!mounted) return;
      if (upload case AppError(:final failure) when isRecentMfaRequired(failure)) {
        final verified = await showRecentMfaChallengeSheet(
          context,
          reason: honestMfaRequiredMessage(failure),
        );
        if (!mounted) return;
        if (!verified) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(honestMfaRequiredMessage(failure))),
          );
          return;
        }
        upload = await repository.uploadAvatar(
          bytes: pending,
          filename: _pendingPhotoName ?? 'avatar.jpg',
        );
        if (!mounted) return;
      }
      switch (upload) {
        case AppSuccess(:final value):
          avatarId =
              (value['id'] as String?)?.trim() ??
              (value['public_id'] as String?)?.trim();
        case AppError(:final failure):
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
          return;
      }
    }

    var result = await repository.updateProfile({
      'given_name': given,
      'middle_name': _middleCtrl.text.trim().isEmpty
          ? null
          : _middleCtrl.text.trim(),
      'family_name': family,
      'preferred_name': _preferredCtrl.text.trim().isEmpty
          ? null
          : _preferredCtrl.text.trim(),
      if (avatarId != null && avatarId.isNotEmpty)
        'avatar_file_asset_id': avatarId,
    });
    if (!mounted) return;

    if (result case AppError(:final failure) when isRecentMfaRequired(failure)) {
      final verified = await showRecentMfaChallengeSheet(
        context,
        reason: honestMfaRequiredMessage(failure),
      );
      if (!mounted) return;
      if (!verified) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(honestMfaRequiredMessage(failure))),
        );
        return;
      }
      result = await repository.updateProfile({
        'given_name': given,
        'middle_name': _middleCtrl.text.trim().isEmpty
            ? null
            : _middleCtrl.text.trim(),
        'family_name': family,
        'preferred_name': _preferredCtrl.text.trim().isEmpty
            ? null
            : _preferredCtrl.text.trim(),
        if (avatarId != null && avatarId.isNotEmpty)
          'avatar_file_asset_id': avatarId,
      });
      if (!mounted) return;
    }

    setState(() => _saving = false);
    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fhcT(
                context,
                'account.profileUpdated',
                fallback: 'Profile updated.',
              ),
            ),
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          fhcGo(context, FhcRoutes.profile);
        }
      case AppError(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'account.editProfile', fallback: 'Edit Profile'),
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                fhcGo(context, FhcRoutes.profile);
              }
            },
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null) {
      return FhcErrorState(
        title: fhcT(
          context,
          'errors.somethingWentWrong',
          fallback: 'Could not load profile',
        ),
        message: _error!,
        onRetry: _load,
      );
    }

    final preview = _pendingPhotoBytes ?? _avatarBytes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: FhcColors.mint,
                      shape: BoxShape.circle,
                      border: Border.all(color: FhcColors.border, width: 2),
                    ),
                    child: preview != null
                        ? Image.memory(preview, fit: BoxFit.cover)
                        : const Icon(
                          Icons.person,
                          size: 48,
                          color: FhcColors.green,
                        ),
                  ),
                  Material(
                    color: FhcColors.green,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _saving ? null : _pickPhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: FhcColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _saving ? null : _pickPhoto,
                child: Text(
                  preview == null
                      ? fhcT(
                        context,
                        'account.uploadPhoto',
                        fallback: 'Upload photo',
                      )
                      : fhcT(
                        context,
                        'account.replacePhoto',
                        fallback: 'Replace photo',
                      ),
                ),
              ),
              if (_email != null && _email!.isNotEmpty)
                Text(
                  _email!,
                  style: const TextStyle(fontSize: 12, color: FhcColors.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FhcSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                fhcT(
                  context,
                  'account.personalInformation',
                  fallback: 'Personal Information',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fhcT(
                  context,
                  'account.editProfileCopy',
                  fallback:
                      'Update how your name appears across Family House Connect. Photo changes require recent verification.',
                ),
                style: const TextStyle(fontSize: 12, color: FhcColors.muted),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _givenCtrl,
                label: fhcT(context, 'account.givenName', fallback: 'Given name'),
              ),
              _field(
                controller: _middleCtrl,
                label: fhcT(
                  context,
                  'account.middleName',
                  fallback: 'Middle name',
                ),
              ),
              _field(
                controller: _familyCtrl,
                label: fhcT(
                  context,
                  'account.familyName',
                  fallback: 'Family name',
                ),
              ),
              _field(
                controller: _preferredCtrl,
                label: fhcT(
                  context,
                  'account.preferredName',
                  fallback: 'Preferred name',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FhcPrimaryButton(
          label: _saving
              ? fhcT(context, 'common.saving', fallback: 'Saving…')
              : fhcT(context, 'account.saveProfile', fallback: 'Save profile'),
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: FhcColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FhcRadius.sm),
            borderSide: const BorderSide(color: FhcColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FhcRadius.sm),
            borderSide: const BorderSide(color: FhcColors.border),
          ),
        ),
      ),
    );
  }
}

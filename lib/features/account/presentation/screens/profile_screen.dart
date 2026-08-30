import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.repository});

  final ProfileRepository? repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileRepository? _repository;

  bool _loading = true;
  String? _error;
  JsonObject? _profile;
  Uint8List? _avatarBytes;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository ??=
        widget.repository ??
        AppServicesScope.maybeOf(context)?.profileRepository ??
        createProfileRepository();
    if (!_started) {
      _started = true;
      _load();
    }
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
        setState(() {
          _profile = value;
          _loading = false;
        });
        await _loadAvatar(value);
      case AppError(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  Future<void> _loadAvatar(JsonObject value) async {
    final profile = value['profile'];
    if (profile is! Map) return;
    final id = (profile['avatar_file_id'] as String?)?.trim();
    if (id == null || id.isEmpty) {
      if (mounted) setState(() => _avatarBytes = null);
      return;
    }
    final repo = _repository;
    if (repo is! LaravelProfileRepository) return;
    final result = await repo.downloadAvatarBytes(id);
    if (!mounted) return;
    if (result case AppSuccess(:final value)) {
      setState(() => _avatarBytes = value);
    }
  }

  String get _displayName {
    final profile = _profile?['profile'];
    if (profile is Map) {
      final preferred = profile['preferred_name'] as String?;
      final given = profile['given_name'] as String?;
      final family = profile['family_name'] as String?;
      final parts = [
        if (preferred != null && preferred.isNotEmpty) preferred,
        if ((preferred == null || preferred.isEmpty) &&
            given != null &&
            given.isNotEmpty)
          given,
        if (family != null && family.isNotEmpty) family,
      ];
      if (parts.isNotEmpty) return parts.join(' ');
    }
    final email = _profile?['email'] as String?;
    if (email != null && email.isNotEmpty) return email;
    return fhcT(context, 'member.navAria', fallback: 'Member');
  }

  String get _email => (_profile?['email'] as String?) ?? '';

  Future<void> _signOut(BuildContext context) async {
    final auth = AppServicesScope.maybeOf(context)?.authRepository;
    if (auth != null) {
      await auth.signOut();
    }
    if (!context.mounted) return;
    fhcGo(context, '/sign-in');
  }

  Future<void> _openEdit() async {
    final changed = await Navigator.of(context).pushNamed(FhcRoutes.editProfile);
    if (changed == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          _ProfileHeader(
            onSettings: () => fhcPush(context, FhcRoutes.settings),
          ),
          Expanded(child: _body(context)),
          const FhcBottomNavigation(selected: 4),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
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
    if (_profile == null) {
      return FhcEmptyState(
        title: fhcT(context, 'account.noProfileYet', fallback: 'No profile yet'),
        message: fhcT(
          context,
          'account.noProfileCopy',
          fallback: 'Sign in to load your Family House Connect profile.',
        ),
      );
    }

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        _ProfileHero(
          name: _displayName,
          email: _email,
          avatarBytes: _avatarBytes,
          onEdit: _openEdit,
        ),
        const SizedBox(height: 20),
        _ProfileMenuCard(
          items: [
            _ProfileMenuItem(
              icon: Icons.person_outline,
              label: fhcT(
                context,
                'account.personalInformation',
                fallback: 'Personal Information',
              ),
              onTap: _openEdit,
            ),
            _ProfileMenuItem(
              icon: Icons.history,
              label: fhcT(
                context,
                'account.givingHistory',
                fallback: 'My Giving History',
              ),
              onTap: () => fhcPush(context, FhcRoutes.giveHistory),
            ),
            _ProfileMenuItem(
              icon: Icons.notifications_none_outlined,
              label: fhcT(
                context,
                'account.prayerRequests',
                fallback: 'My Prayer Requests',
              ),
              onTap: () => fhcPush(context, FhcRoutes.prayer),
            ),
            _ProfileMenuItem(
              icon: Icons.groups_outlined,
              label: fhcT(context, 'account.myGroups', fallback: 'My Groups'),
              onTap: () => fhcPush(context, FhcRoutes.groups),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          items: [
            _ProfileMenuItem(
              icon: Icons.settings_outlined,
              label: fhcT(
                context,
                'account.appSettings',
                fallback: 'App Settings',
              ),
              onTap: () => fhcPush(context, FhcRoutes.settings),
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline,
              label: fhcT(context, 'settings.help', fallback: 'Help & Support'),
              onTap: () => fhcPush(context, FhcRoutes.help),
            ),
            _ProfileMenuItem(
              icon: Icons.logout,
              label: fhcT(context, 'account.signOut', fallback: 'Sign Out'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FhcSizes.topBarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              fhcT(context, 'account.myProfile', fallback: 'My Profile'),
              style: FhcTypography.titleSmall,
            ),
          ),
          Positioned(
            right: FhcSpacing.sm,
            child: IconButton(
              onPressed: onSettings,
              tooltip: fhcT(context, 'common.settings', fallback: 'Settings'),
              icon: const Icon(Icons.settings_outlined, size: 23),
              color: FhcColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.onEdit,
    this.avatarBytes,
  });

  final String name;
  final String email;
  final VoidCallback onEdit;
  final Uint8List? avatarBytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileAvatar(bytes: avatarBytes),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.15,
            color: FhcColors.ink,
          ),
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: FhcColors.muted),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 32,
          child: FilledButton(
            onPressed: onEdit,
            style: FilledButton.styleFrom(
              backgroundColor: FhcColors.green,
              foregroundColor: FhcColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FhcRadius.sm),
              ),
            ),
            child: Text(
              fhcT(context, 'account.editProfile', fallback: 'Edit Profile'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.bytes});

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: FhcColors.mint,
        shape: BoxShape.circle,
      ),
      child: bytes != null
          ? Image.memory(bytes!, fit: BoxFit.cover)
          : const Icon(Icons.person, size: 38, color: FhcColors.green),
    );
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.items});
  final List<_ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _ProfileMenuRow(item: items[index]),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.item});
  final _ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      child: InkWell(
        onTap: item.onTap ?? () {},
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: FhcColors.ink),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: FhcColors.ink,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
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

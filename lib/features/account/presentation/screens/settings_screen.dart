import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/l10n/supported_locales.dart';
import '../../../../core/launch/app_launch_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/profile_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.repository});

  final ProfileRepository? repository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  LaravelProfileRepository? _repository;

  bool _loading = true;
  String? _error;
  String _localeLabel = 'English';
  String _timezone = 'Africa/Lagos';
  List<String> _channels = const ['email', 'in_app'];
  bool _started = false;

  List<(String, String)> get _localeChoices => [
    for (final code in kFhcSupportedLocales)
      (code, kFhcLocaleMeta[code]!.endonym),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fromServices = AppServicesScope.maybeOf(context)?.profileRepository;
    _repository ??=
        widget.repository is LaravelProfileRepository
            ? widget.repository as LaravelProfileRepository
            : fromServices is LaravelProfileRepository
            ? fromServices
            : createProfileRepository() as LaravelProfileRepository;
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
        final preferences = value['preferences'];
        if (preferences is Map) {
          final locale = preferences['locale'] as String? ?? 'en';
          final timezone =
              preferences['timezone'] as String? ?? 'Africa/Lagos';
          final rawChannels = preferences['notification_channels'];
          setState(() {
            _localeLabel = _labelForLocale(locale);
            _timezone = timezone;
            _channels = [
              if (rawChannels is List)
                for (final item in rawChannels) '$item',
            ];
            if (_channels.isEmpty) {
              _channels = const ['email', 'in_app'];
            }
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      case AppError(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  String _labelForLocale(String locale) {
    for (final choice in _localeChoices) {
      if (choice.$1 == locale) return choice.$2;
    }
    return locale;
  }

  String _codeForLocaleLabel(String label) {
    for (final choice in _localeChoices) {
      if (choice.$2 == label) return choice.$1;
    }
    return 'en';
  }

  Future<void> _changeLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final choice in _localeChoices)
                ListTile(
                  title: Text(choice.$2),
                  trailing:
                      _localeLabel == choice.$2
                          ? const Icon(Icons.check, color: FhcColors.green)
                          : null,
                  onTap: () => Navigator.of(sheetContext).pop(choice.$2),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == _localeLabel || !mounted) return;

    final repository = _repository;
    if (repository == null) return;
    final previous = _localeLabel;
    setState(() => _localeLabel = selected);
    final result = await repository.updatePreferences({
      'locale': _codeForLocaleLabel(selected),
      'timezone': _timezone,
      'notification_channels': _channels,
    });
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        final locale = value['locale'] as String? ?? selected;
        setState(() => _localeLabel = _labelForLocale(locale));
        await AppLaunchScope.maybeOf(context)?.setLanguage(
          languageCode: locale,
          languageLabel: _labelForLocale(locale),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fhcT(context, 'account.languagePreferenceSaved'))),
        );
      case AppError(:final failure):
        setState(() => _localeLabel = previous);
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
          SizedBox(
            height: FhcSizes.topBarHeight,
            child: Center(
              child: Text(
                fhcT(context, 'settings.title'),
                style: FhcTypography.titleSmall,
              ),
            ),
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
        title: fhcT(context, 'settings.couldNotLoad'),
        message: _error!,
        onRetry: _load,
      );
    }

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        FhcMenuGroup(
          title: fhcT(context, 'settings.account'),
          children: [
            FhcMenuTile(
              icon: Icons.person_outline,
              title: fhcT(context, 'settings.accountSettings'),
              subtitle: fhcT(context, 'settings.accountSettingsCopy'),
              showDivider: true,
              onTap: () => fhcPush(context, FhcRoutes.editProfile),
            ),
            FhcMenuTile(
              icon: Icons.notifications_outlined,
              title: fhcT(context, 'settings.notificationPreferences'),
              subtitle: fhcT(context, 'settings.notificationPreferencesCopy'),
              showDivider: true,
              onTap: () => fhcPush(context, '/settings/notifications'),
            ),
            FhcMenuTile(
              icon: Icons.lock_outline,
              title: fhcT(context, 'settings.privacySecurity'),
              subtitle: fhcT(context, 'settings.privacySecurityCopy'),
              onTap: () => fhcPush(context, '/settings/privacy'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FhcMenuGroup(
          title: fhcT(context, 'settings.preferences'),
          children: [
            FhcMenuTile(
              icon: Icons.language,
              title: fhcT(context, 'settings.language'),
              subtitle: _localeLabel,
              showDivider: true,
              onTap: _changeLanguage,
            ),
            FhcMenuTile(
              icon: Icons.dark_mode_outlined,
              title: fhcT(context, 'settings.theme'),
              subtitle: fhcT(context, 'settings.themeSystem'),
              onTap:
                  () => fhcApiUnavailable(context, action: 'Changing theme'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FhcMenuGroup(
          title: fhcT(context, 'settings.support'),
          children: [
            FhcMenuTile(
              icon: Icons.info_outline,
              title: fhcT(context, 'settings.about'),
              subtitle: fhcT(
                context,
                'settings.version',
                args: {'version': '1.0.0'},
              ),
              showDivider: true,
              onTap: () => fhcPush(context, FhcRoutes.help),
            ),
            FhcMenuTile(
              icon: Icons.help_outline,
              title: fhcT(context, 'settings.help'),
              subtitle: fhcT(context, 'settings.helpCopy'),
              onTap: () => fhcPush(context, FhcRoutes.help),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FhcPrimaryButton(
          label: fhcT(context, 'settings.logOut'),
          color: const Color(0xFFEF4444),
          onPressed: () => _logOut(context),
        ),
      ],
    );
  }

  Future<void> _logOut(BuildContext context) async {
    final auth = AppServicesScope.maybeOf(context)?.authRepository;
    if (auth != null) {
      await auth.signOut();
    }
    if (!context.mounted) return;
    fhcGo(context, '/sign-in');
  }
}

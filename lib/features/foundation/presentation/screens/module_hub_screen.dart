import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../account/data/profile_repository.dart';
import '../fhc_nav.dart';

class ModuleHubScreen extends StatefulWidget {
  const ModuleHubScreen({super.key, this.profileRepository});

  final ProfileRepository? profileRepository;

  @override
  State<ModuleHubScreen> createState() => _ModuleHubScreenState();
}

class _ModuleHubScreenState extends State<ModuleHubScreen> {
  static const _modules = <_ModuleSpec>[
    _ModuleSpec(
      icon: Icons.church_outlined,
      titleKey: 'auth.moduleChurch',
      titleFallback: 'CHURCH',
      subtitleKey: 'auth.moduleChurchCopy',
      subtitleFallback: 'Connect, Grow, Serve',
      color: FhcColors.green,
      route: FhcRoutes.churchHome,
    ),
    _ModuleSpec(
      icon: Icons.school_outlined,
      titleKey: 'auth.moduleKca',
      titleFallback: 'KCA',
      subtitleKey: 'auth.moduleKcaAcademy',
      subtitleFallback: 'Kingdom Christian Academy',
      color: FhcColors.purple,
      route: FhcRoutes.kcaGate,
    ),
    _ModuleSpec(
      icon: Icons.public,
      titleKey: 'auth.moduleMission',
      titleFallback: 'MISSION',
      subtitleKey: 'auth.moduleMissionCopy',
      subtitleFallback: 'Go, Preach, Disciple',
      color: FhcColors.navy,
      route: FhcRoutes.mission,
    ),
    _ModuleSpec(
      icon: Icons.volunteer_activism_outlined,
      titleKey: 'auth.moduleGive',
      titleFallback: 'GIVE',
      subtitleKey: 'auth.moduleGiveCopy',
      subtitleFallback: 'Tithe, Donate, Support',
      color: FhcColors.gold,
      route: FhcRoutes.give,
    ),
    _ModuleSpec(
      icon: Icons.smart_display_outlined,
      titleKey: 'auth.moduleMedia',
      titleFallback: 'MEDIA',
      subtitleKey: 'auth.moduleMediaCopy',
      subtitleFallback: 'Watch, Listen, Read',
      color: FhcColors.media,
      route: FhcRoutes.media,
    ),
    _ModuleSpec(
      icon: Icons.calendar_month_outlined,
      titleKey: 'auth.moduleEvents',
      titleFallback: 'EVENTS',
      subtitleKey: 'auth.moduleEventsCopy',
      subtitleFallback: 'Conferences, Meetings',
      color: FhcColors.eventsAccent,
      route: FhcRoutes.events,
    ),
  ];

  static const _actions = <(IconData, String, String, String)>[
    (Icons.pan_tool_outlined, 'member.prayer', 'Prayer', FhcRoutes.prayer),
    (Icons.event_outlined, 'member.events', 'Events', FhcRoutes.events),
    (Icons.favorite_border, 'nav.give', 'Give', FhcRoutes.give),
    (
      Icons.chat_bubble_outline,
      'member.messages',
      'Messages',
      FhcRoutes.messages,
    ),
  ];

  JsonObject? _dashboard;
  String? _error;
  bool _repoMissing = false;
  bool _started = false;

  ProfileRepository? get _repo =>
      widget.profileRepository ??
      AppServicesScope.maybeOf(context)?.profileRepository ??
      createProfileRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _repoMissing = true;
        _error = null;
        _dashboard = null;
      });
      return;
    }
    final result = await repo.getDashboard();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _dashboard = value;
          _error = null;
          _repoMissing = false;
        });
      case AppError(:final failure):
        setState(() {
          _dashboard = null;
          _error = failure.message;
          _repoMissing = false;
        });
    }
  }

  String get _welcomeName {
    final root = _dashboard?['profile'];
    final profile = root is Map ? root['profile'] : null;
    if (profile is Map) {
      final preferred = '${profile['preferred_name'] ?? ''}'.trim();
      if (preferred.isNotEmpty) return preferred;
      final given = '${profile['given_name'] ?? ''}'.trim();
      if (given.isNotEmpty) return given;
    }
    if (root is Map) {
      final email = '${root['email'] ?? ''}'.trim();
      if (email.isNotEmpty) return email;
    }
    return '';
  }

  String _subtitle(BuildContext context) {
    if (_repoMissing) {
      return fhcT(
        context,
        'errors.profileNotWired',
        fallback: 'Profile repository is not wired.',
      );
    }
    if (_error != null) return _error!;
    if (_dashboard == null) {
      return fhcT(
        context,
        'member.selectModule',
        fallback: 'Select a module to enter and start operating.',
      );
    }
    final unread = _dashboard!['unread_notification_count'] ?? 0;
    final prayers = _dashboard!['open_prayer_count'] ?? 0;
    return fhcT(
      context,
      'auth.hubStats',
      args: {'unread': '$unread', 'prayers': '$prayers'},
      fallback: 'Unread notifications: {unread} · Open prayers: {prayers}',
    );
  }

  String _welcome(BuildContext context) {
    final name = _welcomeName;
    if (name.isEmpty) {
      return fhcT(context, 'member.welcome', fallback: 'Welcome');
    }
    return fhcT(
      context,
      'member.welcomeName',
      args: {'name': name},
      fallback: 'Welcome, {name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _welcome(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle(context),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: FhcColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  const rows = 3;
                  final tileW = (constraints.maxWidth - gap) / 2;
                  final maxH = (constraints.maxHeight - gap * (rows - 1)) / rows;
                  final tileH = maxH < tileW * 1.12 ? maxH : tileW * 1.12;
                  final aspect = tileW / tileH;
                  return GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                    childAspectRatio: aspect,
                    children: [
                      for (final module in _modules)
                        _ModuleTile(
                          spec: module,
                          onTap:
                              module.route == null
                                  ? () {}
                                  : () => fhcGo(context, module.route!),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text(
              fhcT(
                context,
                'common.quickActions',
                fallback: 'Quick Actions',
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                for (var i = 0; i < _actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAction(
                      icon: _actions[i].$1,
                      label: fhcT(
                        context,
                        _actions[i].$2,
                        fallback: _actions[i].$3,
                      ),
                      onTap: () {
                        final route = _actions[i].$4;
                        if (route == FhcRoutes.messages) {
                          fhcGo(context, route);
                        } else {
                          fhcPush(context, route);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          FhcBottomNavigation(
            selected: 0,
            onSelected: (i) => fhcTab(context, i),
          ),
        ],
      ),
    );
  }
}

class _ModuleSpec {
  const _ModuleSpec({
    required this.icon,
    required this.titleKey,
    required this.titleFallback,
    required this.subtitleKey,
    required this.subtitleFallback,
    required this.color,
    this.route,
  });

  final IconData icon;
  final String titleKey;
  final String titleFallback;
  final String subtitleKey;
  final String subtitleFallback;
  final Color color;
  final String? route;
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.spec, required this.onTap});

  final _ModuleSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(FhcRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FhcRadius.card),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                spec.color,
                Color.lerp(spec.color, const Color(0xFF000000), 0.34)!,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(spec.icon, color: FhcColors.white, size: 42),
              const SizedBox(height: 10),
              Text(
                fhcT(
                  context,
                  spec.titleKey,
                  fallback: spec.titleFallback,
                ).toUpperCase(),
                style: const TextStyle(
                  color: FhcColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  fhcT(
                    context,
                    spec.subtitleKey,
                    fallback: spec.subtitleFallback,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FhcColors.white,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(FhcRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            children: [
              FhcCircleIcon(icon: icon, size: 34),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      icon: Icons.public,
      titleKey: 'auth.moduleMission',
      titleFallback: 'MISSION',
      subtitleKey: 'auth.moduleMissionCopy',
      subtitleFallback: 'Go, Preach, Disciple',
      color: FhcColors.navy,
      route: FhcRoutes.mission,
    ),
    _ModuleSpec(
      icon: Icons.school_outlined,
      titleKey: 'auth.moduleKca',
      titleFallback: 'KCA',
      subtitleKey: 'auth.moduleKcaAcademy',
      subtitleFallback: 'Kingdom Change Agent',
      color: FhcColors.purple,
      route: FhcRoutes.kcaGate,
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
      titleFallback: 'EVENT',
      subtitleKey: 'auth.moduleEventsCopy',
      subtitleFallback: 'Conferences, Meetings',
      color: FhcColors.eventsAccent,
      route: FhcRoutes.events,
    ),
    _ModuleSpec(
      icon: Icons.church_outlined,
      titleKey: 'auth.moduleChurch',
      titleFallback: 'CHURCH',
      subtitleKey: 'auth.moduleChurchCopy',
      subtitleFallback: 'Serve and Grow',
      color: FhcColors.green,
      route: FhcRoutes.churchHome,
    ),
    _ModuleSpec(
      icon: Icons.menu_book_outlined,
      titleKey: 'nav.bible',
      titleFallback: 'BIBLE',
      subtitleKey: 'member.bible',
      subtitleFallback: 'Read and study Scripture',
      color: FhcColors.teal,
      route: FhcRoutes.bible,
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
  String? _lastImportantEventIdShown;

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
        _maybeShowImportantEventPopup(value);
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
    final base = fhcT(
      context,
      'auth.hubStats',
      args: {'unread': '$unread', 'prayers': '$prayers'},
      fallback: 'Unread notifications: {unread} · Open prayers: {prayers}',
    );
    final bibleSummary = _bibleReaderSummary(context);
    if (bibleSummary == null) return base;
    return '$base\n$bibleSummary';
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

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }

  String? _bibleReaderSummary(BuildContext context) {
    final counts = _dashboard?['bible_reader_counts'];
    if (counts is! Map) return null;
    final day = _asInt(counts['day']);
    final week = _asInt(counts['week']);
    final year = _asInt(counts['year']);
    return fhcT(
      context,
      'auth.hubBibleReaders',
      args: {'day': '$day', 'week': '$week', 'year': '$year'},
      fallback: 'Bible readers - Day: {day} · Week: {week} · Year: {year}',
    );
  }

  JsonObject? _importantEventFromDashboard(JsonObject dashboard) {
    final event = dashboard['important_event'];
    if (event is! Map) return null;
    final parsed = Map<String, Object?>.from(
      event.map((key, value) => MapEntry('$key', value)),
    );
    final id = '${parsed['id'] ?? ''}'.trim();
    final name = '${parsed['name'] ?? ''}'.trim();
    if (id.isEmpty || name.isEmpty) return null;
    return parsed;
  }

  void _maybeShowImportantEventPopup(JsonObject dashboard) {
    final event = _importantEventFromDashboard(dashboard);
    if (event == null) return;
    final eventId = '${event['id']}';
    if (_lastImportantEventIdShown == eventId) return;
    _lastImportantEventIdShown = eventId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showImportantEventPopup(event);
    });
  }

  Future<void> _showImportantEventPopup(JsonObject event) async {
    final startsAt = DateTime.tryParse('${event['starts_at'] ?? ''}')?.toLocal();
    final when = startsAt == null
        ? fhcT(context, 'events.scheduleTba', fallback: 'Schedule TBA')
        : '${startsAt.day}/${startsAt.month}/${startsAt.year} '
            '${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}';
    final openDetails = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          fhcT(
            dialogContext,
            'events.importantEvent',
            fallback: 'Important Event',
          ),
        ),
        content: Text(
          '${event['name']}\n$when',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(fhcT(dialogContext, 'common.later', fallback: 'Later')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              fhcT(
                dialogContext,
                'common.view',
                fallback: 'View',
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted || openDetails != true) return;
    final id = '${event['id']}'.trim();
    if (id.isEmpty) return;
    Navigator.of(context).pushNamed(FhcRoutes.eventDetail, arguments: id);
  }

  String _formatWhen(Object? rawValue, BuildContext context) {
    final parsed = DateTime.tryParse('${rawValue ?? ''}')?.toLocal();
    if (parsed == null) {
      return fhcT(context, 'events.scheduleTba', fallback: 'Schedule TBA');
    }
    return '${parsed.day}/${parsed.month}/${parsed.year} '
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final importantEvent =
        _dashboard == null ? null : _importantEventFromDashboard(_dashboard!);
    return FhcDevicePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A7E57), Color(0xFF0E443A)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _welcome(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _subtitle(context),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: Color(0xFFE8FFF7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (importantEvent != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD49A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: Color(0xFFB25A00),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fhcT(
                                  context,
                                  'events.importantEvent',
                                  fallback: 'Important Event',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7B3B00),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${importantEvent['name']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: FhcColors.ink,
                                ),
                              ),
                              Text(
                                _formatWhen(importantEvent['starts_at'], context),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: FhcColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final id = '${importantEvent['id']}'.trim();
                            if (id.isEmpty) return;
                            Navigator.of(context).pushNamed(
                              FhcRoutes.eventDetail,
                              arguments: id,
                            );
                          },
                          child: Text(
                            fhcT(context, 'common.view', fallback: 'View'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  fhcT(context, 'auth.chooseModule', fallback: 'Choose a Module'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fhcT(
                    context,
                    'auth.selectModuleContinue',
                    fallback: 'Select a module to continue.',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: FhcColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _modules.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.08,
                  ),
                  itemBuilder: (context, index) => _ModuleTile(
                    spec: _modules[index],
                    onTap:
                        _modules[index].route == null
                            ? () {}
                            : () => fhcGo(context, _modules[index].route!),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fhcT(context, 'common.quickActions', fallback: 'Quick Actions'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
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
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0x22FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(spec.icon, color: FhcColors.white, size: 34),
              ),
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

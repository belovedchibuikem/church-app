import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/mission_repository.dart';

class CrusadeDetailScreen extends StatefulWidget {
  const CrusadeDetailScreen({
    super.key,
    this.crusadeId,
    this.repository,
  });

  final String? crusadeId;
  final HttpMissionRepository? repository;

  @override
  State<CrusadeDetailScreen> createState() => _CrusadeDetailScreenState();
}

class _CrusadeDetailScreenState extends State<CrusadeDetailScreen> {
  HttpMissionRepository? _repository;

  int _tab = 0;
  bool _loading = true;
  String? _error;
  JsonObject? _crusade;
  List<JsonObject> _catalogue = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repository != null) return;
    if (widget.repository != null) {
      _repository = widget.repository;
      return;
    }
    final fromScope = AppServicesScope.maybeOf(context)?.missionRepository;
    _repository = fromScope is HttpMissionRepository
        ? fromScope
        : HttpMissionRepository();
  }

  String? get _routeCrusadeId {
    final fromWidget = widget.crusadeId?.trim();
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    return FhcRouteArgs.entityIdOf(context) ??
        missionCrusadeIdFromRoute(ModalRoute.of(context)?.settings.name);
  }

  HttpMissionRepository get _repo =>
      _repository ?? HttpMissionRepository();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final id = _routeCrusadeId;
    if (id != null) {
      final result = await _repo.getCrusade(id);
      if (!mounted) return;
      switch (result) {
        case AppSuccess(:final value):
          setState(() {
            _crusade = value;
            _catalogue = const [];
            _loading = false;
          });
        case AppError(:final failure):
          setState(() {
            _crusade = null;
            _error = failure.message;
            _loading = false;
          });
      }
      return;
    }

    final result = await _repo.getCrusades(const {
      'status': 'all',
      'sort': '-starts_at',
      'per_page': '25',
    });
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _catalogue = value;
          _crusade = null;
          _loading = false;
        });
      case AppError(:final failure):
        setState(() {
          _catalogue = const [];
          _error = failure.message;
          _loading = false;
        });
    }
  }

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.mission);
    }
  }

  void _openSouls() => fhcPush(context, FhcRoutes.souls);

  void _openAddSoul() {
    final id = (_crusade?['id'] as String?)?.trim() ?? _routeCrusadeId;
    if (id != null && looksLikeMissionUlid(id)) {
      fhcPush(context, '${FhcRoutes.soulAdd}?id=$id');
      return;
    }
    fhcPush(context, FhcRoutes.soulAdd);
  }

  void _openCrusade(String id) {
    final route = '${FhcRoutes.crusade}/$id';
    if (Navigator.of(context).canPop()) {
      fhcPush(context, route);
    } else {
      fhcGo(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: (_crusade?['name'] as String?)?.toUpperCase() ??
                fhcT(context, 'mission.crusades', fallback: 'CRUSADES'),
            onBack: _onBack,
            trailing: IconButton(
              onPressed: () => fhcApiUnavailable(
                context,
                action: fhcT(
                  context,
                  'mission.sharingCrusade',
                  fallback: 'Sharing this crusade',
                ),
              ),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.share_outlined, size: 22),
              color: FhcColors.ink,
              tooltip: fhcT(context, 'mission.share', fallback: 'Share'),
            ),
          ),
          Expanded(child: _body()),
          if (_crusade != null)
            _FooterActions(
              onAddSoul: _openAddSoul,
              onFollowUp: _openSouls,
              onViewSouls: _openSouls,
              onShare: () => fhcApiUnavailable(
                context,
                action: fhcT(
                  context,
                  'mission.sharingCrusade',
                  fallback: 'Sharing this crusade',
                ),
              ),
            ),
          const FhcBottomNavigation(selected: 1),
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
          'mission.unableToLoadCrusades',
          fallback: 'Unable to load crusades',
        ),
        message: _error!,
        onRetry: _load,
      );
    }
    if (_crusade != null) {
      return _CrusadeDetailBody(
        crusade: _crusade!,
        tab: _tab,
        tabs: [
          fhcT(context, 'common.overview', fallback: 'Overview'),
          fhcT(context, 'mission.souls', fallback: 'Souls'),
          fhcT(context, 'mission.schedule', fallback: 'Schedule'),
          fhcT(context, 'mission.team', fallback: 'Team'),
        ],
        onTab: (i) => setState(() => _tab = i),
        onViewSouls: _openSouls,
        onCaptureSoul: _openAddSoul,
      );
    }
    if (_catalogue.isEmpty) {
      return FhcEmptyState(
        icon: Icons.campaign_outlined,
        title: fhcT(
          context,
          'mission.noCrusadesYet',
          fallback: 'No crusades yet',
        ),
        message: fhcT(
          context,
          'mission.noCrusadesCopy',
          fallback:
              'Published mission crusades from the public catalogue will appear here.',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: [
        Text(
          fhcT(context, 'mission.selectACrusade', fallback: 'Select a crusade'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (var i = 0; i < _catalogue.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: FhcColors.border),
                _CatalogueRow(
                  crusade: _catalogue[i],
                  onTap: () {
                    final id = (_catalogue[i]['id'] as String?)?.trim();
                    if (id == null || id.isEmpty) return;
                    _openCrusade(id);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CrusadeDetailBody extends StatelessWidget {
  const _CrusadeDetailBody({
    required this.crusade,
    required this.tab,
    required this.tabs,
    required this.onTab,
    required this.onViewSouls,
    required this.onCaptureSoul,
  });

  final JsonObject crusade;
  final int tab;
  final List<String> tabs;
  final ValueChanged<int> onTab;
  final VoidCallback onViewSouls;
  final VoidCallback onCaptureSoul;

  @override
  Widget build(BuildContext context) {
    final name = (crusade['name'] as String?)?.trim() ??
        fhcT(context, 'mission.crusade', fallback: 'Crusade');
    final location = crusade['location'] is Map
        ? Map<String, Object?>.from(
            (crusade['location'] as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
        : null;
    final dateLine = formatMissionDateRange(
      startsAt: crusade['starts_at'] as String?,
      endsAt: crusade['ends_at'] as String?,
    );
    final placeLine = formatMissionLocation(location);
    final subtitle = '$dateLine  •  $placeLine';

    return Column(
      children: [
        const _CrusadeHero(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _TitleBlock(title: name, subtitle: subtitle),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _StatsRow(),
        ),
        ColoredBox(
          color: FhcColors.white,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _TabLabel(
                    label: tabs[i],
                    active: tab == i,
                    onTap: () => onTab(i),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: switch (tab) {
            1 => _GatedTab(
                title: fhcT(
                  context,
                  'mission.soulsFollowUp',
                  fallback: 'Soul follow-up',
                ),
                message: fhcT(
                  context,
                  'mission.soulsFollowUpCopy',
                  fallback:
                      'Review soul journeys for this crusade, assign mentors, and record follow-up from the admin list.',
                ),
                actionLabel: fhcT(
                  context,
                  'mission.viewFollowUp',
                  fallback: 'View follow-up',
                ),
                onAction: onViewSouls,
                secondaryLabel: fhcT(
                  context,
                  'mission.captureSoul',
                  fallback: 'Capture soul',
                ),
                onSecondary: onCaptureSoul,
              ),
            2 => _GatedTab(
                title: fhcT(
                  context,
                  'mission.eventWindow',
                  fallback: 'Event window',
                ),
                message:
                    '${fhcT(context, 'mission.runs', fallback: 'Runs')} $dateLine · $placeLine. '
                    '${fhcT(context, 'mission.scheduleDetailCopy', fallback: 'A detailed day-by-day agenda will appear here when organizers publish one.')}',
              ),
            3 => _GatedTab(
                title: fhcT(
                  context,
                  'mission.fieldTeam',
                  fallback: 'Field team',
                ),
                message: fhcT(
                  context,
                  'mission.fieldTeamCopy',
                  fallback:
                      'Mentor assignments and volunteer teams are managed from Mission → Team tools for authorized workers.',
                ),
                actionLabel: fhcT(
                  context,
                  'mission.openTeamTools',
                  fallback: 'Open team tools',
                ),
                onAction: () => fhcPush(context, FhcRoutes.mentorAssignment),
              ),
            _ => _OverviewTab(
                description: fhcT(
                  context,
                  'mission.crusadeOverviewCopy',
                  fallback:
                      'A published Family House mission crusade. Capture souls against this crusade ULID when authorized.',
                ),
                locationLabel: placeLine,
                startsAt: crusade['starts_at'] as String?,
                endsAt: crusade['ends_at'] as String?,
                crusadeId: (crusade['id'] as String?) ?? '',
              ),
          },
        ),
      ],
    );
  }
}

class _CatalogueRow extends StatelessWidget {
  const _CatalogueRow({required this.crusade, required this.onTap});

  final JsonObject crusade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (crusade['name'] as String?)?.trim() ??
        fhcT(context, 'mission.crusade', fallback: 'Crusade');
    final location = crusade['location'] is Map
        ? Map<String, Object?>.from(
            (crusade['location'] as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
        : null;
    final subtitle =
        '${formatMissionDateRange(startsAt: crusade['starts_at'] as String?, endsAt: crusade['ends_at'] as String?)} • ${formatMissionLocation(location)}';

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FhcColors.mint,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: FhcColors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: FhcColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FhcColors.muted),
          ],
        ),
      ),
    );
  }
}

class _CrusadeHero extends StatelessWidget {
  const _CrusadeHero();

  static const _fallback = ColoredBox(
    color: FhcColors.greenDeep,
    child: Center(
      child: Icon(Icons.campaign_outlined, size: 56, color: FhcColors.white),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: SizedBox(
          height: 132,
          width: double.infinity,
          child: Image.asset(
            'assets/images/abuja_crusade.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/crusade_crowd.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => _fallback,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.3,
            color: FhcColors.muted,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: fhcT(
              context,
              'mission.soulsReached',
              fallback: 'Souls Reached',
            ),
            value: '—',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: fhcT(
              context,
              'mission.newConversions',
              fallback: 'New Conversions',
            ),
            value: '—',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: fhcT(
              context,
              'mission.volunteers',
              fallback: 'Volunteers',
            ),
            value: '—',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              color: FhcColors.muted,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? FhcColors.green : FhcColors.border,
              width: active ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: active ? FhcColors.green : FhcColors.ink,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.description,
    required this.locationLabel,
    required this.startsAt,
    required this.endsAt,
    required this.crusadeId,
  });

  final String description;
  final String locationLabel;
  final String? startsAt;
  final String? endsAt;
  final String crusadeId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        Text(
          fhcT(context, 'mission.description', fallback: 'Description'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: FhcColors.muted,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          fhcT(context, 'common.location', fallback: 'Location'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          locationLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: FhcColors.muted,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          fhcT(context, 'mission.dates', fallback: 'Dates'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          formatMissionDateRange(startsAt: startsAt, endsAt: endsAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: FhcColors.muted,
          ),
        ),
        if (crusadeId.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            fhcT(context, 'mission.crusadeId', fallback: 'Crusade ID'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            crusadeId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: FhcColors.muted,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }
}

class _GatedTab extends StatelessWidget {
  const _GatedTab({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
      children: [
        FhcEmptyState(
          icon: Icons.lock_outline,
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: 12),
          FhcPrimaryButton(label: secondaryLabel!, onPressed: onSecondary),
        ],
      ],
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.onAddSoul,
    required this.onFollowUp,
    required this.onViewSouls,
    required this.onShare,
  });

  final VoidCallback onAddSoul;
  final VoidCallback onFollowUp;
  final VoidCallback onViewSouls;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FhcColors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _OutlinedAction(
                    icon: Icons.person_add_alt,
                    label: fhcT(context, 'mission.addSoul', fallback: 'Add Soul'),
                    onTap: onAddSoul,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OutlinedAction(
                    icon: Icons.assignment_outlined,
                    label: fhcT(
                      context,
                      'mission.followUp',
                      fallback: 'Follow-up',
                    ),
                    onTap: onFollowUp,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OutlinedAction(
                    icon: Icons.groups_outlined,
                    label: fhcT(
                      context,
                      'mission.viewSouls',
                      fallback: 'View Souls',
                    ),
                    onTap: onViewSouls,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OutlinedAction(
                    icon: Icons.ios_share,
                    label: fhcT(context, 'mission.share', fallback: 'Share'),
                    onTap: onShare,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FhcPrimaryButton(
              label: fhcT(
                context,
                'mission.createReport',
                fallback: 'Create Report',
              ),
              onPressed: () => fhcApiUnavailable(
                context,
                action: fhcT(
                  context,
                  'mission.creatingCrusadeReport',
                  fallback: 'Creating a crusade report',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
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
      color: FhcColors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.sm),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FhcRadius.sm),
            border: Border.all(color: FhcColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: FhcColors.green, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

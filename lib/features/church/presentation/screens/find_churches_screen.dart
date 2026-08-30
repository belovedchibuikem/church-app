import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../../maps/presentation/widgets/interactive_church_map.dart';
import '../../data/church_repository.dart';

class FindChurchesScreen extends StatefulWidget {
  const FindChurchesScreen({super.key, this.repository});

  final ChurchRepositoryImpl? repository;

  @override
  State<FindChurchesScreen> createState() => _FindChurchesScreenState();
}

class _FindChurchesScreenState extends State<FindChurchesScreen> {
  late final TextEditingController _searchController;
  FhcAsyncValue<List<ChurchSummary>> _state = const FhcAsyncValue.loading();
  String? _locationLabel;
  bool _started = false;

  ChurchRepositoryImpl? get _repository {
    final injected = widget.repository;
    if (injected != null) return injected;
    final fromServices = AppServicesScope.maybeOf(context)?.churchRepository;
    return fromServices is ChurchRepositoryImpl ? fromServices : null;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? name}) async {
    final repo = _repository;
    if (repo == null) {
      setState(() {
        _locationLabel = null;
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'errors.churchSearchWaiting',
            fallback:
                'Church search is waiting on AppServices churchRepository. '
                'No fixture list is shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());

    final result = await repo.listChurches(name: name);
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.items.isEmpty) {
          setState(() {
            _locationLabel = null;
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'errors.publishedChurchesWillAppear',
                fallback:
                    'Published churches will appear here when available.',
              ),
            );
          });
          return;
        }
        setState(() {
          _locationLabel = value.items.first.location.placeLabel;
          _state = FhcAsyncValue.data(value.items);
        });
      case AppError(:final failure):
        if (failure is IntegrationUnavailableFailure) {
          setState(() {
            _locationLabel = null;
            _state = FhcAsyncValue.unavailable(message: failure.message);
          });
          return;
        }
        setState(() {
          _locationLabel = null;
          _state = FhcAsyncValue.error(failure);
        });
    }
  }

  void _openChurch(ChurchSummary church) {
    fhcPush(context, '/discover/church/${church.id}');
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          _LocationHeader(label: _locationLabel),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(name: _searchController.text),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [
                  _ChurchSearch(
                    controller: _searchController,
                    onSubmitted: (value) => _load(name: value),
                  ),
                  const SizedBox(height: 12),
                  const InteractiveChurchMap(height: 260),
                  const SizedBox(height: 12),
                  _DiscoverHero(
                    onExplore: () => _load(name: _searchController.text),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: fhcT(
                      context,
                      'church.churches',
                      fallback: 'Churches',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FhcAsyncBody<List<ChurchSummary>>(
                    value: _state,
                    onRetry: () => _load(name: _searchController.text),
                    emptyTitle: fhcT(
                      context,
                      'errors.noChurchesFound',
                      fallback: 'No churches found',
                    ),
                    unavailableTitle: fhcT(
                      context,
                      'errors.churchesUnavailable',
                      fallback: 'Churches unavailable',
                    ),
                    builder: (context, churches) {
                      return Column(
                        children: [
                          for (var i = 0; i < churches.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _ChurchCard(
                              church: churches[i],
                              onOpen: () => _openChurch(churches[i]),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label ??
                    fhcT(
                      context,
                      'church.findAChurch',
                      fallback: 'Find a church',
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: () => fhcPush(context, FhcRoutes.notifications),
              tooltip: fhcT(
                context,
                'common.notifications',
                fallback: 'Notifications',
              ),
              icon: const Icon(Icons.notifications_none_rounded, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChurchSearch extends StatelessWidget {
  const _ChurchSearch({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        style: FhcTypography.body,
        decoration: InputDecoration(
          hintText: fhcT(
            context,
            'church.searchHint',
            fallback: 'Search churches, locations...',
          ),
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: FhcColors.canvas,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _DiscoverHero extends StatelessWidget {
  const _DiscoverHero({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.42,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF003D2D)),
            Positioned(
              right: -2,
              top: 0,
              bottom: 0,
              width: 205,
              child: Image.asset(
                'assets/images/discover_hero_globe.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                semanticLabel: fhcT(
                  context,
                  'church.worldMap',
                  fallback: 'World map',
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF003D2D),
                    Color(0xF2003D2D),
                    Color(0x7A003D2D),
                    Color(0x00003D2D),
                  ],
                  stops: [0, .48, .75, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 132, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fhcT(
                      context,
                      'church.discoverHeadline',
                      fallback: 'DISCOVER\nGREAT CHURCHES\nNEAR YOU',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fhcT(
                      context,
                      'church.discoverCopy',
                      fallback: 'Find a place to worship,\ngrow and belong.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 34,
                    child: FilledButton(
                      onPressed: onExplore,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: FhcColors.greenDark,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        fhcT(
                          context,
                          'church.exploreNow',
                          fallback: 'Explore Now',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }
}

class _ChurchCard extends StatelessWidget {
  const _ChurchCard({required this.church, required this.onOpen});

  final ChurchSummary church;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: FhcColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: FhcElevation.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/church_grace_hero.png',
                    width: 66,
                    height: 66,
                    fit: BoxFit.cover,
                    semanticLabel: church.name,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        church.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        church.location.placeLabel,
                        style: FhcTypography.caption,
                      ),
                      if (church.location.administrativeUnitName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          church.location.administrativeUnitName!,
                          style: FhcTypography.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: FhcColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

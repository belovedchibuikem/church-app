import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class SermonsLibraryScreen extends StatefulWidget {
  const SermonsLibraryScreen({super.key});

  @override
  State<SermonsLibraryScreen> createState() => _SermonsLibraryScreenState();
}

class _SermonsLibraryScreenState extends State<SermonsLibraryScreen> {
  int _tab = 0;
  String _query = '';
  final _searchFocus = FocusNode();

  static const _tabs = <String>['All', 'Series', 'Popular', 'Recent'];

  static const _featured = _Sermon(
    title: 'Faith That Moves Mountains',
    headline: 'FAITH THAT MOVES MOUNTAINS',
    speaker: 'Pastor John David',
    date: 'May 19, 2025',
    duration: '48:30',
    series: true,
    popular: true,
  );

  static const _sermons = <_Sermon>[
    _Sermon(
      title: 'Walking by Faith',
      date: 'May 12, 2025',
      duration: '35:12',
      series: true,
    ),
    _Sermon(
      title: 'The Power of Prayer',
      date: 'May 5, 2025',
      duration: '41:00',
      popular: true,
    ),
    _Sermon(
      title: 'Victory in Christ',
      date: 'Apr 28, 2025',
      duration: '39:22',
      popular: true,
    ),
    _Sermon(
      title: "God's Plan for You",
      date: 'Apr 21, 2025',
      duration: '36:45',
      series: true,
    ),
  ];

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  void _openFeatured() => fhcPush(context, FhcRoutes.live);

  bool _matches(_Sermon sermon) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return sermon.title.toLowerCase().contains(q) ||
        sermon.headline.toLowerCase().contains(q) ||
        sermon.speaker.toLowerCase().contains(q) ||
        sermon.date.toLowerCase().contains(q);
  }

  bool get _showFeatured {
    if (!_matches(_featured)) return false;
    return switch (_tab) {
      1 => _featured.series,
      2 => _featured.popular,
      _ => true,
    };
  }

  List<_Sermon> get _visible {
    var items = _sermons.where(_matches);
    items = switch (_tab) {
      1 => items.where((s) => s.series),
      2 => items.where((s) => s.popular),
      _ => items,
    };
    return items.toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    final showFeatured = _showFeatured;

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: 'Sermons',
            onBack: _goBack,
            trailing: IconButton(
              onPressed: () => _searchFocus.requestFocus(),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.search, size: 22),
              color: FhcColors.ink,
              tooltip: 'Search',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _SearchFilterRow(
              focusNode: _searchFocus,
              onQueryChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _SermonTab(
                      label: _tabs[i],
                      active: i == _tab,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                if (showFeatured) ...[
                  _FeaturedSermon(sermon: _featured, onTap: _openFeatured),
                  const SizedBox(height: 12),
                ],
                if (items.isEmpty && !showFeatured)
                  const _EmptySermons()
                else
                  FhcSurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: FhcColors.border),
                          _SermonRow(sermon: items[i], onTap: _openFeatured),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _Sermon {
  const _Sermon({
    required this.title,
    required this.date,
    required this.duration,
    this.headline = '',
    this.speaker = 'Pastor John David',
    this.series = false,
    this.popular = false,
  });

  final String title;
  final String headline;
  final String speaker;
  final String date;
  final String duration;
  final bool series;
  final bool popular;
}

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow({
    required this.focusNode,
    required this.onQueryChanged,
  });

  final FocusNode focusNode;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              focusNode: focusNode,
              style: FhcTypography.body,
              textInputAction: TextInputAction.search,
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search sermons...',
                hintStyle: FhcTypography.hint,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: FhcColors.muted,
                ),
                isDense: true,
                filled: true,
                fillColor: FhcColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: FhcColors.border),
                  borderRadius: radius,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: FhcColors.border),
                  borderRadius: radius,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: FhcColors.green,
                    width: 1.5,
                  ),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'Filter',
          child: InkWell(
            onTap: () {},
            borderRadius: radius,
            child: Ink(
              width: FhcSizes.minTap,
              height: FhcSizes.minTap,
              decoration: BoxDecoration(
                color: FhcColors.white,
                borderRadius: radius,
                border: Border.all(color: FhcColors.border),
              ),
              child: const Icon(Icons.tune, size: 20, color: FhcColors.ink),
            ),
          ),
        ),
      ],
    );
  }
}

class _SermonTab extends StatelessWidget {
  const _SermonTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 32,
          decoration: BoxDecoration(
            color: active ? FhcColors.green : FhcColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FhcColors.green),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: active ? FhcColors.white : FhcColors.green,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedSermon extends StatelessWidget {
  const _FeaturedSermon({required this.sermon, required this.onTap});

  final _Sermon sermon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.card);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          height: 188,
          decoration: BoxDecoration(
            color: FhcColors.navy,
            borderRadius: radius,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _SermonPhoto(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33061B3D),
                        Color(0x00061B3D),
                        Color(0xCC061B3D),
                      ],
                      stops: [0, 0.38, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sermon.headline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FhcColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sermon.speaker,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FhcColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sermon.date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FhcColors.white,
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: FhcColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 28,
                              color: FhcColors.green,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sermon.duration,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FhcColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _SermonRow extends StatelessWidget {
  const _SermonRow({required this.sermon, required this.onTap});

  final _Sermon sermon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const _SermonThumb(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sermon.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sermon.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: FhcColors.muted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sermon.duration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.muted,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SermonThumb extends StatelessWidget {
  const _SermonThumb();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FhcRadius.sm),
      child: const SizedBox(width: 80, height: 46, child: _SermonPhoto()),
    );
  }
}

class _SermonPhoto extends StatelessWidget {
  const _SermonPhoto();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/sermon_faith_mountains.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder:
          (context, error, stackTrace) => Image.asset(
            'assets/images/press_new_release_banner.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder:
                (context, error, stackTrace) => Image.asset(
                  'assets/images/live_fellowship.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const ColoredBox(color: FhcColors.navy),
                ),
          ),
    );
  }
}

class _EmptySermons extends StatelessWidget {
  const _EmptySermons();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          FhcCircleIcon(icon: Icons.video_library_outlined, size: 48),
          SizedBox(height: 12),
          Text(
            'No sermons found',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

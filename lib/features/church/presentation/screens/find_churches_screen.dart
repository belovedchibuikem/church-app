import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class FindChurchesScreen extends StatelessWidget {
  const FindChurchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          const _LocationHeader(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _SearchField(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                const _DiscoverHero(),
                const SizedBox(height: 16),
                const _SectionHeader(
                  title: 'Top Categories',
                  action: 'See All',
                ),
                const SizedBox(height: 10),
                const _CategoryRow(),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Recommended For You'),
                const SizedBox(height: 10),
                _RecommendedCard(
                  onOpen: () => fhcPush(context, FhcRoutes.churchDetail),
                  onJoinLive: () => fhcPush(context, FhcRoutes.live),
                ),
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 2),
        ],
      ),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FhcSizes.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: FhcColors.green),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Lagos, Nigeria',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FhcTypography.titleSmall,
              ),
            ),
            IconButton(
              onPressed: () => fhcPush(context, FhcRoutes.notifications),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.notifications_none, size: 22),
              color: FhcColors.ink,
              tooltip: 'Notifications',
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.md);
    return SizedBox(
      height: 44,
      child: TextField(
        style: FhcTypography.body,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search churches, locations...',
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
            borderSide: BorderSide.none,
            borderRadius: radius,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: radius,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: FhcColors.green, width: 1.5),
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}

class _DiscoverHero extends StatelessWidget {
  const _DiscoverHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: FhcColors.greenDark,
        borderRadius: BorderRadius.circular(FhcRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: -6,
            top: -8,
            bottom: -8,
            width: 148,
            child: _HeroGlobe(),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    FhcColors.greenDark,
                    Color(0xCC004B36),
                    Color(0x00004B36),
                  ],
                  stops: [0.0, 0.52, 0.88],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 108, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DISCOVER GREAT CHURCHES NEAR YOU',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: 0.2,
                    color: FhcColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Find a place to worship, grow and belong.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: FhcColors.white,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 30,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FhcColors.white,
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(
                        color: FhcColors.white,
                        width: 1.4,
                      ),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FhcRadius.button),
                      ),
                    ),
                    child: const Text(
                      'Explore Now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: FhcColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroGlobe extends StatelessWidget {
  const _HeroGlobe();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/discover_hero_globe.png',
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
      errorBuilder:
          (_, __, ___) => Image.asset(
            'assets/images/discover_globe.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder:
                (_, __, ___) => const ColoredBox(color: FhcColors.greenDark),
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: FhcColors.green,
            ),
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  static const _items = <(IconData, String)>[
    (Icons.location_on_outlined, 'Nearby'),
    (Icons.thumb_up_alt_outlined, 'Popular'),
    (Icons.play_circle_outline, 'Live Services'),
    (Icons.favorite_border, 'Youth'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _CategoryTile(icon: _items[i].$1, label: _items[i].$2),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FhcSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          children: [
            Icon(icon, size: 22, color: FhcColors.green),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: FhcColors.ink,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.onOpen, required this.onJoinLive});

  final VoidCallback onOpen;
  final VoidCallback onJoinLive;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChurchThumb(),
                    SizedBox(width: 12),
                    Expanded(child: _ChurchInfo()),
                    SizedBox(width: 8),
                    _LiveBadge(),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onJoinLive,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join Live Service',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: FhcColors.green,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Sunday 9:00 AM',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              color: FhcColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _JoinLiveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurchThumb extends StatelessWidget {
  const _ChurchThumb();

  static const _fallback = ColoredBox(
    color: FhcColors.mint,
    child: Center(
      child: Icon(Icons.church_outlined, size: 26, color: FhcColors.green),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FhcRadius.sm),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Image.asset(
          'assets/images/church_grace_hero.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder:
              (_, __, ___) => Image.asset(
                'assets/images/church_building.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder:
                    (_, __, ___) => Image.asset(
                      'assets/images/church_house.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => _fallback,
                    ),
              ),
        ),
      ),
    );
  }
}

class _ChurchInfo extends StatelessWidget {
  const _ChurchInfo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grace Home Church',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Ikeja, Lagos',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            color: FhcColors.muted,
          ),
        ),
        SizedBox(height: 2),
        Text(
          '1.2 km away',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            color: FhcColors.muted,
          ),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FhcColors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: FhcColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          height: 1.1,
        ),
      ),
    );
  }
}

class _JoinLiveButton extends StatelessWidget {
  const _JoinLiveButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: FhcColors.green,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.chevron_right,
        size: 20,
        color: FhcColors.white,
      ),
    );
  }
}

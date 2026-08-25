import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class PressLibraryScreen extends StatelessWidget {
  const PressLibraryScreen({super.key});

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  static void _openBook(BuildContext context) {
    fhcPush(context, FhcRoutes.pressBook);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: 'PRESS LIBRARY',
            onBack: () => _goBack(context),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _SearchFilterRow(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                _NewReleaseCard(onReadNow: () => _openBook(context)),
                const SizedBox(height: 18),
                const _SectionHeader(title: 'Browse Categories'),
                const SizedBox(height: 10),
                const _CategoryRow(),
                const SizedBox(height: 18),
                const _SectionHeader(title: 'Popular Resources'),
                const SizedBox(height: 10),
                FhcSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ResourceRow(
                        title: 'The Power of Prayer',
                        subtitle: 'Book • Pastor Tunde',
                        icon: Icons.menu_book_outlined,
                        assets: const [
                          'assets/images/press_power_of_prayer.png',
                        ],
                        onTap: () => _openBook(context),
                      ),
                      const Divider(height: 1, color: FhcColors.border),
                      _ResourceRow(
                        title: 'Walking in Purpose',
                        subtitle: 'Sermon • Pastor John',
                        icon: Icons.campaign_outlined,
                        assets: const [
                          'assets/images/book_walking_purpose.png',
                          'assets/images/press_winning_the_soul.png',
                          'assets/images/press_power_of_prayer.png',
                        ],
                        onTap: () => _openBook(context),
                      ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

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
        const Text(
          'See All',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: FhcColors.green,
          ),
        ),
      ],
    );
  }
}

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              style: FhcTypography.body,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search books, sermons, devotionals...',
                hintStyle: FhcTypography.hint,
                filled: true,
                fillColor: FhcColors.white,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: FhcColors.muted,
                ),
                isDense: true,
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

class _NewReleaseCard extends StatelessWidget {
  const _NewReleaseCard({required this.onReadNow});

  final VoidCallback onReadNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: FhcColors.wine,
        borderRadius: BorderRadius.circular(FhcRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: _ReleaseBanner()),
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 132,
            child: _ReleaseCover(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 122, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEW RELEASE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: FhcColors.gold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'KINGDOM LEADERSHIP',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Discover biblical principles for effective Kingdom leadership.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.3,
                    color: FhcColors.white,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 28,
                  child: FilledButton(
                    onPressed: onReadNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: FhcColors.gold,
                      foregroundColor: FhcColors.navy,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Read Now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
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

class _ReleaseBanner extends StatelessWidget {
  const _ReleaseBanner();

  @override
  Widget build(BuildContext context) {
    return const _ChainedAsset(
      paths: ['assets/images/press_new_release_banner.png'],
      alignment: Alignment.centerLeft,
    );
  }
}

class _ReleaseCover extends StatelessWidget {
  const _ReleaseCover();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000)],
          stops: [0.0, 0.22, 1.0],
        ).createShader(bounds);
      },
      child: const _ChainedAsset(
        paths: [
          'assets/images/press_kingdom_leadership.png',
          'assets/images/book_kingdom_leadership.png',
          'assets/images/press_book_cover.png',
        ],
        fallback: ColoredBox(
          color: Color(0xFF4A1826),
          child: Center(
            child: Icon(Icons.menu_book, color: FhcColors.gold, size: 42),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  static const _items = <(IconData, String)>[
    (Icons.menu_book_outlined, 'Books'),
    (Icons.campaign_outlined, 'Sermons'),
    (Icons.auto_stories_outlined, 'Devotionals'),
    (Icons.tablet_mac_outlined, 'eBooks'),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: FhcColors.white,
          borderRadius: BorderRadius.circular(FhcRadius.md),
          border: Border.all(color: FhcColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: FhcColors.navy),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: FhcColors.ink,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.assets,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final List<String> assets;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: _ChainedAsset(
                    paths: assets,
                    fallback: ColoredBox(
                      color: FhcColors.press.withValues(alpha: 0.10),
                      child: Icon(icon, color: FhcColors.press, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: FhcColors.muted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: FhcColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChainedAsset extends StatelessWidget {
  const _ChainedAsset({
    required this.paths,
    this.alignment = Alignment.center,
    this.fallback,
  });

  final List<String> paths;
  final Alignment alignment;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return _layer(0);
  }

  Widget _layer(int index) {
    if (index >= paths.length) {
      return fallback ?? const SizedBox.shrink();
    }
    return Image.asset(
      paths[index],
      fit: BoxFit.cover,
      alignment: alignment,
      errorBuilder: (_, __, ___) => _layer(index + 1),
    );
  }
}

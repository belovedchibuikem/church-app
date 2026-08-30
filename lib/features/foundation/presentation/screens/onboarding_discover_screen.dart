import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_brand_logo.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';
import '../onboarding_actions.dart';

class OnboardingDiscoverScreen extends StatelessWidget {
  const OnboardingDiscoverScreen({super.key});

  static const _copy =
      'Find churches, online fellowship,\nevents, resources and more.\nYou are never alone.';

  static const _tiles = <(IconData, String, String, Color)>[
    (
      Icons.location_on,
      'onboarding.findChurches',
      'Find Churches',
      FhcColors.green,
    ),
    (
      Icons.podcasts,
      'onboarding.onlineFellowship',
      'Online Fellowship',
      FhcColors.gold,
    ),
    (Icons.calendar_month, 'nav.events', 'Events', FhcColors.gold),
    (
      Icons.description_outlined,
      'onboarding.digitalResources',
      'Digital Resources',
      FhcColors.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final photoH = (h * 0.236).clamp(148.0, 198.0);
          final cardH = (h * 0.112).clamp(78.0, 102.0);
          final gap = h < 760 ? 8.0 : 12.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(20, h < 760 ? 12 : 20, 20, 8),
            child: Column(
              children: [
                Text(
                  fhcT(context, 'mobile.discover', fallback: 'DISCOVER'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: FhcColors.greenDark,
                  ),
                ),
                SizedBox(height: gap * 0.7),
                Text(
                  fhcT(
                    context,
                    'onboarding.familyHouse',
                    fallback: 'Family House',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: FhcColors.ink,
                  ),
                ),
                Text(
                  fhcT(
                    context,
                    'onboarding.anywhereInTheWorld',
                    fallback: 'Anywhere in the World',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: FhcColors.ink,
                  ),
                ),
                SizedBox(height: gap),
                Text(
                  fhcT(context, 'onboarding.discoverCopy', fallback: _copy),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: FhcColors.muted,
                  ),
                ),
                SizedBox(height: gap + 2),
                SizedBox(
                  height: photoH,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      'assets/images/discover_globe.png',
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => const ColoredBox(
                            color: FhcColors.mint,
                            child: Center(child: FhcBrandLogo(size: 120)),
                          ),
                    ),
                  ),
                ),
                SizedBox(height: gap),
                SizedBox(
                  height: cardH * 2 + 10,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _DiscoverTile(tile: _tiles[0])),
                            const SizedBox(width: 10),
                            Expanded(child: _DiscoverTile(tile: _tiles[1])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _DiscoverTile(tile: _tiles[2])),
                            const SizedBox(width: 10),
                            Expanded(child: _DiscoverTile(tile: _tiles[3])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const _DiscoverFooter(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({required this.tile});

  final (IconData, String, String, Color) tile;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tile.$1, color: tile.$4, size: 28),
          const SizedBox(height: 8),
          Text(
            fhcT(context, tile.$2, fallback: tile.$3),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: FhcColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverFooter extends StatelessWidget {
  const _DiscoverFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          TextButton(
            onPressed: () => fhcCompleteOnboarding(context),
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.muted,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              fhcT(context, 'common.skip', fallback: 'Skip'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: FhcColors.muted,
              ),
            ),
          ),
          const Spacer(),
          for (var i = 0; i < 3; i++)
            Container(
              width: i == 0 ? 9 : 7,
              height: i == 0 ? 9 : 7,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              decoration: BoxDecoration(
                color: i == 0 ? FhcColors.green : FhcColors.border,
                shape: BoxShape.circle,
              ),
            ),
          const Spacer(),
          IconButton.filled(
            onPressed: () => fhcGo(context, '/onboarding/connect'),
            tooltip: fhcT(context, 'common.next', fallback: 'Next'),
            style: IconButton.styleFrom(
              backgroundColor: FhcColors.green,
              foregroundColor: FhcColors.white,
              minimumSize: const Size(52, 52),
              maximumSize: const Size(52, 52),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_forward, size: 22),
          ),
        ],
      ),
    );
  }
}

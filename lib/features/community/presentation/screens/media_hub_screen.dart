import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class MediaHubScreen extends StatelessWidget {
  const MediaHubScreen({super.key});

  static const _cards = <_MediaSpec>[
    _MediaSpec(
      icon: Icons.play_circle,
      titleKey: 'online.watch',
      titleFallback: 'Watch',
      subtitleKey: 'online.watchCopy',
      subtitleFallback: 'Live services and video.',
      route: FhcRoutes.live,
    ),
    _MediaSpec(
      icon: Icons.headphones,
      titleKey: 'online.listen',
      titleFallback: 'Listen',
      subtitleKey: 'online.listenCopy',
      subtitleFallback: 'Sermons and audio messages.',
      route: FhcRoutes.sermons,
    ),
    _MediaSpec(
      icon: Icons.menu_book,
      titleKey: 'online.read',
      titleFallback: 'Read',
      subtitleKey: 'online.readCopy',
      subtitleFallback: 'Books, devotionals, and press.',
      route: FhcRoutes.press,
    ),
  ];

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.modules);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'online.media', fallback: 'Media'),
            onBack: () => _goBack(context),
            backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                fhcT(
                  context,
                  'online.mediaSubtitle',
                  fallback: 'Watch, listen, and read.',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: FhcColors.muted,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  for (var i = 0; i < _cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    Expanded(
                      child: _MediaCard(
                        spec: _cards[i],
                        onTap: () => fhcPush(context, _cards[i].route),
                      ),
                    ),
                  ],
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

class _MediaSpec {
  const _MediaSpec({
    required this.icon,
    required this.titleKey,
    required this.titleFallback,
    required this.subtitleKey,
    required this.subtitleFallback,
    required this.route,
  });

  final IconData icon;
  final String titleKey;
  final String titleFallback;
  final String subtitleKey;
  final String subtitleFallback;
  final String route;
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.spec, required this.onTap});

  final _MediaSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.card);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox.expand(
          child: FhcSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                FhcCircleIcon(
                  icon: spec.icon,
                  color: FhcColors.media,
                  size: 56,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fhcT(
                          context,
                          spec.titleKey,
                          fallback: spec.titleFallback,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: FhcColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fhcT(
                          context,
                          spec.subtitleKey,
                          fallback: spec.subtitleFallback,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: FhcColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: FhcColors.gold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

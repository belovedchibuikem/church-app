import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

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

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
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
            child: Row(
              children: [
                SizedBox(
                  width: FhcSizes.minTap,
                  child: IconButton(
                    onPressed: () => _goBack(context),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.chevron_left, size: 28),
                    color: FhcColors.navy,
                    tooltip: fhcT(context, 'common.back', fallback: 'Back'),
                  ),
                ),
                Expanded(
                  child: Text(
                    fhcT(
                      context,
                      'auth.chooseModule',
                      fallback: 'Choose a Module',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: FhcColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: FhcSizes.minTap),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              fhcT(
                context,
                'auth.selectModuleContinue',
                fallback: 'Select a module to continue.',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
                color: FhcColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  for (var row = 0; row < 3; row++) ...[
                    if (row > 0) const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModuleCard(
                              spec: _modules[row * 2],
                              onTap:
                                  () => fhcGo(context, _modules[row * 2].route),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModuleCard(
                              spec: _modules[row * 2 + 1],
                              onTap:
                                  () => fhcGo(
                                    context,
                                    _modules[row * 2 + 1].route,
                                  ),
                            ),
                          ),
                        ],
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

class _ModuleSpec {
  const _ModuleSpec({
    required this.icon,
    required this.titleKey,
    required this.titleFallback,
    required this.subtitleKey,
    required this.subtitleFallback,
    required this.color,
    required this.route,
  });

  final IconData icon;
  final String titleKey;
  final String titleFallback;
  final String subtitleKey;
  final String subtitleFallback;
  final Color color;
  final String route;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.spec, required this.onTap});

  final _ModuleSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = fhcT(context, spec.titleKey, fallback: spec.titleFallback);
    final subtitle = fhcT(
      context,
      spec.subtitleKey,
      fallback: spec.subtitleFallback,
    );
    final radius = BorderRadius.circular(FhcRadius.card);
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: FhcElevation.card,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  spec.color,
                  Color.lerp(spec.color, const Color(0xFF000000), 0.34)!,
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final iconSize = (constraints.maxHeight * 0.28).clamp(
                  28.0,
                  44.0,
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(spec.icon, color: FhcColors.white, size: iconSize),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FhcColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
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
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

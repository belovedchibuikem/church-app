import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class ModuleHubScreen extends StatelessWidget {
  const ModuleHubScreen({super.key});

  static const _modules = <_ModuleSpec>[
    _ModuleSpec(
      icon: Icons.church_outlined,
      title: 'CHURCH',
      subtitle: 'Connect, Grow, Serve',
      color: FhcColors.green,
      route: FhcRoutes.churchHome,
    ),
    _ModuleSpec(
      icon: Icons.public,
      title: 'MISSION',
      subtitle: 'Go, Preach, Disciple',
      color: FhcColors.purple,
      route: FhcRoutes.mission,
    ),
    _ModuleSpec(
      icon: Icons.school,
      title: 'KCA',
      subtitle: 'Grow, Learn, Lead',
      color: FhcColors.blue,
      route: FhcRoutes.kcaGate,
    ),
    _ModuleSpec(
      icon: Icons.menu_book,
      title: 'PRESS',
      subtitle: 'Publish, Teach, Inspire',
      color: FhcColors.wine,
      route: FhcRoutes.press,
    ),
  ];

  static const _actions = <(IconData, String, String)>[
    (Icons.pan_tool_outlined, 'Prayer', FhcRoutes.prayer),
    (Icons.event_outlined, 'Events', FhcRoutes.events),
    (Icons.favorite_border, 'Give', FhcRoutes.give),
    (Icons.chat_bubble_outline, 'Messages', FhcRoutes.messages),
  ];

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Chibuikem 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: FhcColors.ink,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select a module to enter and start operating.',
                  style: TextStyle(
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
                  final tileW = (constraints.maxWidth - gap) / 2;
                  final maxH = (constraints.maxHeight - gap) / 2;
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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text(
              'Quick Actions',
              style: TextStyle(
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
                      label: _actions[i].$2,
                      onTap: () {
                        final route = _actions[i].$3;
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
    required this.title,
    required this.subtitle,
    required this.color,
    this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
                spec.title,
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
                  spec.subtitle,
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

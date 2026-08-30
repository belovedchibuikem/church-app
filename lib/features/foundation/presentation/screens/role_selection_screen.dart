import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/launch/app_launch_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  int _selected = 0;

  static const _roles = <_RoleSpec>[
    _RoleSpec(
      icon: Icons.person_outline,
      titleKey: 'auth.roleMember',
      title: 'Member',
      subtitleKey: 'auth.roleMemberCopy',
      subtitle: 'I want to connect, grow and belong.',
    ),
    _RoleSpec(
      icon: Icons.groups_outlined,
      titleKey: 'auth.roleVolunteer',
      title: 'Volunteer / Worker',
      subtitleKey: 'auth.roleVolunteerCopy',
      subtitle: 'I serve in the ministry.',
    ),
    _RoleSpec(
      icon: Icons.school_outlined,
      titleKey: 'auth.roleKca',
      title: 'KCA Student',
      subtitleKey: 'auth.roleKcaCopy',
      subtitle: 'I want to grow through the KCA journey.',
    ),
    _RoleSpec(
      icon: Icons.person_pin_outlined,
      titleKey: 'auth.roleLeader',
      title: 'Leader / Pastor',
      subtitleKey: 'auth.roleLeaderCopy',
      subtitle: 'I lead a church or ministry.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(title: '', onBack: () => fhcGo(context, '/sign-in')),
          Text(
            fhcT(context, 'auth.whoAreYou', fallback: 'Who Are You?'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: FhcColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              fhcT(
                context,
                'auth.selectRoleCopy',
                fallback: 'Select the option that best describes you.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: FhcColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                children: [
                  for (var i = 0; i < _roles.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Expanded(
                      child: _RoleCard(
                        icon: _roles[i].icon,
                        title: fhcT(
                          context,
                          _roles[i].titleKey,
                          fallback: _roles[i].title,
                        ),
                        subtitle: fhcT(
                          context,
                          _roles[i].subtitleKey,
                          fallback: _roles[i].subtitle,
                        ),
                        selected: i == _selected,
                        onTap: () => setState(() => _selected = i),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FhcPrimaryButton(
                    label: fhcT(
                      context,
                      'common.continue',
                      fallback: 'Continue',
                    ),
                    onPressed: () async {
                      const keys = ['member', 'volunteer', 'kca', 'leader'];
                      await AppLaunchScope.maybeOf(
                        context,
                      )?.saveRole(keys[_selected]);
                      if (!context.mounted) return;
                      fhcReset(context, '/hub');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSpec {
  const _RoleSpec({
    required this.icon,
    required this.titleKey,
    required this.title,
    required this.subtitleKey,
    required this.subtitle,
  });

  final IconData icon;
  final String titleKey;
  final String title;
  final String subtitleKey;
  final String subtitle;
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? FhcColors.green : FhcColors.ink;
    return Material(
      color: FhcColors.white,
      borderRadius: BorderRadius.circular(FhcRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: FhcColors.white,
            borderRadius: BorderRadius.circular(FhcRadius.card),
            border: Border.all(
              color: selected ? FhcColors.green : FhcColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: FhcElevation.card,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 30, color: accent),
                const SizedBox(width: 16),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 22,
                  color: selected ? FhcColors.green : const Color(0xFFC5CBC8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

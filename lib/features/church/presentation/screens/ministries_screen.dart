import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class MinistriesScreen extends StatelessWidget {
  const MinistriesScreen({super.key});

  static List<_MinistryItem> _itemsOf(BuildContext context) => [
    _MinistryItem(
      title: fhcT(
        context,
        'member.worshipMinistry',
        fallback: 'Worship Ministry',
      ),
      subtitle: fhcT(
        context,
        'member.worshipMinistryCopy',
        fallback: 'Leading people in worship',
      ),
      icon: Icons.music_note_outlined,
      color: FhcColors.ink,
    ),
    _MinistryItem(
      title: fhcT(
        context,
        'member.childrenMinistry',
        fallback: 'Children Ministry',
      ),
      subtitle: fhcT(
        context,
        'member.childrenMinistryCopy',
        fallback: 'Teaching kids about Jesus Christ',
      ),
      icon: Icons.child_care_outlined,
      color: const Color(0xFF3B82F6),
    ),
    _MinistryItem(
      title: fhcT(context, 'member.youthMinistry', fallback: 'Youth Ministry'),
      subtitle: fhcT(
        context,
        'member.youthMinistryCopy',
        fallback: 'Empowering young people',
      ),
      icon: Icons.groups_outlined,
      color: FhcColors.green,
    ),
    _MinistryItem(
      title: fhcT(
        context,
        'member.outreachMinistry',
        fallback: 'Outreach Ministry',
      ),
      subtitle: fhcT(
        context,
        'member.outreachMinistryCopy',
        fallback: 'Reaching our community',
      ),
      icon: Icons.campaign_outlined,
      color: FhcColors.orange,
    ),
    _MinistryItem(
      title: fhcT(context, 'member.mediaMinistry', fallback: 'Media Ministry'),
      subtitle: fhcT(
        context,
        'member.mediaMinistryCopy',
        fallback: 'Producing church media',
      ),
      icon: Icons.videocam_outlined,
      color: FhcColors.purple,
    ),
    _MinistryItem(
      title: fhcT(context, 'member.usherMinistry', fallback: 'Usher Ministry'),
      subtitle: fhcT(
        context,
        'member.usherMinistryCopy',
        fallback: 'Serving with excellence',
      ),
      icon: Icons.handshake_outlined,
      color: FhcColors.navy,
    ),
  ];

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.churchHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsOf(context);

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'member.ministries', fallback: 'Ministries'),
            onBack: () => _goBack(context),
            trailing: IconButton(
              onPressed:
                  () => fhcApiUnavailable(
                    context,
                    action: fhcT(
                      context,
                      'member.creatingMinistry',
                      fallback: 'Creating a ministry',
                    ),
                  ),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, size: 24),
              color: FhcColors.ink,
              tooltip: fhcT(context, 'common.add', fallback: 'Add'),
            ),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                const _SearchField(),
                const SizedBox(height: 12),
                FhcMenuGroup(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      FhcMenuTile(
                        icon: items[i].icon,
                        title: items[i].title,
                        subtitle: items[i].subtitle,
                        accent: items[i].color,
                        showDivider: i < items.length - 1,
                        onTap: () => fhcPush(context, FhcRoutes.churchGroups),
                      ),
                  ],
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

class _MinistryItem {
  const _MinistryItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return TextField(
      style: FhcTypography.body,
      decoration: InputDecoration(
        hintText: fhcT(
          context,
          'member.searchMinistries',
          fallback: 'Search ministries...',
        ),
        hintStyle: FhcTypography.hint,
        filled: true,
        fillColor: FhcColors.white,
        prefixIcon: const Icon(Icons.search, size: 20, color: FhcColors.muted),
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
          borderSide: const BorderSide(color: FhcColors.green, width: 1.5),
          borderRadius: radius,
        ),
      ),
    );
  }
}

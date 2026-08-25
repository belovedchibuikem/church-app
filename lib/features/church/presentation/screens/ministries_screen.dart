import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class MinistriesScreen extends StatelessWidget {
  const MinistriesScreen({super.key});

  static const _items = <_MinistryItem>[
    _MinistryItem(
      title: 'Worship Ministry',
      subtitle: 'Leading people in worship',
      icon: Icons.music_note,
      color: FhcColors.ink,
    ),
    _MinistryItem(
      title: 'Children Ministry',
      subtitle: 'Teaching kids about Jesus',
      icon: Icons.groups,
      color: Color(0xFF3B82F6),
    ),
    _MinistryItem(
      title: 'Youth Ministry',
      subtitle: 'Empowering young people',
      icon: Icons.people_alt,
      color: FhcColors.green,
    ),
    _MinistryItem(
      title: 'Outreach Ministry',
      subtitle: 'Reaching our community',
      icon: Icons.campaign,
      color: FhcColors.orange,
    ),
    _MinistryItem(
      title: 'Media Ministry',
      subtitle: 'Producing church media',
      icon: Icons.videocam,
      color: FhcColors.purple,
    ),
    _MinistryItem(
      title: 'Usher Ministry',
      subtitle: 'Serving with excellence',
      icon: Icons.handshake,
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

  static void _openGroups(BuildContext context) {
    fhcPush(context, FhcRoutes.churchGroups);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: 'Ministries',
            onBack: () => _goBack(context),
            trailing: IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, size: 24),
              color: FhcColors.ink,
              tooltip: 'Add',
            ),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                const _SearchField(),
                const SizedBox(height: 8),
                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: FhcColors.border),
                  _MinistryRow(
                    item: _items[i],
                    onTap: () => _openGroups(context),
                  ),
                ],
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
        hintText: 'Search ministries...',
        hintStyle: FhcTypography.hint,
        filled: true,
        fillColor: FhcColors.canvas,
        prefixIcon: const Icon(Icons.search, size: 20, color: FhcColors.muted),
        isDense: true,
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
    );
  }
}

class _MinistryRow extends StatelessWidget {
  const _MinistryRow({required this.item, required this.onTap});

  final _MinistryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.title}, ${item.subtitle}',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                _SolidCircleIcon(icon: item.icon, color: item.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: FhcColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: FhcColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SolidCircleIcon extends StatelessWidget {
  const _SolidCircleIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: FhcColors.white),
    );
  }
}

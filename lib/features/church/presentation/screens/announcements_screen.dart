import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  int _tab = 1;

  static const _tabs = <String>['All', 'Unread', 'Favorites'];

  static const _items = <_AnnouncementItem>[
    _AnnouncementItem(
      title: 'New Sunday Service Time',
      date: 'May 20, 2025',
      snippet: 'Service time changed to 9:00 AM',
      color: FhcColors.orange,
      unread: true,
    ),
    _AnnouncementItem(
      title: 'Midweek Prayer',
      date: 'May 19, 2025',
      snippet: 'Join us this Wednesday at 6:00 PM',
      color: FhcColors.blue,
      unread: true,
      favorite: true,
    ),
    _AnnouncementItem(
      title: 'Baptism Class',
      date: 'May 18, 2025',
      snippet: 'Registration for baptism class is open',
      color: FhcColors.navy,
      unread: true,
    ),
    _AnnouncementItem(
      title: 'Choir Practice',
      date: 'May 17, 2025',
      snippet: 'Choir practice this Saturday',
      color: FhcColors.green,
      unread: true,
      favorite: true,
    ),
    _AnnouncementItem(
      title: 'Building Project Update',
      date: 'May 16, 2025',
      snippet: 'Phase 2 construction update',
      color: FhcColors.orange,
      unread: true,
    ),
  ];

  List<_AnnouncementItem> get _visible {
    return switch (_tab) {
      1 => _items.where((item) => item.unread).toList(),
      2 => _items.where((item) => item.favorite).toList(),
      _ => _items,
    };
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.churchHome);
    }
  }

  void _openItem() => fhcPush(context, FhcRoutes.notifications);

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(title: 'Announcements', onBack: _goBack),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _AnnouncementsTab(
                      label: _tabs[i],
                      active: i == _tab,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child:
                visible.isEmpty
                    ? const _EmptyState()
                    : ListView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                      children: [
                        for (var i = 0; i < visible.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: FhcColors.border),
                          _AnnouncementRow(item: visible[i], onTap: _openItem),
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

class _AnnouncementItem {
  const _AnnouncementItem({
    required this.title,
    required this.date,
    required this.snippet,
    required this.color,
    this.unread = false,
    this.favorite = false,
  });

  final String title;
  final String date;
  final String snippet;
  final Color color;
  final bool unread;
  final bool favorite;
}

class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab({
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
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? FhcColors.green : FhcColors.border,
                width: active ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: active ? FhcColors.green : FhcColors.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({required this.item, required this.onTap});

  final _AnnouncementItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.title}, ${item.date}, ${item.snippet}',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, right: 8),
                  child:
                      item.unread
                          ? const _NewDot()
                          : const SizedBox(width: 8, height: 8),
                ),
                FhcCircleIcon(
                  icon: Icons.campaign,
                  color: item.color,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                        item.date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: FhcColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: FhcColors.muted,
                        ),
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

class _NewDot extends StatelessWidget {
  const _NewDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: FhcColors.orange,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FhcCircleIcon(icon: Icons.campaign_outlined, size: 58),
            SizedBox(height: 14),
            Text(
              'No announcements',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Check back soon for church updates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: FhcColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

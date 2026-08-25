import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _tab = 0;

  late List<_NotificationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      const _NotificationItem(
        icon: Icons.assignment_outlined,
        color: FhcColors.orange,
        title: 'KCA Assignment Due',
        subtitle: 'Submit your Leadership Reflection by May 30, 2025.',
        time: '2m ago',
        route: FhcRoutes.kcaAssignments,
      ),
      const _NotificationItem(
        icon: Icons.description_outlined,
        color: FhcColors.blue,
        title: 'Home Church Report',
        subtitle: 'Your monthly report is due on May 31, 2025.',
        time: '15m ago',
        route: FhcRoutes.homeChurch,
      ),
      const _NotificationItem(
        icon: Icons.event_outlined,
        color: FhcColors.orange,
        title: 'Event Reminder',
        subtitle: 'Annual Convention 2025 tomorrow at 9:00 AM',
        time: '1h ago',
        route: FhcRoutes.events,
      ),
      const _NotificationItem(
        icon: Icons.chat_bubble_outline,
        color: FhcColors.muted,
        title: 'New Message',
        subtitle: 'Pastor John sent you a message',
        time: '2h ago',
        route: FhcRoutes.kcaMentor,
      ),
      const _NotificationItem(
        icon: Icons.public,
        color: FhcColors.purple,
        title: 'Mission Update',
        subtitle: 'Abuja City Crusade report is available.',
        time: '5h ago',
        route: FhcRoutes.mission,
      ),
      const _NotificationItem(
        icon: Icons.volunteer_activism_outlined,
        color: FhcColors.green,
        title: 'Prayer Request',
        subtitle: 'Sister Grace asked the church to pray with her.',
        time: '8h ago',
        route: FhcRoutes.prayer,
      ),
      const _NotificationItem(
        icon: Icons.alternate_email,
        color: FhcColors.blue,
        title: 'You were mentioned',
        subtitle: 'Pastor John mentioned you in Leadership & Influence',
        time: 'Yesterday',
        route: FhcRoutes.kcaMentor,
        mention: true,
      ),
      const _NotificationItem(
        icon: Icons.campaign_outlined,
        color: FhcColors.wine,
        title: 'New Sermon Uploaded',
        subtitle: 'Sunday Worship is now available to watch.',
        time: 'Yesterday',
        route: FhcRoutes.sermons,
      ),
      const _NotificationItem(
        icon: Icons.group_add_outlined,
        color: FhcColors.gold,
        title: 'Group Invitation',
        subtitle: 'You have been invited to Young Adults Fellowship.',
        time: '2 days ago',
        route: FhcRoutes.groups,
        mention: true,
      ),
      const _NotificationItem(
        icon: Icons.chat_bubble_outline,
        color: FhcColors.muted,
        title: 'New Message',
        subtitle: 'Church admin sent you a welcome message.',
        time: '2 days ago',
        route: FhcRoutes.messages,
      ),
      const _NotificationItem(
        icon: Icons.event_outlined,
        color: FhcColors.orange,
        title: 'Event Reminder',
        subtitle: 'KCA Graduation Ceremony is on Jun 15, 2025.',
        time: '3 days ago',
        route: FhcRoutes.events,
      ),
      const _NotificationItem(
        icon: Icons.volunteer_activism_outlined,
        color: FhcColors.green,
        title: 'Prayer Update',
        subtitle: 'Your prayer request has been received.',
        time: '4 days ago',
        route: FhcRoutes.prayer,
      ),
    ];
  }

  int get _unreadCount => _items.where((item) => item.unread).length;

  List<_NotificationItem> get _visible {
    return switch (_tab) {
      1 => _items.where((item) => item.unread).toList(),
      2 => _items.where((item) => item.mention).toList(),
      _ => _items,
    };
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.profile);
    }
  }

  void _markAllRead() {
    setState(() {
      _items = [for (final item in _items) item.copyWith(unread: false)];
    });
  }

  void _open(_NotificationItem item) {
    setState(() {
      _items = [
        for (final current in _items)
          current == item ? current.copyWith(unread: false) : current,
      ];
    });
    fhcPush(context, item.route);
  }

  @override
  Widget build(BuildContext context) {
    final unread = _unreadCount;
    final visible = _visible;

    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(title: 'NOTIFICATIONS', onBack: _goBack),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                Expanded(
                  child: _FilterTab(
                    label: 'All',
                    badge: '${_items.length}',
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                ),
                Expanded(
                  child: _FilterTab(
                    label: 'Unread',
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ),
                Expanded(
                  child: _FilterTab(
                    label: 'Mentions',
                    active: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                visible.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                      itemCount: visible.length,
                      separatorBuilder:
                          (_, __) => const Divider(
                            height: 1,
                            color: FhcColors.border,
                          ),
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        return _NotificationRow(
                          item: item,
                          onTap: () => _open(item),
                        );
                      },
                    ),
          ),
          _MarkAllFooter(enabled: unread > 0, onTap: _markAllRead),
          FhcBottomNavigation(
            selected: 4,
            onSelected: (index) => fhcTab(context, index),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.route,
    this.unread = true,
    this.mention = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final String route;
  final bool unread;
  final bool mention;

  _NotificationItem copyWith({bool? unread}) {
    return _NotificationItem(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      time: time,
      route: route,
      unread: unread ?? this.unread,
      mention: mention,
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final semantics = badge == null ? label : '$label $badge';
    return Semantics(
      button: true,
      selected: active,
      label: semantics,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: active ? FhcColors.ink : FhcColors.muted,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FhcColors.green,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onTap});

  final _NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: 12,
                child: item.unread ? const _UnreadDot() : null,
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 20, color: FhcColors.white),
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
                      color: FhcColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
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
            const SizedBox(width: 8),
            Text(
              item.time,
              style: const TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: FhcColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: FhcColors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MarkAllFooter extends StatelessWidget {
  const _MarkAllFooter({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Center(
        child: TextButton(
          onPressed: enabled ? onTap : null,
          style: TextButton.styleFrom(
            foregroundColor: FhcColors.green,
            disabledForegroundColor: FhcColors.hint,
            minimumSize: const Size(FhcSizes.minTap, FhcSizes.minTap),
          ),
          child: const Text(
            'Mark all as read',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
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
            FhcCircleIcon(icon: Icons.notifications_none, size: 58),
            SizedBox(height: 14),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'You are all caught up.',
              style: TextStyle(fontSize: 12, color: FhcColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

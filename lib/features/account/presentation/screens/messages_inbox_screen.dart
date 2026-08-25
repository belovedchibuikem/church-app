import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  int _tab = 0;

  static const _tabs = <String>['Inbox', 'Groups'];

  static const _threads = <_ThreadSpec>[
    _ThreadSpec(
      name: 'Pastor John',
      role: 'Mentor',
      snippet: 'Great job on Module 7! Keep going.',
      time: '10:20 AM',
      unread: 2,
      asset: 'assets/images/pastor_john_avatar.png',
      fallback: 'assets/images/mentor_john.png',
      route: FhcRoutes.kcaMentor,
    ),
    _ThreadSpec(
      name: 'Home Church Team',
      role: 'Group',
      snippet: 'Meeting reminder for this Sunday.',
      time: '9:15 AM',
      asset: 'assets/images/message_group.png',
      fallback: 'assets/images/member_avatar.png',
      group: true,
      route: FhcRoutes.groups,
    ),
    _ThreadSpec(
      name: 'KCA Leaders',
      role: 'Group',
      snippet: 'Leadership assignment updated.',
      time: 'Yesterday',
      asset: 'assets/images/mentor_john.png',
      fallback: 'assets/images/message_group.png',
      group: true,
      route: FhcRoutes.groups,
    ),
    _ThreadSpec(
      name: 'Mission Team',
      role: 'Group',
      snippet: 'Crusade report due this week.',
      time: 'Yesterday',
      asset: 'assets/images/mission_team_avatar.png',
      fallback: 'assets/images/member_avatar.png',
      group: true,
      route: FhcRoutes.groups,
    ),
    _ThreadSpec(
      name: 'Admin',
      role: 'Official',
      snippet: 'Your report has been approved.',
      time: 'May 18',
      asset: 'assets/images/member_avatar.png',
      fallback: 'assets/images/pastor_john_avatar.png',
    ),
  ];

  List<_ThreadSpec> get _visible =>
      _tab == 1 ? _threads.where((thread) => thread.group).toList() : _threads;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  void _selectTab(int index) {
    setState(() => _tab = index);
    if (index == 1) {
      fhcPush(context, FhcRoutes.groups);
    }
  }

  void _open(_ThreadSpec thread) {
    if (thread.route == null) return;
    fhcPush(context, thread.route!);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(title: 'MESSAGES', onBack: _goBack),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _InboxTab(
                      label: _tabs[i],
                      active: i == _tab,
                      onTap: () => _selectTab(i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child:
                visible.isEmpty
                    ? const _EmptyInbox()
                    : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: visible.length,
                      separatorBuilder:
                          (_, __) =>
                              const Divider(height: 1, color: FhcColors.border),
                      itemBuilder: (context, index) {
                        final thread = visible[index];
                        return _ThreadRow(
                          thread: thread,
                          onTap: () => _open(thread),
                        );
                      },
                    ),
          ),
          FhcBottomNavigation(
            selected: 3,
            onSelected: (index) => fhcTab(context, index),
          ),
        ],
      ),
    );
  }
}

class _ThreadSpec {
  const _ThreadSpec({
    required this.name,
    required this.role,
    required this.snippet,
    required this.time,
    required this.asset,
    required this.fallback,
    this.unread = 0,
    this.group = false,
    this.route,
  });

  final String name;
  final String role;
  final String snippet;
  final String time;
  final String asset;
  final String fallback;
  final int unread;
  final bool group;
  final String? route;
}

class _InboxTab extends StatelessWidget {
  const _InboxTab({
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
              fontSize: 13,
              height: 1.2,
              color: active ? FhcColors.green : FhcColors.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread, required this.onTap});

  final _ThreadSpec thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThreadAvatar(asset: thread.asset, fallback: thread.fallback),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: FhcColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      thread.snippet,
                      maxLines: 1,
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    thread.time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: FhcColors.muted,
                    ),
                  ),
                  if (thread.unread > 0) ...[
                    const SizedBox(height: 8),
                    _UnreadBadge(count: thread.unread),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadAvatar extends StatelessWidget {
  const _ThreadAvatar({required this.asset, required this.fallback});

  final String asset;
  final String fallback;

  static const _size = 48.0;

  Widget _leaf() {
    return const ColoredBox(
      color: FhcColors.mint,
      child: Icon(Icons.person_outline, size: 22, color: FhcColors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: _size,
        height: _size,
        child: Image.asset(
          asset,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => Image.asset(
                fallback,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _leaf(),
              ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count unread',
      child: Container(
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: FhcColors.green,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            fontSize: 10,
            height: 1,
            fontWeight: FontWeight.w700,
            color: FhcColors.white,
          ),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FhcCircleIcon(icon: Icons.chat_bubble_outline, size: 58),
            SizedBox(height: 14),
            Text(
              'No messages',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

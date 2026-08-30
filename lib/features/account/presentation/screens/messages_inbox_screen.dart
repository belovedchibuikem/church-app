import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key, this.messageRepository});

  final MessageRepository? messageRepository;

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  int _tab = 0;
  FhcAsyncValue<List<_ThreadSpec>> _state = const FhcAsyncValue.loading();

  MessageRepository? get _repo =>
      widget.messageRepository ??
      AppServicesScope.maybeOf(context)?.messageRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) {
      _load();
    }
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'account.messagingWaiting',
            fallback:
                'Messaging is waiting on the Laravel messages API. '
                'No fixture threads are shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.conversations();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'account.noConversations',
                fallback: 'No conversations yet.',
              ),
            );
          });
          return;
        }
        setState(() {
          _state = FhcAsyncValue.data([
            for (final item in value) _ThreadSpec.fromJson(item),
          ]);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  List<_ThreadSpec> _visible(List<_ThreadSpec> threads) =>
      _tab == 1 ? threads.where((thread) => thread.group).toList() : threads;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  void _selectTab(int index) {
    setState(() => _tab = index);
  }

  void _open(_ThreadSpec thread) {
    if (thread.id.isEmpty) return;
    fhcPush(context, '${FhcRoutes.kcaMentor}?conversation=${thread.id}');
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      fhcT(context, 'account.inbox', fallback: 'Inbox'),
      fhcT(context, 'account.groups', fallback: 'Groups'),
    ];
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'account.messagesTitle', fallback: 'MESSAGES'),
            onBack: _goBack,
            backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
          ),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _InboxTab(
                      label: tabs[i],
                      active: i == _tab,
                      onTap: () => _selectTab(i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FhcAsyncBody<List<_ThreadSpec>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'account.noMessages',
                fallback: 'No messages',
              ),
              emptyMessage: fhcT(
                context,
                'account.noMessagesCopy',
                fallback: 'Conversations will appear here.',
              ),
              unavailableTitle: fhcT(
                context,
                'account.messagingUnavailable',
                fallback: 'Messaging unavailable',
              ),
              builder: (context, threads) {
                final visible = _visible(threads);
                if (visible.isEmpty) {
                  return const _EmptyInbox();
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
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
    required this.id,
    required this.name,
    required this.role,
    required this.snippet,
    required this.time,
    this.unread = 0,
    this.group = false,
  });

  factory _ThreadSpec.fromJson(JsonObject json) {
    final unreadRaw = json['unread_count'] ?? json['unread'] ?? 0;
    final unread =
        unreadRaw is int ? unreadRaw : int.tryParse('$unreadRaw') ?? 0;
    final type = '${json['type'] ?? json['kind'] ?? ''}'.toLowerCase();
    return _ThreadSpec(
      id: '${json['id'] ?? json['ulid'] ?? ''}',
      name:
          '${json['subject'] ?? json['title'] ?? json['name'] ?? json['participant_name'] ?? 'Conversation'}',
      role: '${json['role'] ?? json['subtitle'] ?? (type == 'group' ? 'Group' : 'Inbox')}',
      snippet: '${json['last_message'] ?? json['snippet'] ?? json['preview'] ?? ''}',
      time: '${json['updated_at'] ?? json['last_message_at'] ?? json['time'] ?? ''}',
      unread: unread,
      group: type == 'group' || json['is_group'] == true,
    );
  }

  final String id;
  final String name;
  final String role;
  final String snippet;
  final String time;
  final int unread;
  final bool group;
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
              const CircleAvatar(
                radius: 24,
                backgroundColor: FhcColors.mint,
                child: Icon(Icons.person_outline, color: FhcColors.green),
              ),
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

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: fhcT(
        context,
        'account.unreadCount',
        args: {'count': '$count'},
        fallback: '$count unread',
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FhcCircleIcon(icon: Icons.chat_bubble_outline, size: 58),
            const SizedBox(height: 14),
            Text(
              fhcT(context, 'account.noMessages', fallback: 'No messages'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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

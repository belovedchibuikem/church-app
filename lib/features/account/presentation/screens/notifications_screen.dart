import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.notificationRepository});

  final NotificationRepository? notificationRepository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _tab = 0;
  FhcAsyncValue<List<_Notice>> _state = const FhcAsyncValue.loading();

  NotificationRepository? get _repo =>
      widget.notificationRepository ??
      AppServicesScope.maybeOf(context)?.notificationRepository;

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
            'account.notificationsWaiting',
            fallback:
                'Notifications are waiting on the Laravel notifications API.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.list();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'account.noNotifications',
                fallback: 'No notifications.',
              ),
            );
          });
          return;
        }
        setState(() {
          _state = FhcAsyncValue.data([
            for (final item in value) _Notice.fromJson(item),
          ]);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.profile);
    }
  }

  List<_Notice> _visible(List<_Notice> notices) {
    if (_tab == 1) return notices.where((item) => item.unread).toList();
    if (_tab == 2) return notices.where((item) => item.mention).toList();
    return notices;
  }

  Future<void> _open(_Notice item) async {
    final repo = _repo;
    if (repo != null && item.unread && item.id.isNotEmpty) {
      await repo.markRead(item.id);
      if (!mounted) return;
      final current = _state;
      if (current is FhcAsyncData<List<_Notice>>) {
        setState(() {
          _state = FhcAsyncValue.data([
            for (final notice in current.value)
              notice.id == item.id ? notice.copyWith(unread: false) : notice,
          ]);
        });
      }
      final resolved = await repo.resolveDestination(item.id);
      if (!mounted) return;
      if (resolved is AppSuccess<JsonObject>) {
        final dest =
            '${resolved.value['destination'] ?? item.route ?? ''}'.trim();
        if (dest.isNotEmpty) {
          fhcPush(context, dest.startsWith('/') ? dest : '/$dest');
          return;
        }
      }
    }
    if (item.route != null && item.route!.isNotEmpty) {
      fhcPush(context, item.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'common.notifications',
              fallback: 'Notifications',
            ),
            onBack: _back,
            backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
          ),
          Row(
            children: [
              Expanded(
                child: _NoticeTab(
                  label: fhcT(context, 'account.all', fallback: 'All'),
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
              ),
              Expanded(
                child: _NoticeTab(
                  label: fhcT(context, 'account.unread', fallback: 'Unread'),
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ),
              Expanded(
                child: _NoticeTab(
                  label: fhcT(
                    context,
                    'account.mentions',
                    fallback: 'Mentions',
                  ),
                  active: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ),
            ],
          ),
          Expanded(
            child: FhcAsyncBody<List<_Notice>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'account.noNotificationsTitle',
                fallback: 'No notifications',
              ),
              emptyMessage: fhcT(
                context,
                'account.noNotificationsCopy',
                fallback: 'Updates from your churches will appear here.',
              ),
              unavailableTitle: fhcT(
                context,
                'account.notificationsUnavailable',
                fallback: 'Notifications unavailable',
              ),
              builder: (context, notices) {
                final visible = _visible(notices);
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      fhcT(
                        context,
                        'account.noNotificationsTitle',
                        fallback: 'No notifications',
                      ),
                      style: FhcTypography.caption,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      return _NoticeRow(
                        item: item,
                        onTap: () => _open(item),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const FhcBottomNavigation(selected: 3),
        ],
      ),
    );
  }
}

class _Notice {
  const _Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.route,
    this.icon = Icons.notifications_outlined,
    this.unread = true,
    this.mention = false,
  });

  factory _Notice.fromJson(JsonObject json) {
    final readAt = json['read_at'];
    final unread = json['unread'] == true ||
        (json['unread'] == null && (readAt == null || '$readAt'.isEmpty));
    return _Notice(
      id: '${json['id'] ?? json['ulid'] ?? ''}',
      title: '${json['title'] ?? json['subject'] ?? 'Notification'}',
      body: '${json['body'] ?? json['message'] ?? ''}',
      time: '${json['created_at'] ?? json['time'] ?? ''}',
      route: '${json['destination'] ?? json['route'] ?? json['deep_link'] ?? ''}',
      icon: Icons.notifications_outlined,
      unread: unread,
      mention: json['mention'] == true || json['is_mention'] == true,
    );
  }

  final String id;
  final String title;
  final String body;
  final String time;
  final String? route;
  final IconData icon;
  final bool unread;
  final bool mention;

  _Notice copyWith({bool? unread}) => _Notice(
    id: id,
    title: title,
    body: body,
    time: time,
    route: route,
    icon: icon,
    unread: unread ?? this.unread,
    mention: mention,
  );
}

class _NoticeTab extends StatelessWidget {
  const _NoticeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? FhcColors.greenDark : FhcColors.ink,
          ),
        ),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.item, required this.onTap});
  final _Notice item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 95,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: FhcColors.mint,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 20, color: FhcColors.greenDark),
            ),
            const SizedBox(width: 11),
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
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.35,
                      color: FhcColors.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: FhcColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (item.unread)
              Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: FhcColors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key, this.prayerRepository});

  final PrayerRepository? prayerRepository;

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  int _tab = 1;
  FhcAsyncValue<List<_PrayerItem>> _state = const FhcAsyncValue.loading();

  PrayerRepository? get _repo =>
      widget.prayerRepository ??
      AppServicesScope.maybeOf(context)?.prayerRepository;

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
            'member.prayer.apiUnavailable',
            fallback:
                'Prayer requests are waiting on the Laravel prayers API. '
                'No fixture list is shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.listOwn();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'member.prayer.noneYet',
                fallback: 'You have not shared a prayer request yet.',
              ),
            );
          });
          return;
        }
        setState(() {
          _state = FhcAsyncValue.data([
            for (final item in value) _PrayerItem.fromJson(item, context),
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
      fhcGo(context, FhcRoutes.discover);
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
              'member.prayer.requests',
              fallback: 'Prayer Requests',
            ),
            onBack: _back,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              height: 160,
              padding: const EdgeInsets.fromLTRB(16, 17, 16, 14),
              decoration: BoxDecoration(
                color: FhcColors.greenDark,
                borderRadius: BorderRadius.circular(FhcRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fhcT(
                      context,
                      'member.prayer.bannerTitle',
                      fallback: 'We believe in the\npower of prayer.',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    fhcT(
                      context,
                      'member.prayer.bannerCopy',
                      fallback:
                          'Share your request and\nour team will pray with you.',
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: FilledButton(
                      onPressed: () => fhcPush(context, FhcRoutes.prayerNew),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: FhcColors.greenDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FhcRadius.sm),
                        ),
                      ),
                      child: Text(
                        fhcT(
                          context,
                          'member.prayer.newRequest',
                          fallback: 'New Prayer Request',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _PrayerTab(
                  label: fhcT(context, 'common.all', fallback: 'All'),
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
              ),
              Expanded(
                child: _PrayerTab(
                  label: fhcT(
                    context,
                    'member.prayer.myRequests',
                    fallback: 'My Requests',
                  ),
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ),
            ],
          ),
          Expanded(
            child: FhcAsyncBody<List<_PrayerItem>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'member.prayer.emptyTitle',
                fallback: 'No prayer requests',
              ),
              emptyMessage: fhcT(
                context,
                'member.prayer.emptyCopy',
                fallback: 'Share a request and others can pray with you.',
              ),
              unavailableTitle: fhcT(
                context,
                'member.prayer.unavailableTitle',
                fallback: 'Prayer unavailable',
              ),
              builder: (context, items) {
                final visible = _tab == 1
                    ? items.where((item) => item.isOwn).toList()
                    : items;
                if (visible.isEmpty) {
                  return FhcEmptyState(
                    title: fhcT(
                      context,
                      'member.prayer.tabEmptyTitle',
                      fallback: 'Nothing in this tab',
                    ),
                    message: fhcT(
                      context,
                      'member.prayer.tabEmptyCopy',
                      fallback: 'Try the other tab or create a new request.',
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder:
                        (context, index) => _PrayerRow(item: visible[index]),
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

class _PrayerItem {
  const _PrayerItem({
    required this.id,
    required this.title,
    required this.date,
    required this.meta,
    required this.isOwn,
    required this.icon,
  });

  factory _PrayerItem.fromJson(JsonObject json, BuildContext context) {
    final dateRaw = '${json['created_at'] ?? json['submitted_at'] ?? ''}';
    final parsed = DateTime.tryParse(dateRaw);
    final praying = json['praying_count'] ?? json['supporters'] ?? '';
    return _PrayerItem(
      id: '${json['id'] ?? json['ulid'] ?? ''}',
      title:
          '${json['subject'] ?? json['title'] ?? json['request'] ?? json['body'] ?? fhcT(context, 'member.prayer', fallback: 'Prayer')}',
      date:
          parsed == null
              ? (dateRaw.isEmpty ? '—' : dateRaw)
              : '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}',
      meta: praying.toString().isEmpty
          ? '${json['status'] ?? fhcT(context, 'member.prayer.shared', fallback: 'Shared')}'
          : fhcT(
              context,
              'member.prayer.prayingCount',
              args: {'count': '$praying'},
              fallback: '{count} Praying',
            ),
      isOwn: json['is_own'] != false,
      icon: Icons.volunteer_activism_outlined,
    );
  }

  final String id;
  final String title;
  final String date;
  final String meta;
  final bool isOwn;
  final IconData icon;
}

class _PrayerTab extends StatelessWidget {
  const _PrayerTab({
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
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 49,
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
              color: active ? FhcColors.green : FhcColors.ink,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({required this.item});
  final _PrayerItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.title}, ${item.meta}',
      child: InkWell(
        onTap: () {
          // Detail route not published; keep list as the bound surface.
        },
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: FhcColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 19, color: FhcColors.greenDark),
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
                        fontSize: 12,
                        color: FhcColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.date}  •  ${item.meta}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: FhcColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: FhcColors.mint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  fhcT(context, 'common.open', fallback: 'Open'),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.greenDark,
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

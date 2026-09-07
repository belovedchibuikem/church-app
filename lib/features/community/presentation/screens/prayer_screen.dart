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
  const PrayerScreen({
    super.key,
    this.prayerRepository,
    this.testimonyRepository,
  });

  final PrayerRepository? prayerRepository;
  final TestimonyRepository? testimonyRepository;

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  int _tab = 1;
  bool _started = false;
  FhcAsyncValue<List<_CareItem>> _prayerState = const FhcAsyncValue.loading();
  FhcAsyncValue<List<_CareItem>> _testimonyState =
      const FhcAsyncValue.loading();

  PrayerRepository? get _prayerRepo =>
      widget.prayerRepository ??
      AppServicesScope.maybeOf(context)?.prayerRepository;

  TestimonyRepository? get _testimonyRepo =>
      widget.testimonyRepository ??
      AppServicesScope.maybeOf(context)?.testimonyRepository;

  bool get _showingTestimonies => _tab == 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadPrayers(), _loadTestimonies()]);
  }

  Future<void> _loadPrayers() async {
    final repo = _prayerRepo;
    if (repo == null) {
      setState(() {
        _prayerState = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.prayer.apiUnavailable',
            fallback:
                'Prayer requests are waiting on the prayer service. '
                'No fixture list is shown.',
          ),
        );
      });
      return;
    }

    setState(() => _prayerState = const FhcAsyncValue.loading());
    final result = await repo.listOwn();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _prayerState = FhcAsyncValue.empty(
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
          _prayerState = FhcAsyncValue.data([
            for (final item in value) _CareItem.prayer(item, context),
          ]);
        });
      case AppError(:final failure):
        setState(() => _prayerState = FhcAsyncValue.error(failure));
    }
  }

  Future<void> _loadTestimonies() async {
    final repo = _testimonyRepo;
    if (repo == null) {
      setState(() {
        _testimonyState = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.testimony.apiUnavailable',
            fallback:
                'Testimonies are waiting on the testimony service. '
                'No fixture list is shown.',
          ),
        );
      });
      return;
    }

    setState(() => _testimonyState = const FhcAsyncValue.loading());
    final result = await repo.listOwn();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _testimonyState = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'member.testimony.noneYet',
                fallback:
                    'When God answers a prayer, share the testimony here.',
              ),
            );
          });
          return;
        }
        setState(() {
          _testimonyState = FhcAsyncValue.data([
            for (final item in value) _CareItem.testimony(item, context),
          ]);
        });
      case AppError(:final failure):
        setState(() => _testimonyState = FhcAsyncValue.error(failure));
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                  const SizedBox(height: 8),
                  Text(
                    fhcT(
                      context,
                      'member.prayer.bannerCopy',
                      fallback:
                          'Share your request and our team will pray with you. Come back with a testimony when God answers.',
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HeroActionButton(
                    label: fhcT(
                      context,
                      'member.prayer.newRequest',
                      fallback: 'New Prayer Request',
                    ),
                    filled: true,
                    onPressed: () => fhcPush(context, FhcRoutes.prayerNew),
                  ),
                  const SizedBox(height: 8),
                  _HeroActionButton(
                    label: fhcT(
                      context,
                      'member.testimony.share',
                      fallback: 'Share Testimony',
                    ),
                    filled: false,
                    onPressed: () => fhcPush(context, FhcRoutes.testimonyNew),
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
              Expanded(
                child: _PrayerTab(
                  label: fhcT(
                    context,
                    'member.testimony.tab',
                    fallback: 'Testimonies',
                  ),
                  active: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ),
            ],
          ),
          Expanded(
            child: _showingTestimonies
                ? FhcAsyncBody<List<_CareItem>>(
                    value: _testimonyState,
                    onRetry: _loadTestimonies,
                    emptyTitle: fhcT(
                      context,
                      'member.testimony.emptyTitle',
                      fallback: 'No testimonies yet',
                    ),
                    emptyMessage: fhcT(
                      context,
                      'member.testimony.emptyCopy',
                      fallback:
                          'Share how God answered prayer so others can be encouraged.',
                    ),
                    unavailableTitle: fhcT(
                      context,
                      'member.testimony.unavailableTitle',
                      fallback: 'Testimonies unavailable',
                    ),
                    builder: (context, items) => _CareList(
                      items: items,
                      onRefresh: _loadTestimonies,
                    ),
                  )
                : FhcAsyncBody<List<_CareItem>>(
                    value: _prayerState,
                    onRetry: _loadPrayers,
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
                            fallback:
                                'Try the other tab or create a new request.',
                          ),
                        );
                      }
                      return _CareList(
                        items: visible,
                        onRefresh: _loadPrayers,
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

class _CareItem {
  const _CareItem({
    required this.id,
    required this.title,
    required this.date,
    required this.meta,
    required this.isOwn,
    required this.icon,
  });

  factory _CareItem.prayer(JsonObject json, BuildContext context) {
    final praying = json['praying_count'] ?? json['supporters'] ?? '';
    return _CareItem(
      id: '${json['id'] ?? json['ulid'] ?? ''}',
      title:
          '${json['subject'] ?? json['title'] ?? json['request'] ?? json['body'] ?? fhcT(context, 'member.prayer', fallback: 'Prayer')}',
      date: _formatDate(json['created_at'] ?? json['submitted_at']),
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

  factory _CareItem.testimony(JsonObject json, BuildContext context) {
    return _CareItem(
      id: '${json['id'] ?? json['ulid'] ?? ''}',
      title:
          '${json['title'] ?? json['subject'] ?? fhcT(context, 'member.testimony', fallback: 'Testimony')}',
      date: _formatDate(json['submitted_at'] ?? json['created_at']),
      meta: '${json['status'] ?? fhcT(context, 'common.pending', fallback: 'pending')}',
      isOwn: true,
      icon: Icons.auto_awesome,
    );
  }

  static String _formatDate(Object? raw) {
    final dateRaw = '$raw';
    final parsed = DateTime.tryParse(dateRaw);
    if (parsed == null) {
      return dateRaw.isEmpty || dateRaw == 'null' ? '—' : dateRaw;
    }
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  final String id;
  final String title;
  final String date;
  final String meta;
  final bool isOwn;
  final IconData icon;
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: FhcColors.greenDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.sm),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.sm),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

class _CareList extends StatelessWidget {
  const _CareList({required this.items, required this.onRefresh});

  final List<_CareItem> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _CareRow(item: items[index]),
      ),
    );
  }
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _CareRow extends StatelessWidget {
  const _CareRow({required this.item});
  final _CareItem item;

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

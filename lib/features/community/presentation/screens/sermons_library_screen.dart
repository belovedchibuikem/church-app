import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../content/data/content_repository.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class SermonsLibraryScreen extends StatefulWidget {
  const SermonsLibraryScreen({super.key, this.contentRepository, this.pressRepository});

  final ContentRepository? contentRepository;
  final PressRepository? pressRepository;

  @override
  State<SermonsLibraryScreen> createState() => _SermonsLibraryScreenState();
}

class _SermonsLibraryScreenState extends State<SermonsLibraryScreen> {
  int _selected = 0;
  String _query = '';
  FhcAsyncValue<List<_SermonItem>> _state = const FhcAsyncValue.loading();
  bool _started = false;

  ContentRepository? get _content =>
      widget.contentRepository ??
      AppServicesScope.maybeOf(context)?.contentRepository;

  PressRepository? get _press =>
      widget.pressRepository ??
      AppServicesScope.maybeOf(context)?.pressRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const FhcAsyncValue.loading());

    final fromContent = await _loadFromContentPage();
    if (!mounted) return;
    if (fromContent != null) {
      setState(() => _state = fromContent);
      return;
    }

    final fromPress = await _loadFromPress();
    if (!mounted) return;
    setState(() => _state = fromPress);
  }

  Future<FhcAsyncValue<List<_SermonItem>>?> _loadFromContentPage() async {
    final repo = _content;
    if (repo == null) return null;
    final result = await repo.getContentPage('sermons');
    switch (result) {
      case AppSuccess(:final value):
        final blocks = value['blocks'];
        if (blocks is! List) return null;
        final items = <_SermonItem>[];
        for (final raw in blocks) {
          if (raw is! Map) continue;
          final kind = '${raw['kind'] ?? ''}'.toLowerCase();
          if (kind != 'sermon' && kind != 'card') continue;
          final title = '${raw['title'] ?? ''}'.trim();
          if (title.isEmpty) continue;
          final body = '${raw['body'] ?? ''}'.trim();
          final meta = raw['meta'];
          String? duration;
          if (meta is Map && meta['duration'] != null) {
            duration = '${meta['duration']}';
          }
          items.add(
            _SermonItem(
              id: '${raw['href'] ?? title}',
              title: title,
              subtitle: body.isEmpty ? null : body,
              duration: duration,
              href: raw['href'] is String ? raw['href'] as String : null,
            ),
          );
        }
        if (items.isEmpty) return null;
        return FhcAsyncValue.data(items);
      case AppError():
        return null;
    }
  }

  Future<FhcAsyncValue<List<_SermonItem>>> _loadFromPress() async {
    final repo = _press;
    if (repo == null) {
      return FhcAsyncValue.unavailable(
        message: fhcT(
          context,
          'online.sermonsRequireApi',
          fallback:
              'Sermons require the content or press catalogue API. '
              'No fixture list is shown.',
        ),
      );
    }

    final audio = await repo.search(const {'format': 'audio'});
    final video = await repo.search(const {'format': 'video'});
    if (!mounted) {
      return const FhcAsyncValue.loading();
    }

    final items = <_SermonItem>[];
    void collect(AppResult<List<JsonObject>> result) {
      if (result case AppSuccess(:final value)) {
        for (final row in value) {
          final title = '${row['title'] ?? ''}'.trim();
          if (title.isEmpty) continue;
          final id = '${row['id'] ?? row['public_id'] ?? title}';
          final published = row['published_at'] ?? row['created_at'];
          items.add(
            _SermonItem(
              id: id,
              title: title,
              subtitle: published == null
                  ? null
                  : _formatDate('$published'),
              duration: row['duration'] == null ? null : '${row['duration']}',
              publicationId: id,
            ),
          );
        }
      }
    }

    collect(audio);
    collect(video);

    if (items.isEmpty) {
      final eitherFailed =
          audio is AppError && video is AppError;
      if (eitherFailed) {
        final failure = (audio as AppError).failure;
        return FhcAsyncValue.error(failure);
      }
      return FhcAsyncValue.empty(
        message: fhcT(
          context,
          'online.noSermonsPublished',
          fallback: 'When sermons are published, they will appear here.',
        ),
      );
    }
    return FhcAsyncValue.data(items);
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = parsed.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.media);
    }
  }

  void _openItem(_SermonItem item) {
    if (item.publicationId != null && item.publicationId!.isNotEmpty) {
      fhcPush(context, '${FhcRoutes.pressBook}?id=${item.publicationId}');
      return;
    }
    fhcPush(context, FhcRoutes.live);
  }

  List<_SermonItem> _filtered(List<_SermonItem> items) {
    final q = _query.trim().toLowerCase();
    var rows = items;
    if (q.isNotEmpty) {
      rows = rows
          .where((item) => item.title.toLowerCase().contains(q))
          .toList(growable: false);
    }
    // Tabs: All / Series / Popular / Recent — Recent sorts by subtitle date
    // when present; others share the catalogue until series metadata ships.
    if (_selected == 3) {
      final copy = [...rows];
      copy.sort((a, b) => (b.subtitle ?? '').compareTo(a.subtitle ?? ''));
      return copy;
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      fhcT(context, 'online.sermonsAll', fallback: 'All'),
      fhcT(context, 'online.sermonsSeries', fallback: 'Series'),
      fhcT(context, 'online.sermonsPopular', fallback: 'Popular'),
      fhcT(context, 'online.sermonsRecent', fallback: 'Recent'),
    ];

    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          _Header(onBack: _back),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FhcSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      style: FhcTypography.body,
                      decoration: InputDecoration(
                        hintText: fhcT(
                          context,
                          'online.searchSermons',
                          fallback: 'Search sermons...',
                        ),
                        prefixIcon: const Icon(Icons.search, size: 19),
                        filled: true,
                        fillColor: FhcColors.white,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(FhcRadius.sm),
                          borderSide: const BorderSide(color: FhcColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SquareButton(
                  icon: Icons.tune,
                  label: fhcT(
                    context,
                    'online.filterSermons',
                    fallback: 'Filter sermons',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FhcSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                tabs.length,
                (index) => _Tab(
                  label: tabs[index],
                  active: _selected == index,
                  onTap: () => setState(() => _selected = index),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                children: [
                  FhcAsyncBody<List<_SermonItem>>(
                    value: _state,
                    onRetry: _load,
                    emptyTitle: fhcT(
                      context,
                      'online.noSermonsFound',
                      fallback: 'No sermons found',
                    ),
                    unavailableTitle: fhcT(
                      context,
                      'online.sermonsUnavailable',
                      fallback: 'Sermons unavailable',
                    ),
                    builder: (context, items) {
                      final rows = _filtered(items);
                      if (rows.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              fhcT(
                                context,
                                'online.noSermonsFound',
                                fallback: 'No sermons found',
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (var index = 0; index < rows.length; index++)
                            _SermonRow(
                              item: rows[index],
                              onTap: () => _openItem(rows[index]),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _SermonItem {
  const _SermonItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.duration,
    this.href,
    this.publicationId,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? duration;
  final String? href;
  final String? publicationId;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left, size: 27),
            tooltip: fhcT(context, 'common.back', fallback: 'Back'),
          ),
          Expanded(
            child: Text(
              fhcT(context, 'online.sermons', fallback: 'Sermons'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => fhcPush(context, FhcRoutes.notifications),
            icon: const Icon(Icons.notifications_none, size: 22),
            tooltip: fhcT(
              context,
              'notifications.title',
              fallback: 'Notifications',
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? FhcColors.greenDark : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? FhcColors.white : FhcColors.ink,
          ),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: FhcColors.border),
          borderRadius: BorderRadius.circular(FhcRadius.sm),
        ),
        child: Icon(icon, size: 20, color: FhcColors.ink),
      ),
    );
  }
}

class _SermonRow extends StatelessWidget {
  const _SermonRow({required this.item, required this.onTap});

  final _SermonItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: FhcColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                color: FhcColors.greenDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: FhcColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.duration != null)
              Text(
                item.duration!,
                style: const TextStyle(fontSize: 12, color: FhcColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

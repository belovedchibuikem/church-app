import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class PressLibraryScreen extends StatefulWidget {
  const PressLibraryScreen({super.key, this.repository});

  final PressRepository? repository;

  @override
  State<PressLibraryScreen> createState() => _PressLibraryScreenState();
}

class _PressLibraryScreenState extends State<PressLibraryScreen> {
  final _searchController = TextEditingController();
  FhcAsyncValue<List<JsonObject>> _state = const FhcAsyncValue.loading();
  String? _categoryFilter;

  PressRepository? get _repository =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.pressRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'errors.pressLibraryRequiresApi',
            fallback:
                'Press library requires the Laravel public publications API. '
                'No fixture catalogue is shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repository.search(const {
      'sort': 'title',
      'per_page': 50,
    });
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _state = value.isEmpty
              ? FhcAsyncValue.empty(
                  message: fhcT(
                    context,
                    'nav.pressEmptyLibrary',
                    fallback:
                        'When Press releases titles, they will appear in this library.',
                  ),
                )
              : FhcAsyncValue.data(value);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  void _openPublication(String id) {
    if (id.isEmpty) return;
    Navigator.of(context).pushNamed('/press/book/$id', arguments: id);
  }

  List<JsonObject> _filtered(List<JsonObject> publications) {
    final q = _searchController.text.trim().toLowerCase();
    final category = _categoryFilter;
    return publications.where((item) {
      final title = '${item['title'] ?? ''}'.toLowerCase();
      final subtitle = '${item['subtitle'] ?? ''}'.toLowerCase();
      final publisher = '${item['publisher'] ?? ''}'.toLowerCase();
      final itemCategory = '${item['category'] ?? ''}'.toLowerCase();
      final format = '${item['format'] ?? ''}'.toLowerCase();
      final haystack = '$title $subtitle $publisher $itemCategory $format';
      if (category != null &&
          !itemCategory.contains(category) &&
          !format.contains(category) &&
          !haystack.contains(category)) {
        return false;
      }
      if (q.isEmpty) return true;
      return haystack.contains(q);
    }).toList(growable: false);
  }

  String _subtitle(JsonObject item) {
    final format = '${item['format'] ?? ''}'.trim();
    final publisher = '${item['publisher'] ?? ''}'.trim();
    final category = '${item['category'] ?? ''}'.trim();
    final parts = <String>[
      if (format.isNotEmpty) _titleCase(format),
      if (publisher.isNotEmpty) publisher else if (category.isNotEmpty) category,
    ];
    return parts.isEmpty
        ? fhcT(context, 'nav.pressPublication', fallback: 'Publication')
        : parts.join(' • ');
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\s-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }

  static IconData _iconFor(JsonObject item) {
    final format = '${item['format'] ?? ''}'.toLowerCase();
    if (format.contains('audio')) return Icons.headphones_outlined;
    if (format.contains('sermon') || format.contains('video')) {
      return Icons.campaign_outlined;
    }
    return Icons.menu_book_outlined;
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'nav.pressLibrary', fallback: 'PRESS LIBRARY'),
            onBack: _goBack,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _SearchFilterRow(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              onFilter: () => fhcApiUnavailable(
                context,
                action: fhcT(
                  context,
                  'nav.pressAdvancedFilter',
                  fallback: 'Advanced Press filtering',
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FhcAsyncBody<List<JsonObject>>(
      value: _state,
      onRetry: _load,
      emptyTitle: fhcT(
        context,
        'errors.noPublicationsYet',
        fallback: 'No publications yet',
      ),
      emptyMessage: fhcT(
        context,
        'nav.pressEmptyLibrary',
        fallback:
            'When Press releases titles, they will appear in this library.',
      ),
      unavailableTitle: fhcT(
        context,
        'errors.pressUnavailable',
        fallback: 'Press unavailable',
      ),
      builder: (context, publications) {
        final items = _filtered(publications);
        final featured = items.isEmpty ? null : items.first;
        if (items.isEmpty) {
          return FhcEmptyState(
            title: fhcT(context, 'errors.noMatches', fallback: 'No matches'),
            message: fhcT(
              context,
              'common.tryDifferentSearch',
              fallback: 'Try a different search term.',
            ),
            icon: Icons.search_off,
            actionLabel: fhcT(
              context,
              'common.clearSearch',
              fallback: 'Clear search',
            ),
            onAction: () {
              _searchController.clear();
              setState(() {});
            },
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            children: [
              if (featured != null) ...[
                _NewReleaseCard(
                  title:
                      '${featured['title'] ?? fhcT(context, 'nav.pressNewRelease', fallback: 'New release')}',
                  description: () {
                    final subtitle = '${featured['subtitle'] ?? ''}'.trim();
                    if (subtitle.isNotEmpty) return subtitle;
                    final description =
                        '${featured['description'] ?? ''}'.trim();
                    if (description.isNotEmpty) return description;
                    return fhcT(
                      context,
                      'nav.pressDiscoverPublication',
                      fallback:
                          'Discover this Family House Press publication.',
                    );
                  }(),
                  onReadNow: () => _openPublication('${featured['id'] ?? ''}'),
                ),
                const SizedBox(height: 18),
              ],
              _SectionHeader(
                title: fhcT(
                  context,
                  'nav.pressBrowseCategories',
                  fallback: 'Browse Categories',
                ),
              ),
              const SizedBox(height: 10),
              _CategoryRow(
                selected: _categoryFilter,
                onSelect: (value) => setState(() => _categoryFilter = value),
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: fhcT(
                  context,
                  'nav.pressPopularResources',
                  fallback: 'Popular Resources',
                ),
              ),
              const SizedBox(height: 10),
              FhcSurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: FhcColors.border),
                      _ResourceRow(
                        title:
                            '${items[i]['title'] ?? fhcT(context, 'nav.pressPublication', fallback: 'Publication')}',
                        subtitle: _subtitle(items[i]),
                        icon: _iconFor(items[i]),
                        onTap: () =>
                            _openPublication('${items[i]['id'] ?? ''}'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: FhcColors.ink,
      ),
    );
  }
}

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow({
    required this.controller,
    required this.onChanged,
    required this.onFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: FhcTypography.body,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: fhcT(
                  context,
                  'common.searchPressHint',
                  fallback: 'Search books, sermons, devotionals...',
                ),
                hintStyle: FhcTypography.hint,
                filled: true,
                fillColor: FhcColors.white,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: FhcColors.muted,
                ),
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
                  borderSide: const BorderSide(
                    color: FhcColors.green,
                    width: 1.5,
                  ),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: fhcT(context, 'common.filter', fallback: 'Filter'),
          child: InkWell(
            onTap: onFilter,
            borderRadius: radius,
            child: Ink(
              width: FhcSizes.minTap,
              height: FhcSizes.minTap,
              decoration: BoxDecoration(
                color: FhcColors.white,
                borderRadius: radius,
                border: Border.all(color: FhcColors.border),
              ),
              child: const Icon(Icons.tune, size: 20, color: FhcColors.ink),
            ),
          ),
        ),
      ],
    );
  }
}

class _NewReleaseCard extends StatelessWidget {
  const _NewReleaseCard({
    required this.title,
    required this.description,
    required this.onReadNow,
  });

  final String title;
  final String description;
  final VoidCallback onReadNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: FhcColors.wine,
        borderRadius: BorderRadius.circular(FhcRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: 16,
            top: 24,
            child: Icon(Icons.menu_book, color: FhcColors.gold, size: 64),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 90, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fhcT(context, 'nav.pressFeatured', fallback: 'FEATURED'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: FhcColors.gold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.3,
                    color: FhcColors.white,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 28,
                  child: FilledButton(
                    onPressed: onReadNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: FhcColors.gold,
                      foregroundColor: FhcColors.navy,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      fhcT(context, 'nav.pressReadNow', fallback: 'Read Now'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String?> onSelect;

  static const _items = <(IconData, String, String, String?)>[
    (Icons.apps_outlined, 'common.all', 'All', null),
    (Icons.menu_book_outlined, 'nav.pressBooks', 'Books', 'books'),
    (Icons.campaign_outlined, 'nav.pressSermons', 'Sermons', 'sermons'),
    (
      Icons.auto_stories_outlined,
      'nav.pressDevotionals',
      'Devotionals',
      'devotionals',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _CategoryTile(
              icon: _items[i].$1,
              label: fhcT(context, _items[i].$2, fallback: _items[i].$3),
              active: selected == _items[i].$4,
              onTap: () => onSelect(_items[i].$4),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.md),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? FhcColors.press.withValues(alpha: 0.08)
                : FhcColors.white,
            borderRadius: BorderRadius.circular(FhcRadius.md),
            border: Border.all(
              color: active ? FhcColors.press : FhcColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? FhcColors.press : FhcColors.navy,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? FhcColors.press : FhcColors.ink,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(
                  color: FhcColors.press.withValues(alpha: 0.10),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(icon, color: FhcColors.press, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: FhcColors.muted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: FhcColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

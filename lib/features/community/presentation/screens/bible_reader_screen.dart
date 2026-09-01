import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

const _kBibleVersionPref = 'bible.version';
const _kParchment = Color(0xFFF7F3EA);

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key, this.repository});

  final BibleRepository? repository;

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  JsonObject? _chapter;
  List<JsonObject> _books = const [];
  String? _error;
  bool _loading = true;
  double _fontSize = 19;
  String? _loadedKey;
  String _version = 'kjv';

  BibleRepository? get _repository =>
      widget.repository ?? AppServicesScope.maybeOf(context)?.bibleRepository;

  String _versionFromRoute() {
    final name = ModalRoute.of(context)?.settings.name ?? '';
    final uri = Uri.tryParse(name.startsWith('/') ? 'https://fhc.local$name' : name);
    final fromQuery = uri?.queryParameters['v']?.trim();
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    return '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = FhcRouteArgs.maybeOf(context);
    final book = args?.entityId ?? 'john';
    final chapter = args?.secondaryId ?? '1';
    final version = _versionFromRoute();
    final key = '$book:$chapter:$version';
    if (_loadedKey != key) {
      _loadedKey = key;
      _load(book, int.tryParse(chapter) ?? 1, version);
    }
  }

  Future<void> _load(String book, int chapter, String version) async {
    var resolved = version;
    if (resolved.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        resolved = prefs.getString(_kBibleVersionPref) ?? 'kjv';
      } catch (_) {
        resolved = 'kjv';
      }
    }
    _version = resolved;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = _repository;
    if (repository == null) {
      setState(() {
        _loading = false;
        _error = fhcT(
          context,
          'bible.unavailable',
          fallback: 'The Bible API is not configured in this build.',
        );
      });
      return;
    }
    final result = await repository.chapter(book, chapter, version: resolved);
    if (_books.isEmpty) {
      final books = await repository.books(version: resolved);
      if (books is AppSuccess<JsonObject>) {
        final items = books.value['books'];
        if (items is List) {
          _books = [
            for (final item in items)
              if (item is Map)
                Map<String, Object?>.from(
                  item.map((key, value) => MapEntry('$key', value)),
                ),
          ];
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case AppSuccess(:final value):
          _chapter = value;
          _error = null;
          final current = value['version'];
          if (current is Map && current['id'] is String) {
            _version = current['id'] as String;
          }
        case AppError(:final failure):
          _error = failure.message;
      }
    });
    if (result is AppSuccess<JsonObject>) {
      await repository.savePosition(book, chapter);
    }
  }

  void _open(String slug, int chapter) {
    fhcGo(
      context,
      '/bible/$slug/$chapter?v=${Uri.encodeComponent(_version)}',
    );
  }

  void _openNeighbour(JsonObject? neighbour) {
    if (neighbour == null) return;
    _open(
      '${neighbour['book_slug']}',
      (neighbour['chapter'] as num?)?.toInt() ?? 1,
    );
  }

  Future<void> _pickBook() async {
    if (_books.isEmpty) return;
    final selected = await showModalBottomSheet<JsonObject>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _kParchment,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.7,
          child: ListView(
            children: [
              for (final book in _books)
                ListTile(
                  title: Text('${book['name']}'),
                  trailing: Text(
                    '${book['abbrev'] ?? book['id']}'.toString().toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: FhcColors.greenDark,
                    ),
                  ),
                  subtitle: Text(
                    book['testament'] == 'ot'
                        ? fhcT(
                            sheetContext,
                            'bible.oldTestament',
                            fallback: 'Old Testament',
                          )
                        : fhcT(
                            sheetContext,
                            'bible.newTestament',
                            fallback: 'New Testament',
                          ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, book),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    _open('${selected['slug']}', 1);
  }

  Future<void> _pickChapter() async {
    final book = _chapter?['book'];
    final bookMap = book is Map ? Map<String, Object?>.from(book) : null;
    final slug = '${bookMap?['slug'] ?? ''}';
    var count = (bookMap?['chapters'] as num?)?.toInt();
    if (count == null) {
      for (final item in _books) {
        if (item['slug'] == slug) {
          count = (item['chapters'] as num?)?.toInt() ?? 1;
          break;
        }
      }
    }
    count ??= 1;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: _kParchment,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.55,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GridView.builder(
              itemCount: count,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final chapter = index + 1;
                return Material(
                  color: FhcColors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(sheetContext, chapter),
                    child: Center(
                      child: Text(
                        '$chapter',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
    if (selected == null || slug.isEmpty) return;
    _open(slug, selected);
  }

  @override
  Widget build(BuildContext context) {
    final book = _chapter?['book'];
    final bookMap = book is Map ? Map<String, Object?>.from(book) : null;
    final verses = _chapter?['verses'];
    final verseList = verses is List
        ? [
            for (final item in verses)
              if (item is Map) Map<String, Object?>.from(item),
          ]
        : const <JsonObject>[];
    final previous = _chapter?['previous'];
    final next = _chapter?['next'];
    final title = bookMap == null
        ? fhcT(context, 'bible.title', fallback: 'Bible')
        : '${bookMap['name']} ${_chapter?['chapter']}';
    final versionLabel =
        '${(_chapter?['version'] is Map ? (_chapter!['version'] as Map)['abbreviation'] : null) ?? _version}'
            .toUpperCase();

    return FhcDevicePage(
      backgroundColor: _kParchment,
      child: Column(
        children: [
          FhcTopBar(
            title: title,
            onBack: () => Navigator.of(context).maybePop(),
            trailingWidth: 148,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  versionLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: FhcColors.greenDark,
                  ),
                ),
                IconButton(
                  tooltip: fhcT(
                    context,
                    'bible.fontSmaller',
                    fallback: 'Smaller text',
                  ),
                  onPressed: () =>
                      setState(() => _fontSize = (_fontSize - 1).clamp(16, 28)),
                  icon: const Icon(Icons.text_decrease),
                ),
                IconButton(
                  tooltip: fhcT(
                    context,
                    'bible.fontLarger',
                    fallback: 'Larger text',
                  ),
                  onPressed: () =>
                      setState(() => _fontSize = (_fontSize + 1).clamp(16, 28)),
                  icon: const Icon(Icons.text_increase),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _books.isEmpty ? null : _pickBook,
                    child: Text(
                      bookMap == null
                          ? fhcT(
                              context,
                              'bible.chooseBook',
                              fallback: 'Choose book',
                            )
                          : '${bookMap['name']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _chapter == null ? null : _pickChapter,
                  child: Text('${_chapter?['chapter'] ?? ''}'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                    children: [
                      for (final verse in verseList)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${verse['verse']}  ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: FhcColors.green,
                                    fontSize: 12,
                                    height: 1.7,
                                  ),
                                ),
                                TextSpan(
                                  text: '${verse['text']}',
                                  style: TextStyle(
                                    fontSize: _fontSize,
                                    height: 1.7,
                                    color: FhcColors.ink,
                                    fontFamily: 'Georgia',
                                    fontFamilyFallback: const [
                                      'serif',
                                      'Times New Roman',
                                      'Noto Serif',
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (previous is Map)
                            TextButton(
                              onPressed: () => _openNeighbour(
                                Map<String, Object?>.from(previous),
                              ),
                              child: Text(
                                '← ${previous['book_name']} ${previous['chapter']}',
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          if (next is Map)
                            TextButton(
                              onPressed: () => _openNeighbour(
                                Map<String, Object?>.from(next),
                              ),
                              child: Text(
                                '${next['book_name']} ${next['chapter']} →',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

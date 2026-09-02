import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/bible_kjv_markup.dart';

const _kBibleVersionPref = 'bible.version';
const _kParchment = Color(0xFFF7F3EA);
const _kParchmentDeep = Color(0xFFEFE6D6);

const _kDefaultVersions = <JsonObject>[
  {
    'id': 'kjv',
    'abbreviation': 'KJV',
    'name': 'King James Version',
    'available': true,
  },
  {
    'id': 'niv',
    'abbreviation': 'NIV',
    'name': 'New International Version',
    'available': false,
  },
  {
    'id': 'rsv',
    'abbreviation': 'RSV',
    'name': 'Revised Standard Version',
    'available': false,
  },
  {
    'id': 'amp',
    'abbreviation': 'AMP',
    'name': 'Amplified Bible',
    'available': false,
  },
];

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key, this.repository});

  final BibleRepository? repository;

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final _search = TextEditingController();
  final _bookFilter = TextEditingController();
  BibleRepository? _repository;
  List<JsonObject> _books = const [];
  List<JsonObject> _versions = _kDefaultVersions;
  JsonObject? _progress;
  List<JsonObject> _hits = const [];
  String? _error;
  bool _loading = true;
  bool _guest = true;
  bool _searching = false;
  bool _searched = false;
  String _testament = 'all';
  bool _completing = false;
  String _version = 'kjv';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository ??=
        widget.repository ?? AppServicesScope.maybeOf(context)?.bibleRepository;
    if (_loading) _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _bookFilter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) {
      setState(() {
        _loading = false;
        _guest = true;
        _error = fhcT(
          context,
          'bible.unavailable',
          fallback: 'The Bible API is not configured in this build.',
        );
      });
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kBibleVersionPref);
      if (stored != null && stored.isNotEmpty) {
        _version = stored;
      }
    } catch (_) {}
    final books = await repository.books(version: _version);
    final progress = await repository.progress();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (books) {
        case AppSuccess(:final value):
          _books = _asBooks(value);
          final versions = value['versions'];
          if (versions is List) {
            _versions = [
              for (final item in versions)
                if (item is Map)
                  Map<String, Object?>.from(
                    item.map((key, value) => MapEntry('$key', value)),
                  ),
            ];
          }
          final current = value['version'];
          if (current is Map && current['id'] is String) {
            _version = current['id'] as String;
          }
        case AppError(:final failure):
          _error = failure.message;
          _books = const [];
      }
      switch (progress) {
        case AppSuccess(:final value):
          _progress = value;
          _guest = false;
        case AppError():
          _progress = null;
          _guest = true;
      }
    });
  }

  List<JsonObject> _mapList(Object? items) {
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map)
          Map<String, Object?>.from(
            item.map((key, value) => MapEntry('$key', value)),
          ),
    ];
  }

  List<JsonObject> _asBooks(JsonObject value) => _mapList(value['books']);

  Future<void> _selectVersion(JsonObject version) async {
    final id = '${version['id'] ?? ''}';
    if (id.isEmpty) return;
    final available = version['available'] != false;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'bible.versionUnavailable',
              args: {'name': '${version['abbreviation'] ?? id}'},
              fallback:
                  '{name} is not installed on this church server yet. KJV remains available. Add a licensed {name} text file to enable it.',
            ),
          ),
        ),
      );
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kBibleVersionPref, id);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _version = id);
  }

  Future<void> _runSearch() async {
    final query = _search.text.trim();
    if (query.length < 2 || _repository == null) return;
    setState(() {
      _searching = true;
      _searched = true;
    });
    final result = await _repository!.search(query, version: _version);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _hits = switch (result) {
        AppSuccess(:final value) => _asHits(value),
        AppError(:final failure) => () {
          _error = failure.message;
          return const <JsonObject>[];
        }(),
      };
    });
    if (_hits.length == 1 && _looksLikeReference(query)) {
      _openHit(_hits.first);
    }
  }

  bool _looksLikeReference(String query) =>
      RegExp(r'\d').hasMatch(query) && query.contains(' ');

  List<JsonObject> _asHits(JsonObject value) => _mapList(value['results']);

  void _openChapter(String slug, int chapter) {
    fhcPush(context, '/bible/$slug/$chapter?v=${Uri.encodeComponent(_version)}');
  }

  void _openHit(JsonObject hit) {
    final slug = '${hit['book_slug'] ?? ''}';
    final chapter = (hit['chapter'] as num?)?.toInt() ?? 1;
    _openChapter(slug, chapter);
  }

  Future<void> _openBook(JsonObject book) async {
    final slug = '${book['slug'] ?? ''}';
    final count = (book['chapters'] as num?)?.toInt() ?? 1;
    final name = '${book['name'] ?? slug}';
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _kParchment,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: FhcTypography.title),
                const SizedBox(height: 4),
                Text(
                  fhcT(
                    context,
                    'bible.chooseChapter',
                    fallback: 'Choose chapter',
                  ),
                  style: FhcTypography.caption,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: count,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || slug.isEmpty) return;
    _openChapter(slug, selected);
  }

  List<JsonObject> get _filteredBooks {
    final needle = _bookFilter.text.trim().toLowerCase();
    return [
      for (final book in _books)
        if ((_testament == 'all' || book['testament'] == _testament) &&
            (needle.isEmpty ||
                '${book['name']}'.toLowerCase().contains(needle) ||
                '${book['abbrev'] ?? book['id']}'.toLowerCase().contains(
                  needle,
                ) ||
                '${book['slug']}'.contains(needle.replaceAll(' ', '-'))))
          book,
    ];
  }

  Future<void> _markDone(JsonObject enrollment, JsonObject due) async {
    final id = '${enrollment['id'] ?? ''}';
    final day = (due['day_number'] as num?)?.toInt();
    if (id.isEmpty || day == null || _repository == null) return;
    setState(() => _completing = true);
    final result = await _repository!.completeDay(id, day);
    if (!mounted) return;
    setState(() {
      _completing = false;
      switch (result) {
        case AppSuccess(:final value):
          _progress = value;
        case AppError(:final failure):
          _error = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBooks;
    final ot = filtered.where((book) => book['testament'] == 'ot').toList();
    final nt = filtered.where((book) => book['testament'] == 'nt').toList();
    final enrollment = _progress?['enrollment'];
    final enrollmentMap = enrollment is Map
            ? Map<String, Object?>.from(
              enrollment.map((key, value) => MapEntry('$key', value)),
            )
            : null;
    final due = enrollmentMap?['due'];
    final dueMap = due is Map
            ? Map<String, Object?>.from(
              due.map((key, value) => MapEntry('$key', value)),
            )
            : null;
    final position = _progress?['position'];
    final positionMap = position is Map
            ? Map<String, Object?>.from(
              position.map((key, value) => MapEntry('$key', value)),
            )
            : null;

    return FhcDevicePage(
      backgroundColor: _kParchment,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'bible.title', fallback: 'Bible'),
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                fhcGo(context, FhcRoutes.modules);
              }
            },
            trailing: TextButton(
              onPressed: () => fhcPush(context, FhcRoutes.biblePlans),
              child: Text(fhcT(context, 'bible.plans', fallback: 'Plans')),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
                _VersionSwitcher(
                  versions: _versions,
                  selected: _version,
                  onSelected: _selectVersion,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                  decoration: InputDecoration(
                    hintText: fhcT(
                      context,
                      'bible.searchPlaceholder',
                      fallback: 'Search a word or John 3:16',
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: _runSearch,
                          ),
                    filled: true,
                    fillColor: FhcColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(FhcRadius.md),
                      borderSide: const BorderSide(color: FhcColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(FhcRadius.md),
                      borderSide: const BorderSide(color: FhcColors.border),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFF9F1D32)),
                  ),
                ],
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_searched && _hits.isEmpty && !_searching) ...[
                  const SizedBox(height: 12),
                  Text(
                    fhcT(
                      context,
                      'bible.noResults',
                      fallback: 'No verses matched that search.',
                    ),
                  ),
                ],
                if (_hits.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final hit in _hits)
                    _SearchHit(
                      hit: hit,
                      query: _search.text.trim(),
                      onTap: () => _openHit(hit),
                    ),
                ],
                const SizedBox(height: 16),
                _TodayCard(
                  guest: _guest,
                  enrollment: enrollmentMap,
                  due: dueMap,
                  position: positionMap,
                  completing: _completing,
                  onMarkDone: enrollmentMap == null || dueMap == null
                              ? null
                              : () => _markDone(enrollmentMap, dueMap),
                  onOpenPassage: _openChapter,
                  onPlans: () => fhcPush(context, FhcRoutes.biblePlans),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _bookFilter,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: fhcT(
                      context,
                      'bible.filterBooks',
                      fallback: 'Find a book',
                    ),
                    prefixIcon: const Icon(Icons.menu_book_outlined, size: 20),
                    filled: true,
                    fillColor: FhcColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(FhcRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final entry in [
                      (
                        'all',
                        fhcT(context, 'bible.allBooks', fallback: 'All'),
                      ),
                      (
                        'ot',
                        fhcT(context, 'bible.oldTestament', fallback: 'OT'),
                      ),
                      (
                        'nt',
                        fhcT(context, 'bible.newTestament', fallback: 'NT'),
                      ),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Center(child: Text(entry.$2)),
                        selected: _testament == entry.$1,
                            onSelected: (_) =>
                                setState(() => _testament = entry.$1),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_testament != 'nt')
                  _BookGrid(
                    title: fhcT(
                      context,
                      'bible.oldTestament',
                      fallback: 'Old Testament',
                    ),
                    books: ot,
                    onOpen: _openBook,
                  ),
                if (_testament != 'ot')
                  _BookGrid(
                    title: fhcT(
                      context,
                      'bible.newTestament',
                      fallback: 'New Testament',
                    ),
                    books: nt,
                    onOpen: _openBook,
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

class _VersionSwitcher extends StatelessWidget {
  const _VersionSwitcher({
    required this.versions,
    required this.selected,
    required this.onSelected,
  });

  final List<JsonObject> versions;
  final String selected;
  final ValueChanged<JsonObject> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final version in versions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${version['abbreviation'] ?? version['id']}'),
                selected: selected == '${version['id']}',
                onSelected: (_) => onSelected(version),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchHit extends StatelessWidget {
  const _SearchHit({
    required this.hit,
    required this.query,
    required this.onTap,
  });

  final JsonObject hit;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: FhcColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hit['reference'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: FhcColors.greenDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  _highlight(parseKjvMarkup('${hit['text'] ?? ''}').reading, query),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _highlight(String text, String query) {
    final needle = query.trim();
    if (needle.length < 2) {
      return TextSpan(text: text, style: FhcTypography.body);
    }
    final lower = text.toLowerCase();
    final match = needle.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = lower.indexOf(match, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start), style: FhcTypography.body));
        break;
      }
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: FhcTypography.body),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + needle.length),
          style: FhcTypography.body.copyWith(
            fontWeight: FontWeight.w700,
            backgroundColor: const Color(0xFFFFF3BF),
          ),
        ),
      );
      start = index + needle.length;
    }
    return TextSpan(children: spans);
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.guest,
    required this.enrollment,
    required this.due,
    required this.position,
    required this.completing,
    required this.onMarkDone,
    required this.onOpenPassage,
    required this.onPlans,
  });

  final bool guest;
  final JsonObject? enrollment;
  final JsonObject? due;
  final JsonObject? position;
  final bool completing;
  final VoidCallback? onMarkDone;
  final void Function(String slug, int chapter) onOpenPassage;
  final VoidCallback onPlans;

  @override
  Widget build(BuildContext context) {
    final passages = due == null
        ? const <JsonObject>[]
        : [
            for (final item in (due!['passages'] as List? ?? const [])
                .whereType<Map>())
              Map<String, Object?>.from(
                item.map((key, value) => MapEntry('$key', value)),
              ),
          ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FhcColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kParchmentDeep),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fhcT(context, 'bible.today', fallback: "Today's reading"),
            style: FhcTypography.titleSmall,
          ),
          const SizedBox(height: 8),
          if (due != null) ...[
            Text(
              fhcT(
                context,
                'bible.dayOf',
                args: {
                  'day': '${due!['day_number'] ?? ''}',
                  'total': '${enrollment?['day_count'] ?? ''}',
                },
                fallback: 'Day {day} of {total}',
              ),
            ),
            if (enrollment?['is_catching_up'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  fhcT(
                    context,
                    'bible.catchUp',
                    args: {'count': '${enrollment?['overdue_days'] ?? 0}'},
                    fallback:
                        'Catch up first — {count} missed day(s) still due.',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            for (final passage in passages)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('${passage['book_name']} ${passage['chapter']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenPassage(
                  '${passage['book_slug']}',
                  (passage['chapter'] as num?)?.toInt() ?? 1,
                ),
              ),
            FilledButton(
              onPressed: completing ? null : onMarkDone,
              child: Text(
                fhcT(context, 'bible.markDone', fallback: 'Mark today complete'),
              ),
            ),
          ] else if (guest)
            Text(
              fhcT(
                context,
                'bible.signInForPlans',
                fallback:
                    'Sign in to start a reading plan and track today’s target.',
              ),
            )
          else
            Text(
              fhcT(
                context,
                'bible.choosePlanCopy',
                fallback:
                    'Choose 3 months, 6 months, 1 year, 2 years, or a custom length.',
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onPlans,
              child: Text(
                fhcT(context, 'bible.choosePlan', fallback: 'Choose a plan'),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: position == null
                  ? () => onOpenPassage('john', 1)
                  : () => onOpenPassage(
                        '${position!['book_slug']}',
                        (position!['chapter'] as num?)?.toInt() ?? 1,
                      ),
              child: Text(
                position == null
                    ? fhcT(
                        context,
                        'bible.startJohn',
                        fallback: 'Start in John 1',
                      )
                    : '${fhcT(context, 'bible.continueReading', fallback: 'Continue reading')} · ${position!['book_name']} ${position!['chapter']}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  const _BookGrid({
    required this.title,
    required this.books,
    required this.onOpen,
  });

  final String title;
  final List<JsonObject> books;
  final ValueChanged<JsonObject> onOpen;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FhcTypography.titleSmall),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const columns = 3;
              const gap = 8.0;
              final width =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
            children: [
              for (final book in books)
                    SizedBox(
                      width: width,
                      child: Material(
                        color: FhcColors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onOpen(book),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${book['abbrev'] ?? '${book['id']}'.toString().toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: FhcColors.greenDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${book['name']}',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${book['chapters']} ch',
                                  style: FhcTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

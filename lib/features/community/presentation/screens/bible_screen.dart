import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

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
  JsonObject? _progress;
  List<JsonObject> _hits = const [];
  String? _error;
  bool _loading = true;
  bool _guest = true;
  bool _searching = false;
  bool _searched = false;
  String _testament = 'all';
  bool _completing = false;

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
    final books = await repository.books();
    final progress = await repository.progress();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _books = switch (books) {
        AppSuccess(:final value) => _asBooks(value),
        AppError(:final failure) => () {
          _error = failure.message;
          return const <JsonObject>[];
        }(),
      };
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

  Future<void> _runSearch() async {
    final query = _search.text.trim();
    if (query.length < 2 || _repository == null) return;
    setState(() {
      _searching = true;
      _searched = true;
    });
    final result = await _repository!.search(query);
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
    if (_hits.length == 1) {
      _openHit(_hits.first);
    }
  }

  List<JsonObject> _asHits(JsonObject value) => _mapList(value['results']);

  void _openChapter(String slug, int chapter) {
    fhcPush(context, '/bible/$slug/$chapter');
  }

  void _openHit(JsonObject hit) {
    final slug = '${hit['book_slug'] ?? ''}';
    final chapter = (hit['chapter'] as num?)?.toInt() ?? 1;
    _openChapter(slug, chapter);
  }

  List<JsonObject> get _filteredBooks {
    final needle = _bookFilter.text.trim().toLowerCase();
    return [
      for (final book in _books)
        if ((_testament == 'all' || book['testament'] == _testament) &&
            (needle.isEmpty ||
                '${book['name']}'.toLowerCase().contains(needle) ||
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
    final enrollmentMap =
        enrollment is Map
            ? Map<String, Object?>.from(
              enrollment.map((key, value) => MapEntry('$key', value)),
            )
            : null;
    final due = enrollmentMap?['due'];
    final dueMap =
        due is Map
            ? Map<String, Object?>.from(
              due.map((key, value) => MapEntry('$key', value)),
            )
            : null;
    final position = _progress?['position'];
    final positionMap =
        position is Map
            ? Map<String, Object?>.from(
              position.map((key, value) => MapEntry('$key', value)),
            )
            : null;

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                  decoration: InputDecoration(
                    hintText: fhcT(
                      context,
                      'bible.searchPlaceholder',
                      fallback: 'Try John 3:16 or faith',
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
                      borderRadius: BorderRadius.circular(FhcRadius.sm),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFF9F1D32))),
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${hit['reference'] ?? ''}'),
                      subtitle: Text(
                        '${hit['text'] ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _openHit(hit),
                    ),
                ],
                const SizedBox(height: 16),
                FhcSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fhcT(context, 'bible.today', fallback: "Today's reading"),
                        style: FhcTypography.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (dueMap != null) ...[
                        Text(
                          fhcT(
                            context,
                            'bible.dayOf',
                            args: {
                              'day': '${dueMap['day_number'] ?? ''}',
                              'total': '${enrollmentMap?['day_count'] ?? ''}',
                            },
                            fallback: 'Day {day} of {total}',
                          ),
                        ),
                        if (enrollmentMap?['is_catching_up'] == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              fhcT(
                                context,
                                'bible.catchUp',
                                args: {
                                  'count': '${enrollmentMap?['overdue_days'] ?? 0}',
                                },
                                fallback:
                                    'Catch up first — {count} missed day(s) still due.',
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        ..._passages(dueMap).map(
                          (passage) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${passage['book_name']} ${passage['chapter']}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openChapter(
                              '${passage['book_slug']}',
                              (passage['chapter'] as num?)?.toInt() ?? 1,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: _completing || enrollmentMap == null
                              ? null
                              : () => _markDone(enrollmentMap, dueMap),
                          child: Text(
                            fhcT(
                              context,
                              'bible.markDone',
                              fallback: 'Mark today complete',
                            ),
                          ),
                        ),
                      ] else if (_guest)
                        Text(
                          fhcT(
                            context,
                            'bible.signInForPlans',
                            fallback:
                                'Sign in to start a yearly plan and track today’s target.',
                          ),
                        )
                      else
                        Text(
                          fhcT(
                            context,
                            'bible.choosePlanCopy',
                            fallback:
                                'Choose a 1, 2, or 3 year plan to see a daily target.',
                          ),
                        ),
                      TextButton(
                        onPressed: () => fhcPush(context, FhcRoutes.biblePlans),
                        child: Text(
                          fhcT(context, 'bible.choosePlan', fallback: 'Choose a plan'),
                        ),
                      ),
                      TextButton(
                        onPressed: positionMap == null
                            ? () => _openChapter('john', 1)
                            : () => _openChapter(
                                  '${positionMap['book_slug']}',
                                  (positionMap['chapter'] as num?)?.toInt() ?? 1,
                                ),
                        child: Text(
                          positionMap == null
                              ? fhcT(
                                  context,
                                  'bible.startJohn',
                                  fallback: 'Start in John 1',
                                )
                              : '${fhcT(context, 'bible.continueReading', fallback: 'Continue reading')} · ${positionMap['book_name']} ${positionMap['chapter']}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                      borderRadius: BorderRadius.circular(FhcRadius.sm),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in [
                      ('all', fhcT(context, 'bible.allBooks', fallback: 'All books')),
                      (
                        'ot',
                        fhcT(context, 'bible.oldTestament', fallback: 'Old Testament'),
                      ),
                      (
                        'nt',
                        fhcT(context, 'bible.newTestament', fallback: 'New Testament'),
                      ),
                    ])
                      ChoiceChip(
                        label: Text(entry.$2),
                        selected: _testament == entry.$1,
                        onSelected: (_) => setState(() => _testament = entry.$1),
                      ),
                  ],
                ),
                if (_testament != 'nt')
                  _BookSection(
                    title: fhcT(context, 'bible.oldTestament', fallback: 'Old Testament'),
                    books: ot,
                    onOpen: _openChapter,
                  ),
                if (_testament != 'ot')
                  _BookSection(
                    title: fhcT(context, 'bible.newTestament', fallback: 'New Testament'),
                    books: nt,
                    onOpen: _openChapter,
                  ),
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }

  List<JsonObject> _passages(JsonObject due) => _mapList(due['passages']);
}

class _BookSection extends StatelessWidget {
  const _BookSection({
    required this.title,
    required this.books,
    required this.onOpen,
  });

  final String title;
  final List<JsonObject> books;
  final void Function(String slug, int chapter) onOpen;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FhcTypography.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final book in books)
                ActionChip(
                  label: Text('${book['name']}'),
                  onPressed: () => onOpen('${book['slug']}', 1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

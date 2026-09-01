/// KJV public-domain dumps encode italics and margin notes in `{braces}`.
///
/// `{are}` — words supplied in English (print KJV: italics).
/// `{firmament: Heb. expansion}` — translator / language note (print KJV: margin).
enum KjvMarkupKind { text, supplied, note }

final class KjvMarkupRun {
  const KjvMarkupRun(this.kind, this.value);

  final KjvMarkupKind kind;
  final String value;
}

final class KjvParsedVerse {
  const KjvParsedVerse(this.runs);

  final List<KjvMarkupRun> runs;

  String get reading => [
    for (final run in runs)
      if (run.kind != KjvMarkupKind.note) run.value,
  ].join();

  List<String> get notes => [
    for (final run in runs)
      if (run.kind == KjvMarkupKind.note && run.value.trim().isNotEmpty)
        run.value.trim(),
  ];
}

KjvParsedVerse parseKjvMarkup(String raw) {
  if (!raw.contains('{')) {
    return KjvParsedVerse([KjvMarkupRun(KjvMarkupKind.text, raw)]);
  }

  final runs = <KjvMarkupRun>[];
  final pattern = RegExp(r'\{([^{}]*)\}');
  var cursor = 0;
  for (final match in pattern.allMatches(raw)) {
    if (match.start > cursor) {
      runs.add(
        KjvMarkupRun(KjvMarkupKind.text, raw.substring(cursor, match.start)),
      );
    }
    final inner = match.group(1) ?? '';
    if (_isTranslatorNote(inner)) {
      final note = inner.trim();
      if (note.isNotEmpty) {
        runs.add(KjvMarkupRun(KjvMarkupKind.note, note));
      }
    } else {
      runs.add(KjvMarkupRun(KjvMarkupKind.supplied, inner));
    }
    cursor = match.end;
  }
  if (cursor < raw.length) {
    runs.add(KjvMarkupRun(KjvMarkupKind.text, raw.substring(cursor)));
  }
  return KjvParsedVerse(List<KjvMarkupRun>.unmodifiable(runs));
}

bool _isTranslatorNote(String inner) {
  return inner.contains(':');
}

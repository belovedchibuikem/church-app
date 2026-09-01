import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../data/bible_kjv_markup.dart';

const _kSuperscripts = ['¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];

/// Renders KJV brace markup: supplied words in italics, notes as tappable marks.
class BibleVerseRichText extends StatelessWidget {
  const BibleVerseRichText({
    super.key,
    required this.raw,
    required this.verseNumber,
    required this.fontSize,
  });

  final String raw;
  final Object? verseNumber;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final parsed = parseKjvMarkup(raw);
    var noteIndex = 0;
    final bodyStyle = TextStyle(
      fontSize: fontSize,
      height: 1.7,
      color: FhcColors.ink,
      fontFamily: 'Georgia',
      fontFamilyFallback: const ['serif', 'Times New Roman', 'Noto Serif'],
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$verseNumber  ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: FhcColors.green,
              fontSize: 12,
              height: 1.7,
            ),
          ),
          for (final run in parsed.runs)
            if (run.kind == KjvMarkupKind.text)
              TextSpan(text: run.value, style: bodyStyle)
            else if (run.kind == KjvMarkupKind.supplied)
              TextSpan(
                text: run.value,
                style: bodyStyle.copyWith(fontStyle: FontStyle.italic),
              )
            else
              WidgetSpan(
                alignment: PlaceholderAlignment.top,
                child: _NoteMark(
                  label: _markFor(noteIndex++),
                  note: run.value,
                ),
              ),
        ],
      ),
    );
  }
}

String _markFor(int index) {
  if (index >= 0 && index < _kSuperscripts.length) {
    return _kSuperscripts[index];
  }
  return '[${index + 1}]';
}

class _NoteMark extends StatelessWidget {
  const _NoteMark({required this.label, required this.note});

  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNote(context, note),
      child: Padding(
        padding: const EdgeInsets.only(left: 1, right: 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: FhcColors.greenDark,
            height: 1,
          ),
        ),
      ),
    );
  }

  Future<void> _showNote(BuildContext context, String body) {
    final title = fhcT(
      context,
      'bible.translatorNote',
      fallback: 'Translator’s note',
    );
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: FhcColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: FhcColors.ink,
                  fontFamily: 'Georgia',
                  fontFamilyFallback: ['serif', 'Times New Roman'],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

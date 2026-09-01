import 'package:family_house_connect_mobile/features/community/data/bible_kjv_markup.dart';
import 'package:family_house_connect_mobile/features/community/presentation/widgets/bible_verse_rich_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supplied words become italic reading text without braces', () {
    final parsed = parseKjvMarkup(
      'These {are} the generations of the heavens and of the earth',
    );
    expect(parsed.reading, 'These are the generations of the heavens and of the earth');
    expect(parsed.notes, isEmpty);
    expect(
      parsed.runs.where((run) => run.kind == KjvMarkupKind.supplied).single.value,
      'are',
    );
  });

  test('colon braces are translator notes, not verse body', () {
    final parsed = parseKjvMarkup(
      'which God created and made. {created...: Heb. created to make}',
    );
    expect(parsed.reading, 'which God created and made. ');
    expect(parsed.notes, ['created...: Heb. created to make']);
  });

  test('mixed italics and Hebrew notes in one verse', () {
    final parsed = parseKjvMarkup(
      'And God saw the light, that {it was} good. '
      '{the light from...: Heb. between the light and between the darkness}',
    );
    expect(parsed.reading.contains('{'), isFalse);
    expect(parsed.reading, contains('it was'));
    expect(parsed.notes, hasLength(1));
    expect(parsed.notes.single, contains('Heb.'));
  });

  testWidgets('reader italicizes supplied words and hides note braces', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BibleVerseRichText(
            raw:
                'These {are} the generations. {created...: Heb. created to make}',
            verseNumber: 4,
            fontSize: 18,
          ),
        ),
      ),
    );
    expect(find.textContaining('{are}'), findsNothing);
    expect(find.textContaining('{created'), findsNothing);
    expect(find.textContaining('These '), findsWidgets);
    expect(find.text('¹'), findsOneWidget);

    await tester.tap(find.text('¹'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Heb. created to make'), findsOneWidget);
  });
}

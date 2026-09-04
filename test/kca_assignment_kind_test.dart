import 'package:family_house_connect_mobile/features/kca/presentation/kca_assignment_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('soul winning kinds parse and require media', () {
    expect(parseKcaAssignmentKind('soul_winning'), KcaAssignmentKind.soulWinning);
    expect(parseKcaAssignmentKind('soul-winning'), KcaAssignmentKind.soulWinning);
    expect(kcaAssignmentRequiresMedia(KcaAssignmentKind.soulWinning), isTrue);
    expect(kcaAssignmentRequiresMedia(KcaAssignmentKind.practical), isTrue);
    expect(kcaAssignmentRequiresMedia(KcaAssignmentKind.written), isTrue);
    expect(kcaAssignmentRequiresMedia(KcaAssignmentKind.standard), isFalse);
  });

  test('flattenKcaSoulTree walks nested children', () {
    final flat = flattenKcaSoulTree([
      {
        'id': 'a',
        'given_name': 'Ada',
        'children': [
          {'id': 'b', 'given_name': 'Chidi', 'children': const []},
        ],
      },
    ]);
    expect(flat.map((row) => row['id']), ['a', 'b']);
  });
}

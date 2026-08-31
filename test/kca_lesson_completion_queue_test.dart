import 'package:family_house_connect_mobile/features/kca/data/kca_lesson_completion_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueue is idempotent per lesson and remove clears it', () async {
    final queue = KcaLessonCompletionQueue();
    await queue.enqueue(
      lessonId: '01ARZ3NDEKTSV4RRFFQ69G5FAV',
      idempotencyKey: 'k1',
      unlockToken: 'a' * 64,
    );
    await queue.enqueue(
      lessonId: '01ARZ3NDEKTSV4RRFFQ69G5FAV',
      idempotencyKey: 'k2',
    );
    expect((await queue.load()).length, 1);
    await queue.remove('01ARZ3NDEKTSV4RRFFQ69G5FAV');
    expect(await queue.load(), isEmpty);
  });
}

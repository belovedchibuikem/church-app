import 'package:family_house_connect_mobile/features/mission/data/mission_soul_capture_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('soul capture queue is idempotent by key', () async {
    SharedPreferences.setMockInitialValues({});
    final queue = MissionSoulCaptureQueue();
    await queue.enqueue(
      crusadeId: '01ARZ3NDEKTSV4RRFFQ69G5FAV',
      idempotencyKey: 'capture-1',
      givenName: 'Ada',
      familyName: 'Mensah',
      consentAt: '2026-08-31T12:00:00Z',
    );
    await queue.enqueue(
      crusadeId: '01ARZ3NDEKTSV4RRFFQ69G5FAV',
      idempotencyKey: 'capture-1',
      givenName: 'Ada',
      familyName: 'Mensah',
    );
    expect((await queue.load()).length, 1);
    await queue.mark('capture-1', 'synced');
    expect((await queue.load()).single['status'], 'synced');
  });
}

import 'package:family_house_connect_mobile/core/launch/app_launch_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MemoryAppLaunchStore.setLanguage notifies listeners and updates languageCode',
      () async {
    final store = MemoryAppLaunchStore();
    var notified = 0;
    store.addListener(() => notified++);

    expect(store.languageCode, 'en');

    await store.setLanguage(languageCode: 'fr', languageLabel: 'Français');

    expect(store.languageCode, 'fr');
    expect(notified, 1);
  });
}

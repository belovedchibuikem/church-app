import 'package:family_house_connect_mobile/features/kca/data/kca_enrolment_draft_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveStep and loadStep round-trip field maps', () async {
    final store = KcaEnrolmentDraftStore();
    await store.saveStep(1, {
      'church_ministry': 'Garden House',
      'country': 'NG',
    });

    final loaded = await store.loadStep(1);
    expect(loaded['church_ministry'], 'Garden House');
    expect(loaded['country'], 'NG');
  });

  test('loadAll merges step fields and clear removes them', () async {
    final store = KcaEnrolmentDraftStore();
    await store.saveStep(1, {'church_ministry': 'A'});
    await store.saveStep(2, {'walk_more': 'Growing'});

    final all = await store.loadAll();
    expect(all['church_ministry'], 'A');
    expect(all['walk_more'], 'Growing');
    expect(all['step1_church_ministry'], 'A');

    await store.clear();
    expect(await store.loadStep(1), isEmpty);
    expect(await store.loadStep(2), isEmpty);
  });

  test('hydrateFromApplicationData accepts nested step maps', () async {
    final store = KcaEnrolmentDraftStore();
    await store.hydrateFromApplicationData({
      'step_1': {'church_ministry': 'Hydrated Church'},
      'step2_walk_more': 'From flat key',
    });

    expect((await store.loadStep(1))['church_ministry'], 'Hydrated Church');
    expect((await store.loadStep(2))['walk_more'], 'From flat key');
  });
}

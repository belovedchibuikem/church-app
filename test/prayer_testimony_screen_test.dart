import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/contracts/mobile_repository_contracts.dart';
import 'package:family_house_connect_mobile/core/design_system/fhc_tokens.dart';
import 'package:family_house_connect_mobile/features/community/presentation/screens/prayer_screen.dart';
import 'package:family_house_connect_mobile/features/community/presentation/screens/testimony_new_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakePrayerRepository implements PrayerRepository {
  @override
  Future<AppResult<List<JsonObject>>> listOwn() async => const AppSuccess([
    {
      'id': 'prayer-1',
      'subject': 'Pray for the church of God in Nigeria',
      'status': 'open',
      'created_at': '2026-09-02T00:00:00Z',
      'is_own': true,
    },
  ]);

  @override
  Future<AppResult<JsonObject>> create(JsonObject request) async {
    return const AppError(
      IntegrationUnavailableFailure('Prayer create is unbound in this test.'),
    );
  }
}

final class _FakeTestimonyRepository implements TestimonyRepository {
  _FakeTestimonyRepository({this.created});

  JsonObject? created;

  @override
  Future<AppResult<List<JsonObject>>> listOwn() async => const AppSuccess([
    {
      'id': 'testimony-1',
      'title': 'God healed my mother',
      'body': 'We prayed and she recovered.',
      'status': 'pending',
      'submitted_at': '2026-09-05T00:00:00Z',
    },
  ]);

  @override
  Future<AppResult<JsonObject>> create(JsonObject request) async {
    created = request;
    return AppSuccess({
      'id': 'testimony-2',
      'title': request['title'],
      'body': request['body'],
      'status': 'pending',
    });
  }
}

Widget _app(Widget home) {
  return MaterialApp(
    theme: buildFhcTheme(),
    home: home,
    routes: {
      '/prayer': (_) => const Scaffold(body: Text('Prayer Requests')),
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('prayer screen offers testimony capture on the same page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        PrayerScreen(
          prayerRepository: _FakePrayerRepository(),
          testimonyRepository: _FakeTestimonyRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Prayer Request'), findsOneWidget);
    expect(find.text('Share Testimony'), findsOneWidget);
    expect(find.text('Testimonies'), findsOneWidget);
    expect(find.text('Pray for the church of God in Nigeria'), findsOneWidget);

    await tester.tap(find.text('Testimonies'));
    await tester.pumpAndSettle();

    expect(find.text('God healed my mother'), findsOneWidget);
    expect(find.textContaining('pending'), findsOneWidget);
  });

  testWidgets('testimony form submits title and body', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeTestimonyRepository();
    await tester.pumpWidget(_app(TestimonyNewScreen(testimonyRepository: repo)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'He made a way');
    await tester.enterText(
      find.byType(TextField).at(1),
      'The rent was paid the same week we prayed.',
    );
    await tester.tap(find.text('Submit Testimony'));
    await tester.pump();

    expect(repo.created?['title'], 'He made a way');
    expect(
      repo.created?['body'],
      'The rent was paid the same week we prayed.',
    );
  });
}

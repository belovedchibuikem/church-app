import 'package:family_house_connect_mobile/app/app.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const screens = <(String, String)>[
  ('01_discover_churches', '/discover'),
  ('02_church_detail', '/church/detail'),
  ('03_live_service', '/fellowship/live'),
  ('04_give_donate', '/give'),
  ('05_sermons_library', '/sermons'),
  ('06_prayer_requests', '/prayer'),
  ('07_groups', '/groups'),
  ('08_events', '/events'),
  ('09_notifications', '/notifications'),
  ('10_profile', '/profile'),
  ('11_bible', '/bible'),
  ('12_giving_history', '/give/history'),
  ('13_settings', '/settings'),
];

void main() {
  setUpAll(() async {
    final roboto = FontLoader('FhcRoboto')
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('assets/fonts/materialicons-regular.otf'));
    await Future.wait([roboto.load(), materialIcons.load()]);
  });

  for (final screen in screens) {
    testWidgets('capture ${screen.$1} at 390x844', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        FamilyHouseConnectApp(
          initialRoute: screen.$2,
          authorizationGateway: const VisualReviewAuthorizationGateway(),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() async {
        for (final asset in const [
          'assets/images/discover_hero_globe.png',
          'assets/images/grace_home_church.png',
          'assets/images/church_building.png',
          'assets/images/live_pastor.png',
          'assets/images/prayer_avatar.png',
          'assets/images/member_avatar.png',
          'assets/images/profile_avatar.png',
          'assets/images/kca_avatar.png',
          'assets/images/member_photos/member_sarah_okafor.png',
          'assets/images/member_photos/member_john_david.png',
          'assets/images/member_photos/member_blessing_uche.png',
          'assets/images/sermon_faith_mountains.png',
          'assets/images/group_avatar_young_adults.png',
          'assets/images/group_avatar_women_of_grace.png',
          'assets/images/group_avatar_men_of_valor.png',
          'assets/images/group_avatar_bible_study.png',
          'assets/images/convention_2025.png',
          'assets/images/event_youth_summit.png',
          'assets/images/event_kca_training.png',
          'assets/images/event_prayer_conference.png',
          'assets/images/profile_chibuikem.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      final renderingException = tester.takeException();
      expect(
        renderingException,
        isNull,
        reason: '${screen.$1} overflowed or failed to render',
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../artifacts/screenshots/community/${screen.$1}.png',
        ),
      );
    });
  }
}

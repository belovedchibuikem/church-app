import 'package:family_house_connect_mobile/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const screens = <(String, String)>[
  ('01_splash', '/splash'),
  ('02_onboarding_discover', '/onboarding/discover'),
  ('03_onboarding_connect', '/onboarding/connect'),
  ('04_onboarding_multiply', '/onboarding/multiply'),
  ('05_language_location', '/language'),
  ('06_sign_in', '/sign-in'),
  ('07_verify_phone', '/verify-phone'),
  ('08_two_factor', '/2fa'),
  ('09_role_selection', '/role-selection'),
  ('10_module_hub', '/hub'),
  ('11_church_dashboard', '/church'),
  ('12_kca_dashboard', '/kca'),
  ('13_mission_dashboard', '/mission'),
];

void main() {
  setUpAll(() async {
    final roboto = FontLoader('FhcRoboto')
      ..addFont(rootBundle.load('assets/fonts/roboto-bold.ttf'));
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('assets/fonts/materialicons-regular.otf'));
    await Future.wait([roboto.load(), materialIcons.load()]);
  });

  for (final screen in screens) {
    testWidgets('capture ${screen.$1} at 390x844', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(FamilyHouseConnectApp(initialRoute: screen.$2));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() async {
        for (final asset in const [
          'assets/images/splash_map.png',
          'assets/images/discover_globe.png',
          'assets/images/connect_people.png',
          'assets/images/multiply_home.png',
          'assets/images/otp_security.png',
          'assets/images/security_shield.png',
          'assets/images/member_avatar.png',
          'assets/images/church_live.png',
          'assets/images/lesson_book.png',
          'assets/images/kca_lesson_book.png',
          'assets/images/mission_lagos_thumb.png',
          'assets/images/mission_banner.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pump();
      final renderingException = tester.takeException();
      expect(
        renderingException,
        isNull,
        reason: '${screen.$1} overflowed or failed to render',
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../artifacts/screenshots/${screen.$1}.png'),
      );
    });
  }
}

import 'package:family_house_connect_mobile/app/app.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:family_house_connect_mobile/core/launch/app_launch_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSignUp(WidgetTester tester, {required String languageCode}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      FamilyHouseConnectApp(
        initialRoute: '/sign-up',
        launchStore: MemoryAppLaunchStore(
          onboardingCompleted: true,
          setupCompleted: true,
          languageCode: languageCode,
        ),
        authorizationGateway: const VisualReviewAuthorizationGateway(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sign-up form renders TextFields for Yoruba locale', (tester) async {
    await pumpSignUp(tester, languageCode: 'yo');
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('sign-up form renders TextFields for Igbo locale', (tester) async {
    await pumpSignUp(tester, languageCode: 'ig');
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('sign-up form renders TextFields for Hausa locale', (tester) async {
    await pumpSignUp(tester, languageCode: 'ha');
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('sign-up form renders TextFields for Swahili locale', (tester) async {
    await pumpSignUp(tester, languageCode: 'sw');
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsWidgets);
  });
}

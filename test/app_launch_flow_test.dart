import 'package:family_house_connect_mobile/app/app.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:family_house_connect_mobile/core/launch/app_launch_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(
    WidgetTester tester, {
    AppLaunchStore? launchStore,
    String initialRoute = '/splash',
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      FamilyHouseConnectApp(
        initialRoute: initialRoute,
        launchStore: launchStore,
        authorizationGateway: const VisualReviewAuthorizationGateway(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('first launch splash continues into discover onboarding', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('DISCOVER'), findsOneWidget);
    expect(find.text('FAMILY HOUSE'), findsNothing);
  });

  testWidgets('completed onboarding never returns to intro slides', (
    tester,
  ) async {
    await pumpApp(
      tester,
      launchStore: MemoryAppLaunchStore(
        onboardingCompleted: true,
        setupCompleted: false,
      ),
    );
    expect(find.text('DISCOVER'), findsNothing);
    expect(find.text('Language & Location'), findsOneWidget);
  });

  testWidgets('returning visitor with setup complete lands on sign-in', (
    tester,
  ) async {
    await pumpApp(
      tester,
      launchStore: MemoryAppLaunchStore(
        onboardingCompleted: true,
        setupCompleted: true,
      ),
    );
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('DISCOVER'), findsNothing);
  });

  testWidgets('skipping onboarding persists and continues to setup', (
    tester,
  ) async {
    final store = MemoryAppLaunchStore();
    await pumpApp(tester, launchStore: store);
    expect(store.onboardingCompleted, isFalse);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(store.onboardingCompleted, isTrue);
    expect(find.text('Language & Location'), findsOneWidget);
  });

  testWidgets('choosing French rebuilds chrome from the message catalog', (
    tester,
  ) async {
    final store = MemoryAppLaunchStore(
      onboardingCompleted: true,
      setupCompleted: false,
    );
    await pumpApp(tester, launchStore: store);
    expect(find.text('Language & Location'), findsOneWidget);
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(store.languageCode, 'fr');
    expect(find.text('Langue et localisation'), findsOneWidget);
    expect(find.text('Language & Location'), findsNothing);
  });
}

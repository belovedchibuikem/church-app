import 'package:family_house_connect_mobile/app/app.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpRoute(
    WidgetTester tester,
    String route, {
    AuthorizationGateway authorizationGateway =
        const VisualReviewAuthorizationGateway(),
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      FamilyHouseConnectApp(
        initialRoute: route,
        authorizationGateway: authorizationGateway,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('canonical auth alias resolves to the existing login screen', (
    tester,
  ) async {
    await pumpRoute(tester, '/auth/login');
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('parameterized event registration deep link resolves', (
    tester,
  ) async {
    await pumpRoute(tester, '/events/kingdom-impact/register');
    expect(find.text('Event Registration'), findsOneWidget);
  });

  testWidgets('parameterized payment receipt deep link remains guarded', (
    tester,
  ) async {
    await pumpRoute(
      tester,
      '/payments/PAY-123/receipt',
      authorizationGateway: const UnconfiguredAuthorizationGateway(),
    );
    expect(find.text('Restricted access'), findsOneWidget);
  });

  testWidgets('unknown and expired deep links show content unavailable', (
    tester,
  ) async {
    await pumpRoute(tester, '/expired/resource/does-not-exist');
    expect(find.text('We couldn’t open this content'), findsOneWidget);
  });

  testWidgets('production fallback fails closed on protected destinations', (
    tester,
  ) async {
    await pumpRoute(
      tester,
      '/settings/privacy',
      authorizationGateway: const UnconfiguredAuthorizationGateway(),
    );
    expect(find.text('Restricted access'), findsOneWidget);
    expect(
      find.textContaining('Laravel authorization service'),
      findsOneWidget,
    );
  });
}

import 'package:family_house_connect_mobile/app/app.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _DeniedGateway implements AuthorizationGateway {
  String? lastPermission;

  @override
  Future<AuthorizationDecision> authorize({
    required String permission,
    String? resourceId,
    String? organizationScope,
  }) async {
    lastPermission = permission;
    return const AuthorizationDecision(
      AuthorizationState.forbidden,
      reason: 'Laravel denied this scoped operation.',
    );
  }

  @override
  Future<void> bindSession({
    required String accessToken,
    required String deviceIdentifier,
  }) async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> prefetchCapabilities() async {}
}

void main() {
  testWidgets('splash proceeds to discover onboarding', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const FamilyHouseConnectApp(
        initialRoute: '/splash',
        authorizationGateway: VisualReviewAuthorizationGateway(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DISCOVER'), findsOneWidget);
  });

  testWidgets('module hub exposes all four native module tiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const FamilyHouseConnectApp(
        initialRoute: '/hub',
        authorizationGateway: VisualReviewAuthorizationGateway(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('CHURCH'), findsOneWidget);
    expect(find.text('MISSION'), findsOneWidget);
    expect(find.text('KCA'), findsOneWidget);
    expect(find.text('PRESS'), findsOneWidget);
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
  });

  testWidgets('protected dashboard renders backend denial state', (
    tester,
  ) async {
    await tester.pumpWidget(
      FamilyHouseConnectApp(
        initialRoute: '/church',
        authorizationGateway: _DeniedGateway(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Access denied'), findsOneWidget);
    expect(find.text('Laravel denied this scoped operation.'), findsOneWidget);
  });

  testWidgets('giving history requires the scoped Laravel permission', (
    tester,
  ) async {
    final gateway = _DeniedGateway();
    await tester.pumpWidget(
      FamilyHouseConnectApp(
        initialRoute: '/give/history',
        authorizationGateway: gateway,
      ),
    );
    await tester.pumpAndSettle();
    expect(gateway.lastPermission, 'giving.history.view');
    expect(find.text('Access denied'), findsOneWidget);
  });
}

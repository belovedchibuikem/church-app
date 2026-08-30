import 'package:family_house_connect_mobile/app/app.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _RecordingDeniedGateway implements AuthorizationGateway {
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
  Future<void> pumpRoute(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      FamilyHouseConnectApp(
        initialRoute: route,
        authorizationGateway: const VisualReviewAuthorizationGateway(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAction(WidgetTester tester, String label) async {
    final action = find.text(label);
    expect(action, findsWidgets);
    final buttonLabel = action.last;
    await tester.ensureVisible(buttonLabel);
    await tester.tap(buttonLabel);
    await tester.pumpAndSettle();
  }

  testWidgets('altar-call decision continues to confirmation', (tester) async {
    await pumpRoute(tester, '/altar-call');
    await tapAction(tester, 'Continue');
    expect(find.text('Thank you for your decision!'), findsOneWidget);
  });

  testWidgets('need submission continues to owned request status', (
    tester,
  ) async {
    await pumpRoute(tester, '/needs/request');
    await tapAction(tester, 'Submit Need');
    expect(find.text('My Needs'), findsOneWidget);
  });

  testWidgets('event registration requires an event id from catalogue', (
    tester,
  ) async {
    await pumpRoute(tester, '/events/register');
    expect(find.text('Registration unavailable'), findsOneWidget);
    expect(find.textContaining('public event id'), findsOneWidget);
  });

  testWidgets('event tickets surface unavailable without ticket API', (
    tester,
  ) async {
    await pumpRoute(tester, '/events/tickets');
    expect(find.text('Tickets unavailable'), findsOneWidget);
  });

  testWidgets('mission partner support opens the mission support form', (
    tester,
  ) async {
    await pumpRoute(tester, '/mission/partner');
    await tapAction(tester, 'Support Mission');
    expect(find.text('Your Support'), findsOneWidget);
  });

  testWidgets('KCA evidence upload opens the review-status list', (
    tester,
  ) async {
    await pumpRoute(tester, '/kca/evidence');
    await tapAction(tester, 'Upload Evidence');
    expect(find.text('Under Review (2)'), findsOneWidget);
  });

  testWidgets('sensitive expansion routes request scoped authorization', (
    tester,
  ) async {
    final cases = <String, String>{
      '/home-church/finance': 'home_church.finance.view',
      '/altar-call/follow-ups': 'altar_call.followup.view',
      '/kca/evidence': 'kca.evidence.create',
      '/kca/review': 'kca.evidence.review',
      '/mission/souls/add': 'mission.souls.create',
      '/wallet': 'wallet.view',
    };

    for (final entry in cases.entries) {
      final gateway = _RecordingDeniedGateway();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        FamilyHouseConnectApp(
          initialRoute: entry.key,
          authorizationGateway: gateway,
        ),
      );
      await tester.pumpAndSettle();
      expect(gateway.lastPermission, entry.value, reason: entry.key);
      expect(find.text('Access denied'), findsOneWidget);
    }
  });
}

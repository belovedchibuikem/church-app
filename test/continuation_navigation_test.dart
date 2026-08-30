import 'package:family_house_connect_mobile/app/app.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _DeniedContinuationGateway implements AuthorizationGateway {
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

  Future<void> tapLast(WidgetTester tester, String label) async {
    final finder = find.text(label);
    expect(finder, findsWidgets);
    await tester.ensureVisible(finder.last);
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  testWidgets('payment success opens the canonical receipt', (tester) async {
    await pumpRoute(tester, '/payments/success');
    await tapLast(tester, 'View Receipt');
    expect(find.text('Receipt Information'), findsOneWidget);
  });

  testWidgets('KCA enrollment advances through the canonical steps', (
    tester,
  ) async {
    await pumpRoute(tester, '/kca/enrollment/1');
    expect(find.text('Church Information'), findsOneWidget);
    await tapLast(tester, 'Next');
    expect(find.text('Walk with Christ'), findsOneWidget);
  });

  testWidgets('Kingdom Journey advances from overview to discovery', (
    tester,
  ) async {
    await pumpRoute(tester, '/journey');
    await tapLast(tester, 'Continue Journey');
    expect(find.text('Discover Family House'), findsWidgets);
  });

  testWidgets('membership registration connects to first-timer registration', (
    tester,
  ) async {
    await pumpRoute(tester, '/membership/register');
    await tapLast(tester, 'Continue');
    expect(find.text('Welcome to Family House Connect!'), findsOneWidget);
  });

  testWidgets('leadership scope continues to its scoped dashboard', (
    tester,
  ) async {
    await pumpRoute(tester, '/leadership/scope');
    await tapLast(tester, 'Continue');
    expect(find.text('Scope-Aware Leadership Dashboard'), findsOneWidget);
  });

  testWidgets('pending sync waits for authoritative server confirmation', (
    tester,
  ) async {
    await pumpRoute(tester, '/sync/pending');
    await tapLast(tester, 'Sync Now');
    expect(find.text('Sync Pending'), findsWidgets);
    expect(find.text('All synced!'), findsNothing);
    expect(
      find.text(
        'Sync requested. Waiting for authoritative server confirmation.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('failed uploads retry through resumable upload progress', (
    tester,
  ) async {
    await pumpRoute(tester, '/uploads/failed');
    await tapLast(tester, 'Retry All');
    expect(find.text('Resumable uploads are ON'), findsOneWidget);
  });

  testWidgets('active evidence upload can be paused and resumed', (
    tester,
  ) async {
    await pumpRoute(tester, '/uploads/progress');
    await tester.tap(find.byTooltip('Pause upload'));
    await tester.pump();
    expect(find.byTooltip('Resume upload'), findsOneWidget);
  });

  testWidgets('local storage and bandwidth actions acknowledge completion', (
    tester,
  ) async {
    await pumpRoute(tester, '/downloads/storage');
    await tapLast(tester, 'Clear Cache (120 MB)');
    expect(
      find.text('120 MB of cached temporary files cleared.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpRoute(tester, '/settings/low-bandwidth');
    await tapLast(tester, 'Save Settings');
    expect(
      find.text('Low-bandwidth preferences saved on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('new sensitive routes request server-scoped permissions', (
    tester,
  ) async {
    final cases = <String, String>{
      '/payments/receipt': 'payments.receipts.view_own',
      '/settings/privacy': 'privacy.manage_own',
      '/guardian/child': 'guardian.child.view',
      '/safeguarding/report': 'safeguarding.reports.create',
      '/pastoral/record': 'pastoral.records.view',
      '/kca/admin-review': 'kca.reviews.manage',
      '/leadership/approvals': 'leadership.approvals.view',
      '/ai/pastoral-reports': 'ai.pastoral.reports',
      '/sync/pending': 'sync.queue.view_own',
      '/sync/success': 'sync.queue.view_own',
      '/uploads/progress': 'uploads.view_own',
      '/uploads/failed': 'uploads.retry_own',
      '/downloads/storage': 'downloads.manage_own',
    };

    for (final entry in cases.entries) {
      final gateway = _DeniedContinuationGateway();
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

import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:family_house_connect_mobile/core/contracts/mobile_repository_contracts.dart';
import 'package:family_house_connect_mobile/core/design_system/fhc_tokens.dart';
import 'package:family_house_connect_mobile/core/di/app_services.dart';
import 'package:family_house_connect_mobile/core/di/app_services_scope.dart';
import 'package:family_house_connect_mobile/features/church/presentation/screens/church_admin_dashboard_screen.dart';
import 'package:family_house_connect_mobile/features/dashboards/presentation/screens/church_dashboard_screen.dart';
import 'package:family_house_connect_mobile/features/dashboards/presentation/screens/mission_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.dashboard);

  final JsonObject dashboard;

  @override
  Future<AppResult<JsonObject>> getProfile() async => AppSuccess(dashboard);

  @override
  Future<AppResult<JsonObject>> updateProfile(JsonObject changes) async {
    return const AppError(
      IntegrationUnavailableFailure('Profile updates are unbound in this test.'),
    );
  }

  @override
  Future<AppResult<JsonObject>> getDashboard() async => AppSuccess(dashboard);
}

final class _FakeMissionRepository implements MissionRepository {
  _FakeMissionRepository(this.crusades);

  final List<JsonObject> crusades;

  @override
  Future<AppResult<List<JsonObject>>> getCrusades(JsonObject filters) async =>
      AppSuccess(crusades);

  @override
  Future<AppResult<JsonObject>> getSoul(String id) async {
    return const AppError(
      IntegrationUnavailableFailure('Soul detail is unbound in this test.'),
    );
  }

  @override
  Future<AppResult<JsonObject>> createSoul(JsonObject soul) async {
    return const AppError(
      IntegrationUnavailableFailure('Soul capture is unbound in this test.'),
    );
  }

  @override
  Future<AppResult<void>> assignMentor(String soulId, String mentorId) async {
    return const AppError(
      IntegrationUnavailableFailure('Mentor assignment is unbound in this test.'),
    );
  }

  @override
  Future<AppResult<JsonObject>> recordFollowUp(
    String soulId,
    JsonObject body,
  ) async {
    return const AppError(
      IntegrationUnavailableFailure('Follow-up record is unbound in this test.'),
    );
  }

  @override
  Future<AppResult<JsonObject>> completeFollowUp(
    String soulId, [
    JsonObject body = const {},
  ]) async {
    return const AppError(
      IntegrationUnavailableFailure(
        'Follow-up completion is unbound in this test.',
      ),
    );
  }
}

Widget _app(Widget home) {
  return MaterialApp(theme: buildFhcTheme(), home: home);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dashboardPayload = <String, Object?>{
    'profile': {
      'profile': {
        'preferred_name': 'Ada',
        'given_name': 'Ada',
        'family_name': 'Okeke',
      },
    },
    'unread_notification_count': 4,
    'open_prayer_count': 2,
    'upcoming_note': null,
    'recent_payment_intents': <JsonObject>[],
  };

  testWidgets('church dashboard binds /user/dashboard and hides fake totals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        ChurchDashboardScreen(
          profileRepository: _FakeProfileRepository(dashboardPayload),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1,248'), findsNothing);
    expect(find.text('First Timers'), findsNothing);
    expect(find.text('May 20, 2025 • 6:00 PM'), findsNothing);
    expect(find.text('Open prayers'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Prayer'), findsOneWidget);
    expect(find.text('Messages'), findsWidgets);
    expect(find.textContaining('Ada'), findsOneWidget);
  });

  testWidgets('church dashboard is unavailable without a repository', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const ChurchDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Church dashboard unavailable'), findsOneWidget);
    expect(find.text('1,248'), findsNothing);
  });

  testWidgets('mission dashboard counts live crusades and omits unbound cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        MissionDashboardScreen(
          missionRepository: _FakeMissionRepository(const [
            {
              'id': '01JCRUSADE0000000000000001',
              'name': 'Jos Outreach',
              'starts_at': '2026-09-01T00:00:00Z',
              'ends_at': '2026-09-03T00:00:00Z',
            },
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active Crusades'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Jos Outreach'), findsWidgets);
    expect(find.text('Follow-ups'), findsNothing);
    expect(find.text('12'), findsNothing);
    expect(find.text('254'), findsNothing);
    expect(find.text('1,250 Souls'), findsNothing);
  });

  testWidgets('church admin dashboard renders sparse /user/dashboard fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        ChurchAdminDashboardScreen(
          profileRepository: _FakeProfileRepository(dashboardPayload),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1,248'), findsNothing);
    expect(find.text('₦2,450,000'), findsNothing);
    expect(find.text('12 Active'), findsNothing);
    expect(find.text('Unread notifications'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('Open prayers'), findsOneWidget);
    expect(find.text('Messages'), findsWidgets);
  });

  testWidgets('church dashboard still shows fixtures when explicitly allowed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppServicesScope(
        services: AppServices.bootstrap(
          showUnboundFixtures: true,
          authorizationGateway: const VisualReviewAuthorizationGateway(),
        ),
        child: _app(const ChurchDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1,248'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Join Live Service'), findsOneWidget);
  });
}

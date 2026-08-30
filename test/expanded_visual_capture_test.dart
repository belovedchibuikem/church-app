import 'package:family_house_connect_mobile/app/app.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const expandedScreens = <(String, String)>[
  ('01_church_reports', '/church/reports'),
  ('02_first_timers', '/church/first-timers'),
  ('03_home_church_members', '/home-church/members'),
  ('04_home_church_attendance', '/home-church/attendance'),
  ('05_home_church_activities', '/home-church/activities'),
  ('06_home_church_finance', '/home-church/finance'),
  ('07_monthly_report', '/home-church/monthly-report'),
  ('08_share_need', '/home-church/share-need'),
  ('09_needs_management', '/home-church/needs'),
  ('10_online_church', '/online-church'),
  ('11_altar_call', '/altar-call'),
  ('12_altar_call_submitted', '/altar-call/submitted'),
  ('13_altar_call_followups', '/altar-call/follow-ups'),
  ('14_counseling_request', '/counseling/request'),
  ('15_need_request', '/needs/request'),
  ('16_need_status', '/needs/status'),
  ('17_testimony_submission', '/testimony/new'),
  ('18_leadership_dashboard', '/leadership'),
  ('19_wallet', '/wallet'),
  ('20_event_registration', '/events/register'),
  ('21_event_payment', '/events/payment'),
  ('22_event_tickets', '/events/tickets'),
  ('23_event_attendance', '/events/attendance'),
  ('24_event_feedback', '/events/feedback'),
  ('25_press_categories', '/press/categories'),
  ('26_press_resource', '/press/resource'),
  ('27_press_audio', '/press/audio'),
  ('28_downloads', '/downloads'),
  ('29_mission_partners', '/mission/partners'),
  ('30_mission_partner', '/mission/partner'),
  ('31_mission_support', '/mission/support'),
  ('32_mission_invite', '/mission/invite'),
  ('33_crusade_request_status', '/mission/request-status'),
  ('34_add_soul', '/mission/souls/add'),
  ('35_soul_profile', '/mission/souls/profile'),
  ('36_assign_mentor', '/mission/mentor-assignment'),
  ('37_mission_teams', '/mission/teams'),
  ('38_mission_support_request', '/mission/support-request'),
  ('39_mission_assignments', '/mission/assignments'),
  ('40_kca_evidence', '/kca/evidence'),
  ('41_kca_submissions', '/kca/submissions'),
  ('42_kca_certification', '/kca/certification'),
  ('43_kca_admission', '/kca/admission'),
  ('44_kca_attendance', '/kca/attendance'),
  ('45_kca_mentees', '/kca/mentees'),
  ('46_kca_review', '/kca/review'),
  ('47_kca_assessment', '/kca/assessment'),
  ('48_kca_certificate', '/kca/certificate'),
  ('49_kca_verify', '/kca/verify'),
  ('50_kca_alumni', '/kca/alumni'),
  ('51_alumni_dashboard', '/kca/alumni/dashboard'),
  ('52_kca_opportunities', '/kca/opportunities'),
];

void main() {
  setUpAll(() async {
    final roboto = FontLoader('FhcRoboto')
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('assets/fonts/materialicons-regular.otf'));
    await Future.wait([roboto.load(), materialIcons.load()]);
  });

  for (final screen in expandedScreens) {
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
          'assets/images/live_worship.png',
          'assets/images/prayer_hero.png',
          'assets/images/connect_people.png',
          'assets/images/prayer_answered_church.png',
          'assets/images/event_convention.png',
          'assets/images/book_walking_purpose.png',
          'assets/images/live_pastor.png',
          'assets/images/mission_banner.png',
          'assets/images/crusade_crowd.png',
          'assets/images/souls_avatar.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.$1} overflowed or failed to render',
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../artifacts/screenshots/expansion/${screen.$1}.png',
        ),
      );
    });
  }
}

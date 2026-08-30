import 'package:family_house_connect_mobile/app/app.dart';
import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const continuationScreens = <(String, String)>[
  ('001_receipt_detail', '/payments/receipt'),
  ('002_share_receipt', '/payments/receipt/share'),
  ('003_payment_history', '/payments/history'),
  ('004_transaction_detail', '/payments/transaction'),
  ('005_payment_pending', '/payments/pending'),
  ('006_refund_status', '/payments/refund'),
  ('007_dispute_status', '/payments/dispute'),
  ('008_recurring_giving', '/giving/recurring'),
  ('009_notification_preferences', '/settings/notifications'),
  ('010_communication_preferences', '/settings/communications'),
  ('011_active_sessions', '/settings/sessions'),
  ('012_privacy_controls', '/settings/privacy'),
  ('013_consent_management', '/settings/consents'),
  ('014_data_export', '/settings/data-export'),
  ('015_account_deletion', '/settings/delete-account'),
  ('016_child_profile', '/guardian/child'),
  ('017_guardian_controls', '/guardian/controls'),
  ('018_guardian_consent', '/guardian/consent'),
  ('019_restricted_communication', '/guardian/restricted'),
  ('020_safeguarding_report', '/safeguarding/report'),
  ('021_pastoral_record', '/pastoral/record'),
  ('022_ai_hub', '/ai'),
  ('023_pastoral_ai', '/ai/pastoral'),
  ('024_payment_processing', '/payments/processing'),
  ('025_payment_success', '/payments/success'),
  ('026_payment_failed', '/payments/failed'),
  ('027_need_details', '/needs/detail'),
  ('028_record_attendance', '/church/attendance/record'),
  ('029_kca_enrollment_1', '/kca/enrollment/1'),
  ('030_kca_enrollment_2', '/kca/enrollment/2'),
  ('031_kca_enrollment_3', '/kca/enrollment/3'),
  ('032_kca_enrollment_4', '/kca/enrollment/4'),
  ('033_kca_enrollment_5', '/kca/enrollment/5'),
  ('034_kca_enrollment_6', '/kca/enrollment/6'),
  ('035_kca_enrollment_7', '/kca/enrollment/7'),
  ('036_kca_enrollment_8', '/kca/enrollment/8'),
  ('037_kca_application_review', '/kca/application-review'),
  ('038_kca_admission_letter', '/kca/admission-letter'),
  ('039_kca_orientation', '/kca/orientation'),
  ('040_kca_practical_service', '/kca/practical-service'),
  ('041_kca_written_assessments', '/kca/written-assessments'),
  ('042_kca_spiritual_assignment', '/kca/spiritual-assignment'),
  ('043_kca_self_review', '/kca/self-review'),
  ('044_kca_admin_review', '/kca/admin-review'),
  ('045_kca_locked_module', '/kca/locked-module'),
  ('046_kca_physical_assignment', '/kca/physical-assignment'),
  ('047_kca_mentor_dashboard', '/kca/mentor-dashboard'),
  ('048_kca_lecturer', '/kca/lecturer'),
  ('049_kca_intervention', '/kca/intervention'),
  ('050_kca_admission_decision', '/kca/admission-decision'),
  ('051_journey_overview', '/journey'),
  ('052_journey_discover', '/journey/discover'),
  ('053_journey_join_church', '/journey/join-church'),
  ('054_journey_member', '/journey/member'),
  ('055_journey_grow', '/journey/grow'),
  ('056_journey_serve', '/journey/serve'),
  ('057_journey_win_souls', '/journey/win-souls'),
  ('058_journey_become_kca', '/journey/become-kca'),
  ('059_journey_home_church', '/journey/home-church'),
  ('060_journey_multiply', '/journey/multiply'),
  ('061_membership_registration', '/membership/register'),
  ('062_first_timer_registration', '/first-timer/register'),
  ('063_first_timer_journey', '/first-timer/journey'),
  ('064_convert_profile', '/convert/profile'),
  ('065_disciple_progress', '/disciple/progress'),
  ('066_member_profile', '/member/profile'),
  ('067_ministry_role', '/ministry/role'),
  ('068_ministry_history', '/ministry/history'),
  ('069_evangelism_activity', '/evangelism/activity'),
  ('070_evangelism_report', '/evangelism/report'),
  ('071_connect_church', '/referrals/connect'),
  ('072_referral_tracking', '/referrals/tracking'),
  ('073_approvals_queue', '/leadership/approvals'),
  ('074_approval_detail', '/leadership/approval'),
  ('075_leadership_reports', '/leadership/reports'),
  ('076_leadership_alerts', '/leadership/alerts'),
  ('077_mission_ai', '/ai/mission'),
  ('078_kca_ai', '/ai/kca'),
  ('079_press_ai', '/ai/press'),
  ('080_pastoral_reports_ai', '/ai/pastoral-reports'),
  ('081_scope_selector', '/leadership/scope'),
  ('082_scope_dashboard', '/leadership/scope-dashboard'),
  ('083_global_map', '/map'),
  ('084_map_filter', '/map/filter'),
  ('085_mission_location', '/map/mission-location'),
  ('086_no_church_nearby', '/map/no-church'),
  ('087_global_expansion', '/global-expansion'),
  ('088_offline_mode', '/offline'),
  ('089_sync_pending', '/sync/pending'),
  ('090_sync_successful', '/sync/success'),
  ('091_upload_progress', '/uploads/progress'),
  ('092_upload_failed', '/uploads/failed'),
  ('093_downloads_storage', '/downloads/storage'),
  ('094_low_bandwidth', '/settings/low-bandwidth'),
  ('095_content_unavailable', '/content/unavailable'),
];

void main() {
  setUpAll(() async {
    final roboto = FontLoader('FhcRoboto')
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('assets/fonts/materialicons-regular.otf'));
    await Future.wait([roboto.load(), materialIcons.load()]);
  });

  for (final screen in continuationScreens) {
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
          'assets/images/church_building.png',
          'assets/images/connect_people.png',
          'assets/images/mission_banner.png',
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
          '../artifacts/screenshots/continuation/${screen.$1}.png',
        ),
      );
    });
  }
}

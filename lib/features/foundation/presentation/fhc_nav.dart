import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class FhcRoutes {
  static const splash = '/splash';
  static const hub = '/hub';
  static const modules = '/modules';
  static const discover = '/discover';
  static const messages = '/messages';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const settings = '/settings';
  static const help = '/settings/help';
  static const notifications = '/notifications';

  static const churches = '/churches';
  static const church = '/church';
  static const churchHome = '/church/home';
  static const myChurch = '/church/mine';
  static const churchAdmin = '/church/admin';
  static const churchDetail = '/church/detail';
  static const churchMembers = '/church/members';
  static const churchGroups = '/church/groups';
  static const churchAnnouncements = '/church/announcements';
  static const churchMinistries = '/church/ministries';
  static const churchDocuments = '/church/documents';
  static const churchSettings = '/church/settings';
  static const churchReports = '/church/reports';
  static const firstTimers = '/church/first-timers';
  static const churchAttendance = '/church/attendance';
  static const churchActivities = '/church/activities';
  static const churchFinance = '/church/finance';
  static const leadership = '/leadership';
  static const homeChurch = '/home-church';
  static const homeChurchStart = '/home-church/start';
  static const homeChurchStart2 = '/home-church/start/2';
  static const homeChurchStart3 = '/home-church/start/3';
  static const homeChurchStart4 = '/home-church/start/4';
  static const homeChurchApplications = '/home-church/applications';
  static const homeChurchProgress = '/home-church/progress';
  static const homeChurchMembers = '/home-church/members';
  static const homeChurchAttendance = '/home-church/attendance';
  static const homeChurchActivities = '/home-church/activities';
  static const homeChurchFinance = '/home-church/finance';
  static const homeChurchReports = '/home-church/reports';
  static const homeChurchMonthlyReport = '/home-church/monthly-report';
  static const homeChurchShareNeed = '/home-church/share-need';
  static const homeChurchNeeds = '/home-church/needs';
  static const onlineChurch = '/online-church';
  static const altarCall = '/altar-call';
  static const altarCallSubmitted = '/altar-call/submitted';
  static const altarCallFollowups = '/altar-call/follow-ups';
  static const counselingRequest = '/counseling/request';
  static const needRequest = '/needs/request';
  static const needStatus = '/needs/status';
  static const needDetail = '/needs/detail';
  static const testimonyNew = '/testimony/new';

  static const mission = '/mission';
  static const crusade = '/mission/crusade';
  static const souls = '/mission/souls';
  static const missionInvite = '/mission/invite';
  static const missionRequestStatus = '/mission/request-status';
  static const soulAdd = '/mission/souls/add';
  static const soulProfile = '/mission/souls/profile';
  static const mentorAssignment = '/mission/mentor-assignment';
  static const missionTeams = '/mission/teams';
  static const missionSupportRequest = '/mission/support-request';
  static const missionAssignments = '/mission/assignments';
  static const missionPartners = '/mission/partners';
  static const missionPartner = '/mission/partner';
  static const missionSupport = '/mission/support';

  static const kca = '/kca';
  static const kcaGate = '/kca/gate';
  static const kcaEnroll = '/kca/enroll';
  static const kcaModules = '/kca/modules';
  static const kcaModule = '/kca/module';
  static const kcaLesson = '/kca/lesson';
  static const kcaAssignments = '/kca/assignments';
  static const kcaMentor = '/kca/mentor';
  static const kcaEvidence = '/kca/evidence';
  static const kcaSubmissions = '/kca/submissions';
  static const kcaCertification = '/kca/certification';
  static const kcaAdmission = '/kca/admission';
  static const kcaAdmissionLetter = '/kca/admission-letter';
  static const kcaOrientation = '/kca/orientation';
  static const kcaOrientationStage = '/kca/orientation/stage';
  static const kcaOrientationOverview = '/kca/orientation/overview';
  static const kcaOrientationRules = '/kca/orientation/rules';
  static const kcaOrientationPath = '/kca/orientation/path';
  static const kcaOrientationMentors = '/kca/orientation/mentors';
  static const kcaPracticalService = '/kca/practical-service';
  static const kcaAttendance = '/kca/attendance';
  static const kcaMentees = '/kca/mentees';
  static const kcaReview = '/kca/review';
  static const kcaAssessment = '/kca/assessment';
  static const kcaCertificate = '/kca/certificate';
  static const kcaVerify = '/kca/verify';
  static const kcaAlumni = '/kca/alumni';
  static const kcaAlumniDashboard = '/kca/alumni/dashboard';
  static const kcaOpportunities = '/kca/opportunities';

  static const press = '/press';
  static const pressDevotionals = '/press/devotionals';
  static const pressAdmin = '/press/admin';
  static const pressBook = '/press/book';
  static const pressCategories = '/press/categories';
  static const pressResource = '/press/resource';
  static const pressAudio = '/press/audio';
  static const downloads = '/downloads';

  static const events = '/events';
  static const eventDetail = '/events/detail';
  static const eventRegister = '/events/register';
  static const eventPayment = '/events/payment';
  static const eventTickets = '/events/tickets';
  static const eventAttendance = '/events/attendance';
  static const eventFeedback = '/events/feedback';
  static const prayer = '/prayer';
  static const prayerNew = '/prayer/new';
  static const give = '/give';
  static const giveHistory = '/give/history';
  static const wallet = '/wallet';
  static const live = '/fellowship/live';
  static const sermons = '/sermons';
  static const groups = '/groups';
  static const bible = '/bible';
  static const biblePlans = '/bible/plans';
  static const bibleRead = '/bible/read';
  static const media = '/media';

  /// Primary member shell: Home · Modules · Give · Events · Profile.
  static const tabs = <String>[hub, modules, give, events, profile];
}

void fhcGo(BuildContext context, String route) =>
    Navigator.of(context).pushReplacementNamed(route);

void fhcPush(BuildContext context, String route) =>
    Navigator.of(context).pushNamed(route);

/// Clears the navigator stack so first-run screens cannot be popped back to.
void fhcReset(BuildContext context, String route) {
  Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
}

Future<void> fhcApiUnavailable(
  BuildContext context, {
  required String action,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  showDragHandle: true,
  builder:
      (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Integration required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              '$action is ready for its repository contract, but the platform operation is not available in this build. No success state has been created.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
);

void fhcTab(BuildContext context, int index) {
  if (index < 0 || index >= FhcRoutes.tabs.length) return;
  fhcGo(context, FhcRoutes.tabs[index]);
}

/// Copies [text] so the member can share it from any app.
Future<void> fhcShareText(
  BuildContext context, {
  required String text,
  String? confirmation,
}) async {
  final payload = text.trim();
  if (payload.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: payload));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        confirmation ??
            'Copied. Paste it into Messages, WhatsApp, or email to share.',
      ),
    ),
  );
}

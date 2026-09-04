import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/auth/authorization.dart';
import '../core/design_system/fhc_tokens.dart';
import '../core/di/app_services.dart';
import '../core/di/app_services_scope.dart';
import '../core/l10n/locale_scope.dart';
import '../core/l10n/supported_locales.dart';
import '../core/launch/app_launch_scope.dart';
import '../core/launch/app_launch_store.dart';
import '../core/offline/offline_banner.dart';
import '../core/routing/fhc_route_args.dart';
import '../features/account/presentation/account_screens.dart';
import '../features/church/presentation/church_screens.dart';
import '../features/community/presentation/community_screens.dart';
import '../features/dashboards/presentation/dashboard_screens.dart';
import '../features/foundation/presentation/foundation_screens.dart';
import '../features/kca/presentation/kca_screens.dart';
import '../features/mission/presentation/mission_screens.dart';
import '../features/press/presentation/press_screens.dart';
import '../shared/widgets/async_state.dart';
import '../shared/widgets/permission_guard.dart';

String _normalizeIncomingRoute(String requestedRoute) {
  final trimmed = requestedRoute.trim();
  if (trimmed.startsWith('fhc://') ||
      trimmed.startsWith('familyhouseconnect://')) {
    final uri = Uri.parse(trimmed);
    final path = uri.path.isEmpty || uri.path == '/'
        ? '/${uri.host}'
        : '/${uri.host}${uri.path}';
    if (uri.query.isEmpty) return path;
    return '$path?${uri.query}';
  }
  return trimmed;
}

String? _churchIdFromRoute(String requestedRoute) {
  final pathOnly = requestedRoute.split('?').first;
  for (final prefix in const ['/discover/church/', '/church/detail/']) {
    if (!pathOnly.startsWith(prefix)) continue;
    final id = pathOnly.substring(prefix.length).split('/').first.trim();
    if (id.isNotEmpty) return id;
  }
  return null;
}

class FamilyHouseConnectApp extends StatefulWidget {
  const FamilyHouseConnectApp({
    super.key,
    this.initialRoute = '/splash',
    this.authorizationGateway,
    this.services,
    this.launchStore,
  });

  final String initialRoute;
  final AuthorizationGateway? authorizationGateway;
  final AppServices? services;
  final AppLaunchStore? launchStore;

  @override
  State<FamilyHouseConnectApp> createState() => _FamilyHouseConnectAppState();
}

class _FamilyHouseConnectAppState extends State<FamilyHouseConnectApp> {
  late final AppServices _services;
  late final AppLaunchStore _launchStore;
  late final AuthorizationGateway _authorizationGateway;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final gatewayArg = widget.authorizationGateway;
    _services =
        widget.services ??
        AppServices.bootstrap(
          authorizationGateway: gatewayArg,
          visualReview: gatewayArg is VisualReviewAuthorizationGateway,
        );
    _authorizationGateway = gatewayArg ?? _services.authorizationGateway;
    _launchStore =
        widget.launchStore ??
        MemoryAppLaunchStore(splashDuration: Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    final authorizationGateway = _authorizationGateway;
    final resolvedServices = _services;
    final resolvedLaunch = _launchStore;
    return ListenableBuilder(
      listenable: resolvedLaunch,
      builder: (context, _) {
        final localeCode = normalizeFhcLocale(resolvedLaunch.languageCode);
        final materialLocaleCode = materialLocaleCodeFor(localeCode);

        final app = MaterialApp(
      title: 'Family House Connect',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: buildFhcTheme(),
      locale: Locale(materialLocaleCode),
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return supported.first;
        for (final item in supported) {
          if (item.languageCode == locale.languageCode) return item;
        }
        return const Locale('en');
      },
      supportedLocales: [
        for (final code in kFhcFlutterMaterialLocales) Locale(code),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: widget.initialRoute,
      builder: (context, child) {
        return OfflineBannerHost(
          enabled: !resolvedServices.visualReview,
          navigatorKey: _navigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
      onGenerateRoute: (settings) {
        final requestedRoute = _normalizeIncomingRoute(settings.name ?? '/splash');
        final resolved = resolveCanonicalRoute(requestedRoute);
        final route = resolved.canonical;
        final incomingArgs = FhcRouteArgs.from(settings.arguments);
        final routeQuery = Uri.splitQueryString(
          requestedRoute.contains('?')
              ? requestedRoute.substring(requestedRoute.indexOf('?') + 1)
              : '',
        );
        final queryEntityId =
            (routeQuery['id'] ?? routeQuery['intent'])?.trim();
        final routeArgs = FhcRouteArgs(
          entityId: resolved.entityId ??
              incomingArgs?.entityId ??
              (queryEntityId != null && queryEntityId.isNotEmpty
                  ? queryEntityId
                  : null) ??
              (settings.arguments is String
                  ? settings.arguments as String
                  : null),
          secondaryId: resolved.secondaryId ?? incomingArgs?.secondaryId,
          extra: settings.arguments,
        );
        // Permission vocabulary: Flutter keys are client aliases. Laravel
        // `MobilePermissionAliasCatalog` maps known aliases to canonical codes;
        // unlisted keys fall through to `mobile.app.access`. See KNOWN_GAPS
        // KG-008. Align only clearly wrong keys (e.g. needs.create → needs.manage).
        Widget guarded(String permission, Widget child) => PermissionGuard(
          gateway: authorizationGateway,
          permission: permission,
          resourceId: routeArgs.entityId,
          child: child,
        );
        Widget paymentSurface(Widget child) =>
            resolvedServices.hideUnboundPayments
                ? const FhcFeatureUnavailablePage(feature: 'Payments')
                : child;
        Widget prayerSurface(Widget child) =>
            resolvedServices.hideUnboundPrayer
                ? const FhcFeatureUnavailablePage(feature: 'Prayer')
                : child;
        Widget messagingSurface(Widget child) =>
            resolvedServices.hideUnboundMessaging
                ? const FhcFeatureUnavailablePage(feature: 'Messaging')
                : child;
        Widget needsSurface(Widget child) =>
            resolvedServices.hideUnboundNeeds
                ? const FhcFeatureUnavailablePage(feature: 'Needs')
                : child;
        Widget churchFixtureSurface(String feature, Widget child) =>
            resolvedServices.hideUnboundChurchFixtures
                ? FhcFeatureUnavailablePage(feature: feature)
                : child;
        final page = switch (route) {
          '/splash' => const SplashScreen(),
          '/onboarding/discover' => const OnboardingPager(initialPage: 0),
          '/onboarding/connect' => const OnboardingPager(initialPage: 1),
          '/onboarding/multiply' => const OnboardingPager(initialPage: 2),
          '/language' => const LanguageLocationScreen(),
          '/sign-in' => const SignInScreen(),
          '/sign-up' => const SignUpScreen(),
          '/forgot-password' => const ForgotPasswordScreen(),
          '/reset-password' => ResetPasswordScreen(
            initialEmail: routeQuery['email'],
            initialToken: routeQuery['token'],
          ),
          '/verify-phone' => const VerifyPhoneScreen(),
          '/2fa' => const TwoFactorScreen(),
          '/role-selection' => const RoleSelectionScreen(),
          '/hub' => const ModuleHubScreen(),
          '/modules' => const ModulesScreen(),
          '/discover' || '/churches' => const FindChurchesScreen(),
          '/church' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'church.dashboard.view',
            child: const ChurchDashboardScreen(),
          ),
          '/church/admin' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'church.dashboard.view',
            child: const ChurchAdminDashboardScreen(),
          ),
          // Navigation hub for live destinations (discover, dashboard, media,
          // events). Admin list screens remain fixture-gated below.
          '/church/home' => const ChurchModuleHomeScreen(),
          '/church/mine' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'profile.view',
            child: const MyChurchScreen(),
          ),
          '/church/detail' => ChurchDetailScreen(
            churchId: routeArgs.entityId ?? _churchIdFromRoute(requestedRoute),
          ),
          '/church/directory' => const MembersListScreen(),
          '/church/members' => const MembersListScreen(),
          '/church/groups' => const ChurchGroupsScreen(),
          '/church/announcements' => const AnnouncementsScreen(),
          '/church/ministries' => churchFixtureSurface(
            'Church ministries',
            const MinistriesScreen(),
          ),
          '/church/documents' => const DocumentsScreen(),
          '/church/settings' => churchFixtureSurface(
            'Church settings',
            const ChurchSettingsScreen(),
          ),
          '/church/reports' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'church.reports.view',
            child: churchFixtureSurface(
              'Church reports',
              const ChurchReportsScreen(),
            ),
          ),
          '/church/first-timers' || '/first-timers' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'church.followup.view',
            child: churchFixtureSurface(
              'First timers',
              const FirstTimersScreen(),
            ),
          ),
          '/church/attendance' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'church.attendance.manage',
            child: churchFixtureSurface(
              'Church attendance',
              const HomeChurchAttendanceScreen(),
            ),
          ),
          '/church/activities' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'church.activities.manage',
            child: churchFixtureSurface(
              'Church activities',
              const HomeChurchActivitiesScreen(),
            ),
          ),
          '/church/finance' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'church.finance.view',
            child: churchFixtureSurface(
              'Church finance',
              const ChurchFinanceScreen(),
            ),
          ),
          '/leadership' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'leadership.dashboard.view',
            child: const LeadershipDashboardScreen(),
          ),
          '/home-church' => HomeChurchDashboardScreen(
            homeChurchId: routeArgs.entityId,
          ),
          '/home-church/members' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'home_church.members.view',
            child: churchFixtureSurface(
              'Home church members',
              const HomeChurchMembersScreen(),
            ),
          ),
          '/home-church/attendance' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'home_church.attendance.manage',
            child: churchFixtureSurface(
              'Home church attendance',
              const HomeChurchAttendanceScreen(),
            ),
          ),
          '/home-church/activities' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'home_church.activities.manage',
            child: churchFixtureSurface(
              'Home church activities',
              const HomeChurchActivitiesScreen(),
            ),
          ),
          '/home-church/finance' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'home_church.finance.view',
            child: churchFixtureSurface(
              'Home church finance',
              const ChurchFinanceScreen(homeChurch: true),
            ),
          ),
          '/home-church/reports' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'home_church.reports.view',
            child: ChurchReportsScreen(
              homeChurch: true,
              homeChurchId: routeArgs.entityId,
            ),
          ),
          '/home-church/monthly-report' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'home_church.reports.create',
            child: MonthlyReportScreen(homeChurchId: routeArgs.entityId),
          ),
          '/home-church/share-need' => PermissionGuard(
            gateway: authorizationGateway,
            // Laravel alias: home_church.needs.manage → church.home_churches.view
            // (home_church.needs.create is not registered).
            permission: 'home_church.needs.manage',
            child: churchFixtureSurface(
              'Share need',
              const ShareNeedScreen(),
            ),
          ),
          '/home-church/needs' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'home_church.needs.manage',
            child: churchFixtureSurface(
              'Needs management',
              const NeedsManagementScreen(),
            ),
          ),
          '/home-church/start' => const StartHomeChurchStep1Screen(),
          '/home-church/start/2' => const StartHomeChurchStep2Screen(),
          '/home-church/start/3' => const StartHomeChurchStep3Screen(),
          '/home-church/start/4' => const StartHomeChurchStep4Screen(),
          '/home-church/applications' => const HomeChurchApplicationsScreen(),
          '/home-church/progress' => const StartHomeChurchProgressScreen(),
          '/online-church' => const OnlineChurchScreen(),
          '/altar-call' => const AltarCallScreen(),
          '/altar-call/submitted' => const AltarCallSubmittedScreen(),
          '/altar-call/follow-ups' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'altar_call.followup.view',
            child: const AltarCallFollowupsScreen(),
          ),
          '/counseling/request' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'counselling.create',
            child: const CounselingRequestScreen(),
          ),
          '/needs/request' => needsSurface(
            PermissionGuard(
              gateway: authorizationGateway,
              permission: 'needs.create',
              child: const NeedRequestScreen(),
            ),
          ),
          '/needs/status' => needsSurface(
            PermissionGuard(
              gateway: authorizationGateway,
              permission: 'needs.view_own',
              child: const NeedStatusScreen(),
            ),
          ),
          '/needs/detail' => needsSurface(
            guarded(
              'needs.view_own',
              NeedDetailsScreen(needId: routeArgs.entityId),
            ),
          ),
          '/church/attendance/record' => guarded(
            'church.attendance.manage',
            const RecordAttendanceScreen(),
          ),
          '/testimony/new' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'testimony.create',
            child: const TestimonySubmissionScreen(),
          ),
          '/events' => const EventsScreen(),
          '/events/detail' => EventDetailScreen(eventId: routeArgs.entityId),
          '/events/register' => EventRegistrationScreen(
            eventId: routeArgs.entityId,
          ),
          '/events/payment' => EventPaymentScreen(
            registrationId: routeArgs.entityId,
          ),
          '/events/tickets' => EventTicketsScreen(
            registrationId: routeArgs.entityId,
          ),
          '/events/attendance' => const EventAttendanceScreen(),
          '/events/feedback' => const EventFeedbackScreen(),
          '/prayer' => prayerSurface(
            PermissionGuard(
              gateway: authorizationGateway,
              permission: 'prayer.view',
              child: const PrayerScreen(),
            ),
          ),
          '/prayer/new' => prayerSurface(
            PermissionGuard(
              gateway: authorizationGateway,
              permission: 'prayer.create',
              child: const PrayerNewScreen(),
            ),
          ),
          '/give' => paymentSurface(
            PermissionGuard(
              gateway: authorizationGateway,
              permission: 'giving.create',
              child: const GiveScreen(),
            ),
          ),
          '/give/history' => paymentSurface(
            PermissionGuard(
              gateway: authorizationGateway,
              permission: 'giving.history.view',
              child: const GivingHistoryScreen(),
            ),
          ),
          '/wallet' => paymentSurface(
            PermissionGuard(
              gateway: authorizationGateway,
              permission: 'wallet.view',
              child: const WalletScreen(),
            ),
          ),
          '/payments/receipt' => paymentSurface(
            guarded(
              'payments.receipts.view_own',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.receipt,
              ),
            ),
          ),
          '/payments/receipt/share' => paymentSurface(
            guarded(
              'payments.receipts.view_own',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.shareReceipt,
              ),
            ),
          ),
          '/payments/history' => paymentSurface(
            guarded(
              'payments.history.view_own',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.paymentHistory,
              ),
            ),
          ),
          '/payments/transaction' => paymentSurface(
            guarded(
              'payments.transactions.view_own',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.transaction,
              ),
            ),
          ),
          '/payments/pending' => paymentSurface(
            guarded(
              'payments.transactions.view_own',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.paymentPending,
              ),
            ),
          ),
          '/payments/refund' => paymentSurface(
            guarded(
              'payments.refunds.view_own',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.refund,
              ),
            ),
          ),
          '/payments/dispute' => paymentSurface(
            guarded(
              'payments.disputes.view_own',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.dispute,
              ),
            ),
          ),
          '/giving/recurring' => paymentSurface(
            guarded(
              'giving.recurring.manage',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.recurringGiving,
              ),
            ),
          ),
          '/payments/processing' => paymentSurface(
            guarded(
              'payments.create',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.paymentProcessing,
              ),
            ),
          ),
          '/payments/success' => paymentSurface(
            guarded(
              'payments.transactions.view_own',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.paymentSuccess,
              ),
            ),
          ),
          '/payments/failed' => paymentSurface(
            guarded(
              'payments.transactions.view_own',
              const AccountContinuationScreen(
                kind: AccountContinuationKind.paymentFailed,
              ),
            ),
          ),
          '/fellowship/live' => const LiveFellowshipScreen(),
          '/sermons' => const SermonsLibraryScreen(),
          '/groups' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'groups.view',
            child: const GroupsScreen(),
          ),
          '/bible' => const BibleScreen(),
          '/bible/plans' => const BiblePlansScreen(),
          '/bible/read' => const BibleReaderScreen(),
          '/media' => const MediaHubScreen(),
          '/kca' => const KcaEntryGate(),
          '/kca/gate' => const KcaEntryGate(),
          '/kca/enroll' => guarded(
            'kca.enrollment.create',
            const KcaEnrollScreen(),
          ),
          '/kca/modules' => const KcaModulesScreen(),
          '/kca/module' => KcaModuleScreen(
            moduleId: routeArgs.entityId ?? routeQuery['id'],
          ),
          '/kca/lesson' => KcaLessonScreen(
            lessonId: routeArgs.entityId ?? routeQuery['id'],
          ),
          '/kca/chapter' => KcaLessonScreen(
            lessonId: routeArgs.entityId ?? routeQuery['id'],
            chapter: true,
          ),
          '/kca/assignments' =>
            (routeArgs.entityId ?? routeQuery['id'])?.trim().isNotEmpty == true
                ? KcaAssignmentDetailScreen(
                    assignmentId: routeArgs.entityId ?? routeQuery['id'],
                  )
                : const KcaAssignmentsScreen(),
          '/kca/assignment' => KcaAssignmentDetailScreen(
            assignmentId: routeArgs.entityId ?? routeQuery['id'],
          ),
          '/kca/mentor' => const MentorChatScreen(),
          '/kca/evidence' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'kca.evidence.create',
            child: const KcaEvidenceUploadScreen(),
          ),
          '/kca/submissions' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'kca.evidence.view_own',
            child: const KcaSubmissionsScreen(),
          ),
          '/kca/certification' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'kca.certification.view_own',
            child: const KcaCertificationProgressScreen(),
          ),
          '/kca/admission' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'kca.admission.view_own',
            child: const KcaAdmissionStatusScreen(),
          ),
          '/kca/attendance' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'kca.attendance.view',
            child: const KcaAttendanceScreen(),
          ),
          '/kca/mentees' => const KcaMenteesScreen(),
          '/kca/review' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'kca.evidence.review',
            child: const KcaMentorReviewScreen(),
          ),
          '/kca/assessment' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'kca.assessment.view_own',
            child: const KcaFinalAssessmentScreen(),
          ),
          '/kca/certificate' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'kca.certificate.view_own',
            child: const KcaCertificateScreen(),
          ),
          '/kca/verify' => KcaCertificateVerifyScreen(
            initialCode: routeQuery['code'],
          ),
          '/kca/alumni' => const KcaAlumniDirectoryScreen(),
          '/kca/alumni/dashboard' => const KcaAlumniDirectoryScreen(
            dashboard: true,
          ),
          '/kca/opportunities' => const KcaOpportunitiesScreen(),
          '/kca/enrollment/1' => guarded(
            'kca.enrollment.create',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.churchInfo),
          ),
          '/kca/enrollment/2' => guarded(
            'kca.enrollment.create',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.walkWithChrist),
          ),
          '/kca/enrollment/3' => guarded(
            'kca.enrollment.create',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.whyJoin),
          ),
          '/kca/enrollment/4' => guarded(
            'kca.enrollment.create',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.interests),
          ),
          '/kca/enrollment/5' => guarded(
            'kca.enrollment.create',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.commitments),
          ),
          '/kca/enrollment/6' => guarded(
            'kca.enrollment.create',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.personalCommitment),
          ),
          '/kca/enrollment/7' => guarded(
            'kca.enrollment.create',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.guardianConsent),
          ),
          '/kca/enrollment/8' => guarded(
            'kca.enrollment.create',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.recommendation),
          ),
          '/kca/application-review' => guarded(
            'kca.admission.view_own',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.applicationReview),
          ),
          '/kca/admission-letter' => guarded(
            'kca.admission.view_own',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.admissionLetter),
          ),
          '/kca/orientation' => guarded(
            'kca.orientation.view',
            const KcaOrientationHubScreen(),
          ),
          '/kca/orientation/stage' => guarded(
            'kca.orientation.view',
            KcaOrientationStageScreen(
              stageKey: routeArgs.entityId ?? 'overview',
            ),
          ),
          '/kca/orientation/overview' => guarded(
            'kca.orientation.view',
            const KcaOrientationStageScreen(stageKey: 'overview'),
          ),
          '/kca/orientation/rules' => guarded(
            'kca.orientation.view',
            const KcaOrientationStageScreen(stageKey: 'rules'),
          ),
          '/kca/orientation/path' => guarded(
            'kca.orientation.view',
            const KcaOrientationStageScreen(stageKey: 'path'),
          ),
          '/kca/orientation/mentors' => guarded(
            'kca.orientation.view',
            const KcaOrientationStageScreen(stageKey: 'mentors'),
          ),
          '/kca/practical-service' => guarded(
            'kca.practical_service.manage',
            const KcaPracticalServiceScreen(),
          ),
          '/kca/written-assessments' => guarded(
            'kca.assessments.view_own',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.writtenAssessments),
          ),
          '/kca/spiritual-assignment' => guarded(
            'kca.assignments.view_own',
            const KcaLifecycleScreen(
              kind: KcaLifecycleKind.spiritualAssignment,
            ),
          ),
          '/kca/self-review' => guarded(
            'kca.reviews.create_own',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.selfReview),
          ),
          '/kca/admin-review' => guarded(
            'kca.reviews.manage',
            const KcaLifecycleScreen(
              kind: KcaLifecycleKind.administratorReview,
            ),
          ),
          '/kca/locked-module' => guarded(
            'kca.modules.view',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.lockedModule),
          ),
          '/kca/physical-assignment' => guarded(
            'kca.assignments.create',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.physicalAssignment),
          ),
          '/kca/mentor-dashboard' => guarded(
            'kca.mentoring.view',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.mentorDashboard),
          ),
          '/kca/lecturer' => guarded(
            'kca.lessons.deliver',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.lecturerWorkspace),
          ),
          '/kca/intervention' => guarded(
            'kca.mentoring.intervene',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.mentorIntervention),
          ),
          '/kca/admission-decision' => guarded(
            'kca.admission.manage',
            const KcaLifecycleScreen(kind: KcaLifecycleKind.admissionDecision),
          ),
          // Member catalogue — provisional code falls through to
          // mobile.app.access (not admin mission.crusades.view).
          '/mission' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.catalogue.view',
            child: const MissionDashboardScreen(),
          ),
          '/mission/crusade' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.catalogue.view',
            child: CrusadeDetailScreen(crusadeId: routeArgs.entityId),
          ),
          '/mission/invite' => const InviteCrusadeScreen(),
          '/mission/request-status' => const CrusadeRequestStatusScreen(),
          '/mission/souls/add' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.souls.create',
            child: const AddSoulScreen(),
          ),
          '/mission/souls/profile' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.souls.view',
            child: const SoulProfileScreen(),
          ),
          '/mission/mentor-assignment' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.mentors.assign',
            child: const AssignMentorScreen(),
          ),
          '/mission/teams' => const MissionTeamsScreen(),
          '/mission/support-request' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.support.request',
            child: const MissionSupportRequestScreen(),
          ),
          '/mission/assignments' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.assignments.view',
            child: const MissionAssignmentsScreen(),
          ),
          '/mission/partners' => const MissionPartnersScreen(),
          '/mission/partner' => const MissionPartnerDetailsScreen(),
          '/mission/support' => const SupportMissionScreen(),
          '/mission/souls' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.dashboard.view',
            child: const SoulsFollowupScreen(),
          ),
          '/press' => const PressLibraryScreen(),
          '/press/devotionals' => const PressLibraryScreen(
            initialFamily: 'devotionals',
          ),
          '/press/admin' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'press.publications.manage',
            child: const PressAdminScreen(),
          ),
          '/press/book' => PressBookScreen(publicationId: routeArgs.entityId),
          '/press/categories' => const PressCategoriesScreen(),
          '/press/resource' ||
          '/press/publication' => PressResourceDetailScreen(
            publicationId: routeArgs.entityId,
          ),
          '/press/audio' => const PressAudioPlayerScreen(),
          '/downloads' => const DownloadsScreen(),
          '/journey' => guarded(
            'journey.view_own',
            const KingdomJourneyScreen(kind: KingdomJourneyKind.overview),
          ),
          '/journey/discover' => guarded(
            'journey.view_own',
            const KingdomJourneyScreen(kind: KingdomJourneyKind.discover),
          ),
          '/journey/join-church' => guarded(
            'journey.manage_own',
            const KingdomJourneyScreen(kind: KingdomJourneyKind.joinChurch),
          ),
          '/journey/member' => guarded(
            'journey.view_own',
            const KingdomJourneyScreen(kind: KingdomJourneyKind.member),
          ),
          '/journey/grow' => guarded(
            'journey.view_own',
            const KingdomJourneyScreen(kind: KingdomJourneyKind.grow),
          ),
          '/journey/serve' => guarded(
            'journey.view_own',
            const KingdomJourneyScreen(kind: KingdomJourneyKind.serve),
          ),
          '/journey/win-souls' => guarded(
            'journey.view_own',
            const KingdomJourneyScreen(kind: KingdomJourneyKind.winSouls),
          ),
          '/journey/become-kca' => guarded(
            'journey.view_own',
            const KingdomJourneyScreen(kind: KingdomJourneyKind.becomeKca),
          ),
          '/journey/home-church' => guarded(
            'journey.view_own',
            const KingdomJourneyScreen(kind: KingdomJourneyKind.homeChurch),
          ),
          '/journey/multiply' => guarded(
            'journey.view_own',
            const KingdomJourneyScreen(kind: KingdomJourneyKind.multiply),
          ),
          '/membership/register' => guarded(
            'membership.create',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.membershipRegistration,
            ),
          ),
          '/first-timer/register' => guarded(
            'church.first_timers.create',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.firstTimerRegistration,
            ),
          ),
          '/first-timer/journey' => guarded(
            'church.followup.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.firstTimerJourney,
            ),
          ),
          '/convert/profile' => guarded(
            'mission.souls.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.convertProfile,
            ),
          ),
          '/disciple/progress' => guarded(
            'discipleship.progress.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.discipleProgress,
            ),
          ),
          '/member/profile' => guarded(
            'members.profile.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.memberProfile,
            ),
          ),
          '/ministry/role' => guarded(
            'ministry.roles.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.ministryRole,
            ),
          ),
          '/ministry/history' => guarded(
            'ministry.history.view_own',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.ministryHistory,
            ),
          ),
          '/evangelism/activity' => guarded(
            'mission.activities.create',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.evangelismActivity,
            ),
          ),
          '/evangelism/report' => guarded(
            'mission.reports.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.evangelismReport,
            ),
          ),
          '/referrals/connect' => guarded(
            'church.referrals.manage',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.connectChurch,
            ),
          ),
          '/referrals/tracking' => guarded(
            'church.referrals.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.referralTracking,
            ),
          ),
          '/leadership/approvals' => guarded(
            'leadership.approvals.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.approvalsQueue,
            ),
          ),
          '/leadership/approval' => guarded(
            'leadership.approvals.manage',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.approvalDetail,
            ),
          ),
          '/leadership/reports' => guarded(
            'leadership.reports.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.leadershipReports,
            ),
          ),
          '/leadership/alerts' => guarded(
            'leadership.alerts.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.alerts,
            ),
          ),
          '/ai' => guarded(
            'ai.assistants.use',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.aiHub,
            ),
          ),
          '/ai/pastoral' => guarded(
            'ai.pastoral.use',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.pastoralAssistant,
            ),
          ),
          '/ai/mission' => guarded(
            'ai.mission.use',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.missionAi,
            ),
          ),
          '/ai/kca' => guarded(
            'ai.kca.use',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.kcaAi,
            ),
          ),
          '/ai/press' => guarded(
            'ai.press.use',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.pressAi,
            ),
          ),
          '/ai/pastoral-reports' => guarded(
            'ai.pastoral.reports',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.pastoralReports,
            ),
          ),
          '/leadership/scope' => guarded(
            'leadership.scope.select',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.scopeSelector,
            ),
          ),
          '/leadership/scope-dashboard' => guarded(
            'leadership.dashboard.view',
            const LeadershipContinuationScreen(
              kind: LeadershipContinuationKind.scopeDashboard,
            ),
          ),
          '/map' => const LeadershipContinuationScreen(
            kind: LeadershipContinuationKind.globalMap,
          ),
          '/map/filter' => const LeadershipContinuationScreen(
            kind: LeadershipContinuationKind.mapFilter,
          ),
          '/map/mission-location' => const LeadershipContinuationScreen(
            kind: LeadershipContinuationKind.missionLocation,
          ),
          '/map/no-church' => const LeadershipContinuationScreen(
            kind: LeadershipContinuationKind.noChurchNearby,
          ),
          '/global-expansion' => const LeadershipContinuationScreen(
            kind: LeadershipContinuationKind.globalExpansion,
          ),
          '/settings/notifications' => guarded(
            'settings.notifications.manage',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.notificationPreferences,
            ),
          ),
          '/settings/communications' => guarded(
            'settings.communications.manage',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.communicationPreferences,
            ),
          ),
          '/settings/sessions' => guarded(
            'security.sessions.manage',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.activeSessions,
            ),
          ),
          '/settings/privacy' => guarded(
            'privacy.manage_own',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.privacy,
            ),
          ),
          '/settings/consents' => guarded(
            'consents.manage_own',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.consents,
            ),
          ),
          '/settings/data-export' => guarded(
            'privacy.export_own',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.dataExport,
            ),
          ),
          '/settings/delete-account' => guarded(
            'privacy.delete_own',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.accountDeletion,
            ),
          ),
          '/guardian/child' => guarded(
            'guardian.child.view',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.childProfile,
            ),
          ),
          '/guardian/controls' => guarded(
            'guardian.controls.manage',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.guardianControls,
            ),
          ),
          '/guardian/consent' => guarded(
            'guardian.consent.manage',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.guardianConsent,
            ),
          ),
          '/guardian/restricted' => guarded(
            'guardian.communication.view',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.restrictedCommunication,
            ),
          ),
          '/safeguarding/report' => guarded(
            'safeguarding.reports.create',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.safeguardingReport,
            ),
          ),
          '/pastoral/record' => guarded(
            'pastoral.records.view',
            const AccountContinuationScreen(
              kind: AccountContinuationKind.pastoralRecord,
            ),
          ),
          '/offline' => const OfflineSyncScreen(kind: OfflineSyncKind.offline),
          '/sync/pending' => guarded(
            'sync.queue.view_own',
            const OfflineSyncScreen(kind: OfflineSyncKind.syncPending),
          ),
          '/sync/success' => guarded(
            'sync.queue.view_own',
            const OfflineSyncScreen(kind: OfflineSyncKind.syncSuccessful),
          ),
          '/uploads/progress' => guarded(
            'uploads.view_own',
            const OfflineSyncScreen(kind: OfflineSyncKind.uploadProgress),
          ),
          '/uploads/failed' => guarded(
            'uploads.retry_own',
            const OfflineSyncScreen(kind: OfflineSyncKind.uploadFailed),
          ),
          '/downloads/storage' => guarded(
            'downloads.manage_own',
            const OfflineSyncScreen(kind: OfflineSyncKind.storage),
          ),
          '/settings/low-bandwidth' => const OfflineSyncScreen(
            kind: OfflineSyncKind.lowBandwidth,
          ),
          '/content/unavailable' => const OfflineSyncScreen(
            kind: OfflineSyncKind.contentUnavailable,
          ),
          '/notifications' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'notifications.view',
            child: const NotificationsScreen(),
          ),
          '/profile' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'profile.view',
            child: const ProfileScreen(),
          ),
          '/profile/edit' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'profile.view',
            child: const EditProfileScreen(),
          ),
          '/settings' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'settings.view',
            child: const SettingsScreen(),
          ),
          '/settings/help' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'settings.view',
            child: const HelpSupportScreen(),
          ),
          '/messages' => messagingSurface(const MessagesInboxScreen()),
          _ => const OfflineSyncScreen(
            kind: OfflineSyncKind.contentUnavailable,
          ),
        };
        return PageRouteBuilder<void>(
          settings: RouteSettings(
            name: requestedRoute,
            arguments: routeArgs,
          ),
          transitionDuration: FhcMotion.fast,
          reverseTransitionDuration: FhcMotion.fast,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
        );
      },
        );

        return AppServicesScope(
          services: resolvedServices,
          child: OfflineScope(
            controller: resolvedServices.offline,
            child: AppLaunchScope(
            store: resolvedLaunch,
            child: FhcLocaleScope(
              languageCode: localeCode,
              child: app,
            ),
          ),
          ),
        );
      },
    );
  }
}

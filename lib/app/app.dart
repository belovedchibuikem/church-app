import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/auth/authorization.dart';
import '../core/design_system/fhc_tokens.dart';
import '../features/account/presentation/account_screens.dart';
import '../features/church/presentation/church_screens.dart';
import '../features/community/presentation/community_screens.dart';
import '../features/dashboards/presentation/dashboard_screens.dart';
import '../features/foundation/presentation/foundation_screens.dart';
import '../features/kca/presentation/kca_screens.dart';
import '../features/mission/presentation/mission_screens.dart';
import '../features/press/presentation/press_screens.dart';
import '../shared/widgets/permission_guard.dart';

class FamilyHouseConnectApp extends StatelessWidget {
  const FamilyHouseConnectApp({
    super.key,
    this.initialRoute = '/splash',
    this.authorizationGateway = const VisualReviewAuthorizationGateway(),
  });

  final String initialRoute;
  final AuthorizationGateway authorizationGateway;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family House Connect',
      debugShowCheckedModeBanner: false,
      theme: buildFhcTheme(),
      supportedLocales: const [
        Locale('en'),
        Locale('yo'),
        Locale('ig'),
        Locale('ha'),
        Locale('fr'),
        Locale('ar'),
        Locale('zh'),
        Locale('sw'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        final route = settings.name ?? '/splash';
        final page = switch (route) {
          '/splash' => const SplashScreen(),
          '/onboarding/discover' => const OnboardingDiscoverScreen(),
          '/onboarding/connect' => const OnboardingConnectScreen(),
          '/onboarding/multiply' => const OnboardingMultiplyScreen(),
          '/language' => const LanguageLocationScreen(),
          '/sign-in' => const SignInScreen(),
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
          '/church/home' => const ChurchModuleHomeScreen(),
          '/church/detail' => const ChurchDetailScreen(),
          '/church/members' => const MembersListScreen(),
          '/church/groups' => const ChurchGroupsScreen(),
          '/church/announcements' => const AnnouncementsScreen(),
          '/church/ministries' => const MinistriesScreen(),
          '/church/documents' => const DocumentsScreen(),
          '/church/settings' => const ChurchSettingsScreen(),
          '/home-church' => const HomeChurchDashboardScreen(),
          '/home-church/start' => const StartHomeChurchStep1Screen(),
          '/home-church/start/2' => const StartHomeChurchStep2Screen(),
          '/home-church/start/3' => const StartHomeChurchStep3Screen(),
          '/home-church/start/4' => const StartHomeChurchStep4Screen(),
          '/home-church/applications' => const HomeChurchApplicationsScreen(),
          '/home-church/progress' => const StartHomeChurchProgressScreen(),
          '/events' => const EventsScreen(),
          '/events/detail' => const EventDetailScreen(),
          '/prayer' => const PrayerScreen(),
          '/prayer/new' => const PrayerNewScreen(),
          '/give' => const GiveScreen(),
          '/give/history' => const GivingHistoryScreen(),
          '/fellowship/live' => const LiveFellowshipScreen(),
          '/sermons' => const SermonsLibraryScreen(),
          '/groups' => const GroupsScreen(),
          '/bible' => const BibleScreen(),
          '/media' => const MediaHubScreen(),
          '/kca' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'kca.dashboard.view',
            child: const KcaDashboardScreen(),
          ),
          '/kca/gate' => const KcaEntryGate(),
          '/kca/enroll' => const KcaEnrollScreen(),
          '/kca/modules' => const KcaModulesScreen(),
          '/kca/module' => const KcaModuleScreen(),
          '/kca/lesson' => const KcaLessonScreen(),
          '/kca/assignments' => const KcaAssignmentsScreen(),
          '/kca/mentor' => const MentorChatScreen(),
          '/mission' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.dashboard.view',
            child: const MissionDashboardScreen(),
          ),
          '/mission/crusade' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.dashboard.view',
            child: const CrusadeDetailScreen(),
          ),
          '/mission/souls' => PermissionGuard(
            gateway: authorizationGateway,
            permission: 'mission.dashboard.view',
            child: const SoulsFollowupScreen(),
          ),
          '/press' => const PressLibraryScreen(),
          '/press/book' => const PressBookScreen(),
          '/notifications' => const NotificationsScreen(),
          '/profile' => const ProfileScreen(),
          '/settings' => const SettingsScreen(),
          '/messages' => const MessagesInboxScreen(),
          _ => const SplashScreen(),
        };
        return PageRouteBuilder<void>(
          settings: RouteSettings(name: route),
          transitionDuration: FhcMotion.fast,
          reverseTransitionDuration: FhcMotion.fast,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}

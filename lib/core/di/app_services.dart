import 'package:family_house_connect_public_api/public_api.dart';
import 'package:flutter/foundation.dart';

import '../../features/account/data/message_repository.dart';
import '../../features/account/data/notification_repository.dart';
import '../../features/account/data/profile_repository.dart';
import '../../features/account/data/security_repository.dart';
import '../../features/church/data/church_repository.dart';
import '../../features/church/data/home_church_repository.dart';
import '../../features/community/data/bible_repository.dart';
import '../../features/community/data/event_repository.dart';
import '../../features/community/data/need_repository.dart';
import '../../features/community/data/payment_repository.dart';
import '../../features/community/data/prayer_repository.dart';
import '../../features/content/data/content_repository.dart';
import '../../features/foundation/data/auth_repository.dart';
import '../../features/kca/data/kca_repository.dart';
import '../../features/mission/data/mission_repository.dart';
import '../../features/press/data/press_repository.dart';
import '../api/api_transport.dart';
import '../api/fhc_api_config.dart';
import '../api/http_api_transport.dart';
import '../api/http_public_api_transport.dart';
import '../auth/authorization.dart';
import '../auth/laravel_authorization_gateway.dart';
import '../contracts/mobile_repository_contracts.dart';
import '../notifications/push_notification_scaffold.dart';
import '../sync/http_sync_repository.dart';
import '../sync/sync_contract.dart';


/// Application composition root.
///
/// Constructs transport, token store, authorization gateway, and the generated
/// public API client. Protected HTTP repositories (prayer/needs/messages/
/// notifications/sync/payments) bind only when [transport] is present;
/// otherwise screens show honest unavailable UI — never fixture inboxes.
///
/// URL bridge:
/// - [apiBaseUrl] → `/api/v1` for [HttpApiTransport] (`FHC_API_URL`)
/// - [publicApiBaseUrl] → host for generated clients (`FHC_PUBLIC_API_BASE_URL`)
final class AppServices {
  AppServices._({
    required this.apiBaseUrl,
    required this.publicApiBaseUrl,
    required this.tokenStore,
    required this.authorizationGateway,
    required this.publicApi,
    required this.visualReview,
    required this.showUnboundFixtures,
    this.transport,
    this.authRepository,
    this.profileRepository,
    this.churchRepository,
    this.homeChurchRepository,
    this.missionRepository,
    this.kcaRepository,
    this.pressRepository,
    this.eventRepository,
    this.contentRepository,
    this.prayerRepository,
    this.needRepository,
    this.paymentRepository,
    this.messageRepository,
    this.notificationRepository,
    this.bibleRepository,
    this.securityRepository,
    this.syncRepository,
    this.pushNotifications = const PushNotificationScaffold(),
  });

  /// Sentinel so callers can pass `transport: null` to leave protected HTTP
  /// repositories unbound (honest unavailable UI).
  static const Object _createDefaultTransport = Object();

  final String apiBaseUrl;
  final String publicApiBaseUrl;
  final SessionTokenStore tokenStore;
  final AuthorizationGateway authorizationGateway;
  final FamilyHousePublicApiClient publicApi;
  final bool visualReview;

  /// Always present; [PushNotificationScaffold.isConfigured] stays false until
  /// an OD-009 push provider (FCM/APNs) is approved and wired.
  final PushNotificationScaffold pushNotifications;

  /// When true, unbound payment/prayer/messaging screens keep fixture UI
  /// (visual-review / golden captures only). **Always false in release** and
  /// false in normal debug/profile so the app talks to the live API.
  final bool showUnboundFixtures;

  /// Shared [HttpApiTransport] for protected/feature repositories.
  /// Null when bootstrap was called with `transport: null`.
  final ApiTransport? transport;

  final AuthRepository? authRepository;
  final ProfileRepository? profileRepository;
  final ChurchRepository? churchRepository;
  final HomeChurchRepository? homeChurchRepository;
  final MissionRepository? missionRepository;
  final KcaRepository? kcaRepository;
  final PressRepository? pressRepository;
  final EventRepository? eventRepository;
  final ContentRepository? contentRepository;
  final PrayerRepository? prayerRepository;
  final NeedRepository? needRepository;
  final PaymentRepository? paymentRepository;
  final MessageRepository? messageRepository;
  final NotificationRepository? notificationRepository;
  final BibleRepository? bibleRepository;
  final SecurityRepository? securityRepository;
  final SyncRepository? syncRepository;

  bool get paymentsBound => paymentRepository != null;
  bool get prayerBound => prayerRepository != null;
  bool get needsBound => needRepository != null;
  bool get messagingBound => messageRepository != null;
  bool get notificationsBound => notificationRepository != null;
  bool get syncBound =>
      syncRepository != null && syncRepository is! UnconfiguredSyncRepository;
  bool get churchCatalogueBound => churchRepository != null;
  bool get homeChurchApplyBound => homeChurchRepository != null;

  /// Honest unavailable for payment UX unless a repository is wired or fixtures
  /// are explicitly allowed (visual review / debug).
  bool get hideUnboundPayments =>
      !paymentsBound && !showUnboundFixtures;

  bool get hideUnboundPrayer => !prayerBound && !showUnboundFixtures;

  bool get hideUnboundNeeds => !needsBound && !showUnboundFixtures;

  bool get hideUnboundMessaging =>
      !messagingBound && !showUnboundFixtures;

  /// Church directory / groups / announcements / documents bind via
  /// [ChurchRepository] user-scoped list APIs. Admin-heavy church ops still
  /// use [hideUnboundChurchFixtures] when unbound.
  bool get hideUnboundChurchFixtures => !showUnboundFixtures;

  static AppServices bootstrap({
    String? apiBaseUrl,
    SessionTokenStore? tokenStore,
    AuthorizationGateway? authorizationGateway,
    bool visualReview = false,
    bool? showUnboundFixtures,
    Object? transport = _createDefaultTransport,
    SessionRefresher? sessionRefresher,
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    ChurchRepository? churchRepository,
    HomeChurchRepository? homeChurchRepository,
    MissionRepository? missionRepository,
    KcaRepository? kcaRepository,
    PressRepository? pressRepository,
    EventRepository? eventRepository,
    ContentRepository? contentRepository,
    PrayerRepository? prayerRepository,
    NeedRepository? needRepository,
    PaymentRepository? paymentRepository,
    MessageRepository? messageRepository,
    NotificationRepository? notificationRepository,
    BibleRepository? bibleRepository,
    SecurityRepository? securityRepository,
    SyncRepository? syncRepository,
    PushNotificationScaffold? pushNotifications,
  }) {
    assertFhcApiConfiguredForRelease(override: apiBaseUrl);

    // Release never ships allow-all auth or unbound fixture UX — even if a
    // caller (or FHC_VISUAL_REVIEW) asked for them.
    final effectiveVisualReview = visualReview && !kReleaseMode;
    if (visualReview && kReleaseMode) {
      debugPrint(
        'FHC: FHC_VISUAL_REVIEW / visualReview ignored in release builds.',
      );
    }
    final effectiveShowUnboundFixtures =
        kReleaseMode
            ? false
            : (showUnboundFixtures ?? effectiveVisualReview);

    final apiUrl = resolveFhcApiUrl(override: apiBaseUrl);
    final publicOrigin = resolveFhcPublicApiBaseUrl(override: apiBaseUrl);
    final store = tokenStore ?? createSessionTokenStore();
    sharedAccountTokenStore(store);

    var gateway =
        authorizationGateway ??
        createAuthorizationGateway(
          apiBaseUrl: apiUrl,
          tokenStore: store,
          visualReview: effectiveVisualReview,
        );
    if (kReleaseMode && gateway is VisualReviewAuthorizationGateway) {
      debugPrint(
        'FHC: refusing VisualReviewAuthorizationGateway in release; '
        'using LaravelAuthorizationGateway.',
      );
      gateway = createAuthorizationGateway(
        apiBaseUrl: apiUrl,
        tokenStore: store,
        visualReview: false,
      );
    }

    // Auth is always the live Laravel mobile auth client — never a fixture.
    final resolvedAuth =
        authRepository ??
        LaravelAuthRepository(
          tokenStore: store,
          authorizationGateway: gateway,
          apiBaseUrl: apiUrl,
        );

    if (gateway is LaravelAuthorizationGateway &&
        resolvedAuth is SessionRefresher) {
      gateway.sessionRefresher = resolvedAuth as SessionRefresher;
    }

    final refresher =
        sessionRefresher ??
        (resolvedAuth is SessionRefresher
            ? resolvedAuth as SessionRefresher
            : null);

    final publicTransport = HttpPublicApiTransport();
    final publicApi = FamilyHousePublicApiClient(
      baseUri: Uri.parse(publicOrigin),
      transport: publicTransport,
    );

    final ApiTransport? resolvedTransport =
        identical(transport, _createDefaultTransport)
            ? createHttpApiTransport(
              tokenStore: store,
              baseUrl: apiUrl,
              refresher: refresher,
            )
            : transport as ApiTransport?;

    final resolvedProfile =
        profileRepository ??
        LaravelProfileRepository.fromTokenStore(
          tokenStore: store,
          baseUrl: apiUrl,
        );
    final resolvedSecurity =
        securityRepository ??
        LaravelSecurityRepository.fromTokenStore(
          tokenStore: store,
          baseUrl: apiUrl,
        );

    if (!effectiveVisualReview && gateway is LaravelAuthorizationGateway) {
      gateway.prefetchCapabilities();
    }

    T? withTransport<T>(T Function(ApiTransport t) build) =>
        resolvedTransport == null ? null : build(resolvedTransport);

    return AppServices._(
      apiBaseUrl: apiUrl,
      publicApiBaseUrl: publicOrigin,
      tokenStore: store,
      authorizationGateway: gateway,
      publicApi: publicApi,
      transport: resolvedTransport,
      visualReview: effectiveVisualReview,
      showUnboundFixtures: effectiveShowUnboundFixtures,
      authRepository: resolvedAuth,
      profileRepository: resolvedProfile,
      churchRepository:
          churchRepository ??
          ChurchRepositoryImpl(
            baseUrl: apiUrl,
            transport: resolvedTransport,
          ),
      homeChurchRepository:
          homeChurchRepository ??
          HomeChurchRepositoryImpl(
            baseUrl: apiUrl,
            transport: resolvedTransport,
          ),
      missionRepository:
          missionRepository ??
          HttpMissionRepository(
            baseUrl: apiUrl,
            transport: resolvedTransport,
          ),
      kcaRepository:
          kcaRepository ??
          HttpKcaRepository(baseUrl: apiUrl, transport: resolvedTransport),
      pressRepository:
          pressRepository ??
          RemotePressRepository(
            baseUrl: apiUrl,
            transport: resolvedTransport,
            tokenStore: store,
          ),
      eventRepository:
          eventRepository ??
          RemoteEventRepository(
            baseUrl: apiUrl,
            transport: resolvedTransport,
          ),
      contentRepository:
          contentRepository ?? RemoteContentRepository(publicApi: publicApi),
      prayerRepository:
          prayerRepository ??
          withTransport((t) => HttpPrayerRepository(transport: t)),
      needRepository:
          needRepository ??
          withTransport((t) => HttpNeedRepository(transport: t)),
      paymentRepository:
          paymentRepository ??
          withTransport(
            (t) => HttpPaymentRepository(
              transport: t,
              tokenStore: store,
              baseUrl: apiUrl,
            ),
          ),
      messageRepository:
          messageRepository ??
          withTransport((t) => HttpMessageRepository(transport: t)),
      notificationRepository:
          notificationRepository ??
          withTransport((t) => HttpNotificationRepository(transport: t)),
      bibleRepository:
          bibleRepository ??
          HttpBibleRepository(
            baseUrl: apiUrl,
            transport: resolvedTransport,
          ),
      securityRepository: resolvedSecurity,
      syncRepository:
          syncRepository ??
          withTransport((t) => HttpSyncRepository(transport: t)) ??
          const UnconfiguredSyncRepository(),
      pushNotifications: pushNotifications ?? const PushNotificationScaffold(),
    );
  }
}

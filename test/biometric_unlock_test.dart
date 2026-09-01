import 'package:family_house_connect_mobile/core/auth/authorization.dart';
import 'package:family_house_connect_mobile/core/auth/biometric_unlock.dart';
import 'package:family_house_connect_mobile/core/auth/session_token_store.dart';
import 'package:family_house_connect_mobile/core/di/app_services.dart';
import 'package:family_house_connect_mobile/core/di/app_services_scope.dart';
import 'package:family_house_connect_mobile/core/l10n/locale_scope.dart';
import 'package:family_house_connect_mobile/features/foundation/presentation/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fingerprint unlock is offered only when a session is stored', () async {
    final store = MemorySessionTokenStore();
    final biometrics = _FakeBiometrics(available: true, authenticates: true);
    final unlock = BiometricUnlock(tokenStore: store, biometrics: biometrics);

    expect(await unlock.canOfferUnlock, isFalse);

    await store.writeSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      deviceIdentifier: 'device',
    );
    await store.writeBiometricUnlockEnabled(true);

    expect(await unlock.canOfferUnlock, isTrue);
    expect(await unlock.authenticate(reason: 'test'), isTrue);
  });

  test('fingerprint is not offered when hardware is missing', () async {
    final store = MemorySessionTokenStore();
    await store.writeSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      deviceIdentifier: 'device',
    );
    await store.writeBiometricUnlockEnabled(true);
    final unlock = BiometricUnlock(
      tokenStore: store,
      biometrics: const _FakeBiometrics(available: false, authenticates: false),
    );
    expect(await unlock.canOfferUnlock, isFalse);
  });

  testWidgets('sign-in shows the fingerprint action when unlock is enabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemorySessionTokenStore();
    await store.writeSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      deviceIdentifier: 'device',
    );
    await store.writeBiometricUnlockEnabled(true);
    final biometric = BiometricUnlock(
      tokenStore: store,
      biometrics: const _FakeBiometrics(available: true, authenticates: true),
    );

    await tester.pumpWidget(
      AppServicesScope(
        services: AppServices.bootstrap(
          tokenStore: store,
          authorizationGateway: const VisualReviewAuthorizationGateway(),
          visualReview: true,
        ),
        child: FhcLocaleScope(
          languageCode: 'en',
          child: MaterialApp(
            home: SignInScreen(biometricUnlock: biometric),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in with fingerprint'), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}

final class _FakeBiometrics implements DeviceBiometrics {
  const _FakeBiometrics({
    required this.available,
    required this.authenticates,
  });

  final bool available;
  final bool authenticates;

  @override
  Future<bool> canAuthenticate() async => available;

  @override
  Future<bool> authenticate({required String reason}) async => authenticates;
}

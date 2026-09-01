import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../api/api_transport.dart';

/// Device biometrics (fingerprint / Face ID). Unavailable on web.
abstract interface class DeviceBiometrics {
  Future<bool> canAuthenticate();

  Future<bool> authenticate({required String reason});
}

final class UnavailableDeviceBiometrics implements DeviceBiometrics {
  const UnavailableDeviceBiometrics();

  @override
  Future<bool> canAuthenticate() async => false;

  @override
  Future<bool> authenticate({required String reason}) async => false;
}

final class LocalDeviceBiometrics implements DeviceBiometrics {
  LocalDeviceBiometrics({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> canAuthenticate() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      final enrolled = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (enrolled) return true;
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on MissingPluginException {
      return false;
    } on PlatformException {
      try {
        return await _auth.authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }
}

DeviceBiometrics createDeviceBiometrics() {
  if (kIsWeb) return const UnavailableDeviceBiometrics();
  return LocalDeviceBiometrics();
}

/// Fingerprint / Face ID gate over a stored 30-day mobile session.
final class BiometricUnlock {
  BiometricUnlock({
    required this.tokenStore,
    DeviceBiometrics? biometrics,
  }) : _biometrics = biometrics ?? createDeviceBiometrics();

  final SessionTokenStore tokenStore;
  final DeviceBiometrics _biometrics;

  Future<bool> get isHardwareAvailable => _biometrics.canAuthenticate();

  Future<bool> get isEnabled => tokenStore.readBiometricUnlockEnabled();

  Future<bool> get hasStoredSession async {
    final refresh = await tokenStore.readRefreshToken();
    final access = await tokenStore.readAccessToken();
    return (refresh != null && refresh.isNotEmpty) ||
        (access != null && access.isNotEmpty);
  }

  Future<bool> get canOfferUnlock async {
    if (!await isHardwareAvailable) return false;
    if (!await hasStoredSession) return false;
    return tokenStore.readBiometricUnlockEnabled();
  }

  Future<void> setEnabled(bool enabled) {
    return tokenStore.writeBiometricUnlockEnabled(enabled);
  }

  Future<bool> authenticate({required String reason}) {
    return _biometrics.authenticate(reason: reason);
  }
}

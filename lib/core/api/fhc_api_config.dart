import 'package:flutter/foundation.dart';

/// Resolves Laravel API base URLs for the Flutter app and generated clients.
///
/// Two dart-defines are supported (either is enough):
/// - `FHC_API_URL` — full `/api/v1` base used by this app's [HttpApiTransport]
///   (example: `https://familyconnect.katakarra.com/api/v1`).
/// - `FHC_PUBLIC_API_BASE_URL` — host only, matching
///   `api/clients/dart/dart-define.example.json` and generated Dart clients
///   whose paths already include `/api/v1/...`
///   (example: `https://familyconnect.katakarra.com`).
///
/// Prefer `FHC_API_URL` when both are set.
///
/// When defines are unset the production host is used:
/// `https://familyconnect.katakarra.com`.
/// Override with dart-defines for local Laravel (`http://localhost:8000`).
///
/// Release builds refuse loopback URLs so a store binary cannot silently
/// talk to emulator localhost.

/// Production API origin (no `/api/v1` suffix).
const kFhcProductionApiHost = 'https://familyconnect.katakarra.com';

/// True when a production API base was supplied via override or dart-define.
bool isFhcApiConfigured({String? override}) {
  final fromOverride = override?.trim() ?? '';
  if (fromOverride.isNotEmpty) return true;
  return isFhcApiConfiguredFromEnvironment();
}

/// True when `FHC_API_URL` or `FHC_PUBLIC_API_BASE_URL` is present at compile time.
bool isFhcApiConfiguredFromEnvironment() {
  const apiUrl = String.fromEnvironment('FHC_API_URL');
  const publicBase = String.fromEnvironment('FHC_PUBLIC_API_BASE_URL');
  return apiUrl.trim().isNotEmpty || publicBase.trim().isNotEmpty;
}

String resolveFhcPublicApiBaseUrl({String? override}) {
  final fromOverride = override?.trim() ?? '';
  if (fromOverride.isNotEmpty) {
    return _stripTrailingSlash(_stripApiV1Suffix(fromOverride));
  }

  final apiUrl = const String.fromEnvironment('FHC_API_URL').trim();
  if (apiUrl.isNotEmpty) {
    return _stripTrailingSlash(_stripApiV1Suffix(apiUrl));
  }

  final publicBase =
      const String.fromEnvironment('FHC_PUBLIC_API_BASE_URL').trim();
  if (publicBase.isNotEmpty) {
    return _stripTrailingSlash(publicBase);
  }

  return _stripTrailingSlash(_defaultHost());
}

/// Resolves the `/api/v1` base used by [HttpApiTransport] and local adapters.
String resolveFhcApiUrl({String? override}) {
  final fromOverride = override?.trim() ?? '';
  if (fromOverride.isNotEmpty) {
    return _ensureApiV1(_stripTrailingSlash(fromOverride));
  }

  final apiUrl = const String.fromEnvironment('FHC_API_URL').trim();
  if (apiUrl.isNotEmpty) {
    return _ensureApiV1(_stripTrailingSlash(apiUrl));
  }

  final publicBase =
      const String.fromEnvironment('FHC_PUBLIC_API_BASE_URL').trim();
  if (publicBase.isNotEmpty) {
    return '${_stripTrailingSlash(publicBase)}/api/v1';
  }

  return '${_stripTrailingSlash(_defaultHost())}/api/v1';
}

String _defaultHost() => kFhcProductionApiHost;

String _stripTrailingSlash(String value) =>
    value.replaceAll(RegExp(r'/$'), '');

String _stripApiV1Suffix(String value) {
  final normalized = _stripTrailingSlash(value);
  if (normalized.endsWith('/api/v1')) {
    return normalized.substring(0, normalized.length - '/api/v1'.length);
  }
  return normalized;
}

String _ensureApiV1(String value) {
  final normalized = _stripTrailingSlash(value);
  if (normalized.endsWith('/api/v1')) return normalized;
  return '$normalized/api/v1';
}

const _loopbackReleaseMessage =
    'Release builds must not use a loopback API URL. '
    'Set --dart-define=FHC_API_URL=https://familyconnect.katakarra.com/api/v1';

bool _isLoopbackUrl(String url) {
  final lower = url.toLowerCase();
  return lower.contains('localhost') ||
      lower.contains('127.0.0.1') ||
      lower.contains('10.0.2.2') ||
      lower.contains('0.0.0.0');
}

/// In release builds, refuse unbound localhost fallbacks.
///
/// Call from [AppServices.bootstrap] before resolving URLs.
void assertFhcApiConfiguredForRelease({String? override}) {
  if (!kReleaseMode) return;
  final url = resolveFhcApiUrl(override: override);
  if (_isLoopbackUrl(url)) {
    throw StateError('$_loopbackReleaseMessage (got $url)');
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';

enum MapsProviderKind { google, mapbox, leaflet }

/// When true (`--dart-define=FHC_MAPS_DEMO_FIXTURES=true`), failed/empty place
/// fetches may return local demo markers. Production builds leave this off and
/// surface empty + error instead of silent fixtures.
const bool kFhcMapsDemoFixtures = bool.fromEnvironment(
  'FHC_MAPS_DEMO_FIXTURES',
  defaultValue: false,
);

class MapsBootstrap {
  const MapsBootstrap({
    required this.active,
    required this.provider,
    required this.clientApiKey,
    required this.tileUrl,
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });

  final bool active;
  final MapsProviderKind provider;
  final String? clientApiKey;
  final String tileUrl;
  final double latitude;
  final double longitude;
  final double zoom;

  factory MapsBootstrap.fallback() => const MapsBootstrap(
        active: true,
        provider: MapsProviderKind.leaflet,
        clientApiKey: null,
        tileUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        latitude: 6.5244,
        longitude: 3.3792,
        zoom: 12,
      );

  factory MapsBootstrap.fromJson(Map<String, dynamic> json) {
    final provider = switch (json['provider'] as String? ?? 'leaflet') {
      'google' => MapsProviderKind.google,
      'mapbox' => MapsProviderKind.mapbox,
      _ => MapsProviderKind.leaflet,
    };
    final center = json['default_center'] as Map<String, dynamic>? ?? const {};
    return MapsBootstrap(
      active: json['active'] as bool? ?? false,
      provider: provider,
      clientApiKey: json['client_api_key'] as String?,
      tileUrl: (json['tile_url'] as String?) ??
          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      latitude: (center['latitude'] as num?)?.toDouble() ?? 6.5244,
      longitude: (center['longitude'] as num?)?.toDouble() ?? 3.3792,
      zoom: (json['default_zoom'] as num?)?.toDouble() ?? 12,
    );
  }
}

class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.type = 'church',
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String type;
}

/// Public maps catalogue client (`/maps/configuration`, `/maps/places`).
///
/// Uses the same success/error envelope pattern as other public catalogue
/// clients. Demo places are never returned unless [allowDemoFixtures] / the
/// `FHC_MAPS_DEMO_FIXTURES` flag is enabled.
class MapsApi {
  MapsApi({
    String? baseUrl,
    http.Client? httpClient,
    bool? allowDemoFixtures,
  })  : baseUrl = resolveFhcApiUrl(override: baseUrl),
        _http = httpClient ?? http.Client(),
        allowDemoFixtures = allowDemoFixtures ?? kFhcMapsDemoFixtures;

  final String baseUrl;
  final http.Client _http;
  final bool allowDemoFixtures;

  Future<AppResult<MapsBootstrap>> configuration() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/maps/configuration'),
        headers: const {'Accept': 'application/json'},
      );
      final decoded = _decodeBody(response.body);
      if (decoded == null) {
        return AppError(
          ServerFailure(
            'Invalid maps configuration response (${response.statusCode}).',
          ),
        );
      }
      final failure = _failureFromEnvelope(response.statusCode, decoded);
      if (failure != null) return AppError(failure);

      final data = decoded['data'];
      if (data is! Map) {
        return const AppError(
          ServerFailure('Maps configuration envelope missing data.'),
        );
      }
      return AppSuccess(
        MapsBootstrap.fromJson(Map<String, dynamic>.from(data)),
      );
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to reach maps configuration API.', cause: error),
      );
    } catch (error, stack) {
      debugPrint('Maps configuration error: $error\n$stack');
      return AppError(
        UnknownFailure('Maps configuration request failed.', cause: error),
      );
    }
  }

  /// Loads places. On API failure in production mode returns [AppError] with
  /// no demo markers. Empty successful payloads stay empty.
  Future<AppResult<List<MapPlace>>> places() async {
    try {
      final response = await _http.get(
        Uri.parse('$baseUrl/maps/places?type=all&limit=100'),
        headers: const {'Accept': 'application/json'},
      );
      final decoded = _decodeBody(response.body);
      if (decoded == null) {
        return _placesFailure(
          ServerFailure(
            'Invalid maps places response (${response.statusCode}).',
          ),
        );
      }
      final failure = _failureFromEnvelope(response.statusCode, decoded);
      if (failure != null) return _placesFailure(failure);

      final data = decoded['data'];
      if (data is! List) {
        return _placesFailure(
          const ServerFailure('Maps places envelope missing data[].'),
        );
      }
      if (data.isEmpty) {
        return const AppSuccess(<MapPlace>[]);
      }

      final places = <MapPlace>[];
      for (final item in data) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final coords = map['coordinates'];
        if (coords is! Map) continue;
        final coordMap = Map<String, dynamic>.from(coords);
        final lat = coordMap['latitude'];
        final lng = coordMap['longitude'];
        final id = map['id'];
        final name = map['name'];
        if (lat is! num || lng is! num || id is! String || name is! String) {
          continue;
        }
        places.add(
          MapPlace(
            id: id,
            name: name,
            latitude: lat.toDouble(),
            longitude: lng.toDouble(),
            type: map['type'] as String? ?? 'church',
          ),
        );
      }
      return AppSuccess(List<MapPlace>.unmodifiable(places));
    } on http.ClientException catch (error) {
      return _placesFailure(
        NetworkFailure('Unable to reach maps places API.', cause: error),
      );
    } catch (error, stack) {
      debugPrint('Maps places error: $error\n$stack');
      return _placesFailure(
        UnknownFailure('Maps places request failed.', cause: error),
      );
    }
  }

  AppResult<List<MapPlace>> _placesFailure(AppFailure failure) {
    if (allowDemoFixtures) {
      debugPrint('Maps places demo fixtures enabled: ${failure.message}');
      return const AppSuccess(_demoPlaces);
    }
    return AppError(failure);
  }

  static const _demoPlaces = [
    MapPlace(
      id: 'ikeja',
      name: 'Family House Church Ikeja',
      latitude: 6.6018,
      longitude: 3.3515,
    ),
    MapPlace(
      id: 'lekki',
      name: 'Family House Church Lekki',
      latitude: 6.4474,
      longitude: 3.4723,
    ),
    MapPlace(
      id: 'surulere',
      name: 'Surulere Home Church',
      latitude: 6.4969,
      longitude: 3.3566,
      type: 'home_church',
    ),
  ];
}

Map<String, dynamic>? _decodeBody(String body) {
  if (body.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  } catch (_) {
    return null;
  }
}

AppFailure? _failureFromEnvelope(int statusCode, Map<String, dynamic> body) {
  if (statusCode >= 200 && statusCode < 300) return null;
  final error = body['error'];
  final message = error is Map
      ? (error['message'] as String? ?? 'Request failed ($statusCode).')
      : 'Request failed ($statusCode).';
  return switch (statusCode) {
    401 => UnauthorizedFailure(message),
    403 => ForbiddenFailure(message),
    404 => NotFoundFailure(message),
    409 => ConflictFailure(message),
    422 => ValidationFailure(message),
    429 => RateLimitFailure(message),
    >= 500 => ServerFailure(message),
    _ => NetworkFailure(message),
  };
}

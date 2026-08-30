import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../data/maps_api.dart';

class InteractiveChurchMap extends StatefulWidget {
  const InteractiveChurchMap({
    super.key,
    this.height = 280,
    this.mode = InteractiveMapMode.explore,
    this.destination,
  });

  final double height;
  final InteractiveMapMode mode;
  final MapPlace? destination;

  @override
  State<InteractiveChurchMap> createState() => _InteractiveChurchMapState();
}

enum InteractiveMapMode { explore, directions }

class _InteractiveChurchMapState extends State<InteractiveChurchMap> {
  final _api = MapsApi();
  final _mapController = MapController();
  MapsBootstrap _config = MapsBootstrap.fallback();
  List<MapPlace> _places = const [];
  LatLng? _userLocation;
  String? _routeLabel;
  String? _placesError;
  String? _locationStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _placesError = null;
      _locationStatus = null;
    });

    final configResult = await _api.configuration();
    final placesResult = await _api.places();
    if (!mounted) return;

    setState(() {
      switch (configResult) {
        case AppSuccess(:final value):
          _config = value;
        case AppError():
          // Provider inactive / unreachable → documented Leaflet/OSM fallback.
          _config = MapsBootstrap.fallback();
      }
      switch (placesResult) {
        case AppSuccess(:final value):
          _places = value;
          _placesError = null;
        case AppError(:final failure):
          _places = const [];
          _placesError = failure.message;
      }
      _loading = false;
    });
  }

  Future<void> _useMyLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationStatus = fhcT(
            context,
            'onboarding.locationServicesOff',
            fallback: 'Location services are off',
          );
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationStatus = fhcT(
            context,
            'onboarding.locationPermission',
            fallback: 'Permission needed to personalize nearby churches',
          );
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _userLocation = point;
        _locationStatus = null;
      });
      _mapController.move(point, 14);
      if (widget.mode == InteractiveMapMode.directions &&
          widget.destination != null) {
        final km = (Geolocator.distanceBetween(
                  point.latitude,
                  point.longitude,
                  widget.destination!.latitude,
                  widget.destination!.longitude,
                ) /
                1000)
            .toString();
        setState(() {
          _routeLabel = fhcT(
            context,
            'common.routeReady',
            args: {'km': km},
            fallback: 'Route ready · {km} km',
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationStatus = fhcT(
          context,
          'onboarding.locationUnavailable',
          fallback: 'Location unavailable — you can continue',
        );
      });
    }
  }

  String get _providerLabel => switch (_config.provider) {
        MapsProviderKind.google => 'Google Maps tiles via key',
        MapsProviderKind.mapbox => 'Mapbox',
        MapsProviderKind.leaflet => 'Leaflet / OpenStreetMap',
      };

  String get _tileUrl {
    if (_config.provider == MapsProviderKind.mapbox &&
        (_config.clientApiKey?.isNotEmpty ?? false)) {
      return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=${_config.clientApiKey}';
    }
    // Leaflet always, and Google until a native Maps SDK key is baked into the app build.
    return _config.tileUrl.contains('{s}')
        ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
        : _config.tileUrl;
  }

  bool get _mapsInactive => !_config.active;

  @override
  Widget build(BuildContext context) {
    final center = widget.destination != null
        ? LatLng(widget.destination!.latitude, widget.destination!.longitude)
        : LatLng(_config.latitude, _config.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _mapsInactive ? null : _useMyLocation,
              icon: const Icon(Icons.my_location),
              label: Text(
                fhcT(
                  context,
                  'onboarding.locationUseMine',
                  fallback: 'Use my location',
                ),
              ),
            ),
            Chip(
              label: Text(
                _mapsInactive
                    ? fhcT(
                        context,
                        'errors.mapsInactive',
                        fallback: 'Maps inactive (API)',
                      )
                    : _providerLabel,
              ),
            ),
            if (_routeLabel != null) Chip(label: Text(_routeLabel!)),
            if (_placesError != null)
              ActionChip(
                avatar: const Icon(Icons.error_outline, size: 16),
                label: Text(
                  fhcT(context, 'common.retry', fallback: 'Try Again'),
                ),
                onPressed: _boot,
              ),
          ],
        ),
        if (_locationStatus != null) ...[
          const SizedBox(height: 4),
          Text(
            _locationStatus!,
            style: const TextStyle(fontSize: 12, color: FhcColors.muted),
          ),
        ],
        if (_mapsInactive) ...[
          const SizedBox(height: 4),
          Text(
            fhcT(
              context,
              'errors.mapsInactiveCopy',
              fallback:
                  'Maps configuration reports inactive. Showing OSM fallback tiles only; '
                  'native Google/Mapbox SDKs are not bound until a provider key is approved.',
            ),
            style: const TextStyle(fontSize: 12, color: FhcColors.muted),
          ),
        ],
        if (_placesError != null) ...[
          const SizedBox(height: 4),
          Text(
            _placesError!,
            style: const TextStyle(fontSize: 12, color: FhcColors.muted),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _loading
                ? const ColoredBox(
                    color: Color(0xFFE8EEF5),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: _config.zoom,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: _tileUrl,
                            userAgentPackageName:
                                'com.smartlogix.family_house_connect',
                            tileProvider: CancellableNetworkTileProvider(),
                          ),
                          MarkerLayer(
                            markers: [
                              for (final place in _places)
                                Marker(
                                  point: LatLng(place.latitude, place.longitude),
                                  width: 36,
                                  height: 36,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: FhcColors.green,
                                    size: 32,
                                  ),
                                ),
                              if (_userLocation != null)
                                Marker(
                                  point: _userLocation!,
                                  width: 28,
                                  height: 28,
                                  child: const Icon(
                                    Icons.radio_button_checked,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                            ],
                          ),
                          if (_userLocation != null &&
                              widget.destination != null)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [
                                    _userLocation!,
                                    LatLng(
                                      widget.destination!.latitude,
                                      widget.destination!.longitude,
                                    ),
                                  ],
                                  color: FhcColors.green,
                                  strokeWidth: 4,
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (_places.isEmpty)
                        IgnorePointer(
                          child: ColoredBox(
                            color: const Color(0xCCF5F8FB),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _placesError != null
                                      ? fhcT(
                                          context,
                                          'errors.somethingWentWrong',
                                          fallback: 'Places unavailable',
                                        )
                                      : fhcT(
                                          context,
                                          'errors.emptyMap',
                                          fallback:
                                              'No mapped places are published yet.',
                                        ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: FhcColors.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

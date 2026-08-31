import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/fhc_api_config.dart';

/// Public world geography for searchable Country → State → City/LGA selects.
///
/// Prefers the Laravel catalogue (`/api/v1/geography/...`) when populated,
/// then falls back to restcountries + countriesnow (same as the web app).
final class GeographyCatalog {
  GeographyCatalog({
    http.Client? httpClient,
    String? apiBaseUrl,
  }) : _http = httpClient ?? http.Client(),
       _apiBase = resolveFhcApiUrl(override: apiBaseUrl);

  static const defaultCountryCode = 'NG';
  static const _countriesUrl =
      'https://restcountries.com/v3.1/all?fields=name,cca2,flag';
  static const _statesUrl =
      'https://countriesnow.space/api/v0.1/countries/states';
  static const _citiesUrl =
      'https://countriesnow.space/api/v0.1/countries/state/cities';

  final http.Client _http;
  final String _apiBase;

  List<GeoCountry>? _countryCache;
  final Map<String, List<String>> _statesCache = {};
  final Map<String, List<String>> _citiesCache = {};

  static const fallbackCountries = <GeoCountry>[
    GeoCountry(code: 'NG', name: 'Nigeria', flag: '🇳🇬'),
    GeoCountry(code: 'GH', name: 'Ghana', flag: '🇬🇭'),
    GeoCountry(code: 'KE', name: 'Kenya', flag: '🇰🇪'),
    GeoCountry(code: 'ZA', name: 'South Africa', flag: '🇿🇦'),
    GeoCountry(code: 'UG', name: 'Uganda', flag: '🇺🇬'),
    GeoCountry(code: 'TZ', name: 'Tanzania', flag: '🇹🇿'),
    GeoCountry(code: 'CM', name: 'Cameroon', flag: '🇨🇲'),
    GeoCountry(code: 'US', name: 'United States', flag: '🇺🇸'),
    GeoCountry(code: 'GB', name: 'United Kingdom', flag: '🇬🇧'),
    GeoCountry(code: 'CA', name: 'Canada', flag: '🇨🇦'),
    GeoCountry(code: 'AU', name: 'Australia', flag: '🇦🇺'),
    GeoCountry(code: 'IN', name: 'India', flag: '🇮🇳'),
    GeoCountry(code: 'PH', name: 'Philippines', flag: '🇵🇭'),
    GeoCountry(code: 'BR', name: 'Brazil', flag: '🇧🇷'),
    GeoCountry(code: 'FR', name: 'France', flag: '🇫🇷'),
    GeoCountry(code: 'DE', name: 'Germany', flag: '🇩🇪'),
    GeoCountry(code: 'AE', name: 'United Arab Emirates', flag: '🇦🇪'),
    GeoCountry(code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦'),
    GeoCountry(code: 'EG', name: 'Egypt', flag: '🇪🇬'),
    GeoCountry(code: 'CN', name: 'China', flag: '🇨🇳'),
  ];

  static bool isNigeria(String? code) =>
      (code ?? '').trim().toUpperCase() == 'NG';

  static String localityLabelFor(String? countryCode) =>
      isNigeria(countryCode) ? 'LGA / City' : 'City / Area';

  static String formatLocationLine({
    String? locality,
    String? region,
    String? country,
    String? countryLabel,
  }) {
    final countryPart = (countryLabel ?? country ?? '').trim();
    return [
      locality,
      region,
      countryPart,
    ].map((part) => part?.trim() ?? '').where((part) => part.isNotEmpty).join(', ');
  }

  Future<List<GeoCountry>> fetchCountries() async {
    final cached = _countryCache;
    if (cached != null) return cached;

    final fromApi = await _fetchLaravelCountries();
    if (fromApi != null && fromApi.isNotEmpty) {
      _countryCache = fromApi;
      return fromApi;
    }

    try {
      final response = await _http
          .get(Uri.parse(_countriesUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallbackCountries;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return fallbackCountries;
      final next = <GeoCountry>[
        for (final item in decoded)
          if (item is Map)
            GeoCountry(
              code: '${item['cca2'] ?? ''}'.trim().toUpperCase(),
              name: '${(item['name'] is Map ? item['name']['common'] : null) ?? ''}'
                  .trim(),
              flag: item['flag'] is String ? item['flag'] as String : null,
            ),
      ]
          .where((item) => item.code.length == 2 && item.name.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (next.isEmpty) return fallbackCountries;
      _countryCache = next;
      return next;
    } catch (_) {
      return fallbackCountries;
    }
  }

  Future<List<String>> fetchStates(String countryCodeOrName) async {
    final name = countryCodeOrName.trim();
    if (name.isEmpty) return const [];
    final key = name.toLowerCase();
    final cached = _statesCache[key];
    if (cached != null) return cached;

    final iso = _isoHint(name) ?? await _isoForCountryName(name);
    if (iso != null) {
      final fromApi = await _fetchLaravelStates(iso);
      if (fromApi != null) {
        _statesCache[key] = fromApi;
        return fromApi;
      }
      throw StateError('Unable to load states from the platform catalogue.');
    }

    final response = await _http
        .post(
          Uri.parse(_statesUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'country': name}),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Unable to load states (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map ? decoded['data'] : null;
    final states = data is Map ? data['states'] : null;
    final names = <String>[
      if (states is List)
        for (final state in states)
          if (state is Map)
            '${state['name'] ?? ''}'.trim(),
    ].where((item) => item.isNotEmpty).toList()
      ..sort();
    _statesCache[key] = names;
    return names;
  }

  Future<List<String>> fetchCities(String countryCodeOrName, String stateName) async {
    final country = countryCodeOrName.trim();
    final state = stateName.trim();
    if (country.isEmpty || state.isEmpty) return const [];
    final key = '${country.toLowerCase()}::${state.toLowerCase()}';
    final cached = _citiesCache[key];
    if (cached != null) return cached;

    final iso = _isoHint(country) ?? await _isoForCountryName(country);
    if (iso != null) {
      final fromApi = await _fetchLaravelLocalities(iso, state);
      if (fromApi != null) {
        _citiesCache[key] = fromApi;
        return fromApi;
      }
      throw StateError('Unable to load local areas from the platform catalogue.');
    }

    final response = await _http
        .post(
          Uri.parse(_citiesUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'country': country, 'state': state}),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Unable to load cities (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map ? decoded['data'] : null;
    final names = <String>[
      if (data is List)
        for (final city in data) '$city'.trim(),
    ].where((item) => item.isNotEmpty).toList()
      ..sort();
    _citiesCache[key] = names;
    return names;
  }

  String countryDisplayName(String code, List<GeoCountry> countries) {
    final normalized = code.trim().toUpperCase();
    for (final country in countries) {
      if (country.code == normalized) return country.name;
    }
    return normalized;
  }

  String? _isoHint(String value) {
    final trimmed = value.trim();
    if (trimmed.length == 2) return trimmed.toUpperCase();
    return null;
  }

  Future<String?> _isoForCountryName(String countryName) async {
    final countries = await fetchCountries();
    final needle = countryName.trim().toLowerCase();
    for (final country in countries) {
      if (country.name.toLowerCase() == needle || country.code.toLowerCase() == needle) {
        return country.code;
      }
    }
    return null;
  }

  Future<List<GeoCountry>?> _fetchLaravelCountries() async {
    try {
      final response = await _http
          .get(
            Uri.parse('$_apiBase/geography/countries'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final data = _envelopeData(response.body);
      if (data is! List || data.isEmpty) return null;
      final next = <GeoCountry>[
        for (final item in data)
          if (item is Map)
            GeoCountry(
              code: '${item['code'] ?? ''}'.trim().toUpperCase(),
              name: '${item['name'] ?? ''}'.trim(),
            ),
      ].where((item) => item.code.length == 2 && item.name.isNotEmpty).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return next.isEmpty ? null : next;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> _fetchLaravelStates(String iso) async {
    try {
      final response = await _http
          .get(
            Uri.parse('$_apiBase/geography/countries/$iso/states'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final data = _envelopeData(response.body);
      if (data is! List) return null;
      return [
        for (final item in data)
          if (item is Map) '${item['name'] ?? ''}'.trim(),
      ].where((name) => name.isNotEmpty).toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> _fetchLaravelLocalities(String iso, String state) async {
    try {
      final encodedState = Uri.encodeComponent(state);
      final response = await _http
          .get(
            Uri.parse(
              '$_apiBase/geography/countries/$iso/states/$encodedState/localities',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final data = _envelopeData(response.body);
      if (data is! List) return null;
      return [
        for (final item in data)
          if (item is Map) '${item['name'] ?? ''}'.trim(),
      ].where((name) => name.isNotEmpty).toList();
    } catch (_) {
      return null;
    }
  }

  Object? _envelopeData(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map && decoded['data'] != null) return decoded['data'];
    return decoded;
  }
}

final class GeoCountry {
  const GeoCountry({
    required this.code,
    required this.name,
    this.flag,
  });

  final String code;
  final String name;
  final String? flag;

  String get label => flag == null || flag!.isEmpty ? name : '$flag $name';
}

final class GeoSelectOption {
  const GeoSelectOption({
    required this.value,
    required this.label,
    this.meta,
  });

  final String value;
  final String label;
  final String? meta;
}

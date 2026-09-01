import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// Mission catalogue + admin soul/mentor client.
///
/// Public (no auth):
/// - GET /mission/crusades
/// - GET /mission/crusades/{ulid}
/// - GET /mission/locations
///
/// Admin (bearer + device + X-Scope-* + recent MFA):
/// - GET /admin/mission/souls
/// - POST /admin/mission/crusades/{crusade}/souls
/// - POST /admin/mission/souls/{soul}/mentor-assignment
/// - POST /admin/mission/souls/{soul}/follow-ups
/// - POST /admin/mission/souls/{soul}/follow-up-completion
///
/// Not exposed: GET soul-by-id, team roster, partners.
final class HttpMissionRepository
    with TransportRepositoryHelpers
    implements MissionRepository {
  HttpMissionRepository({
    String? baseUrl,
    http.Client? httpClient,
    ApiTransport? transport,
  })  : baseUrl = resolveFhcApiUrl(override: baseUrl),
        _http = httpClient ?? http.Client(),
        _transport = transport;

  final String baseUrl;
  final http.Client _http;
  final ApiTransport? _transport;

  Uri get _root => Uri.parse(baseUrl.replaceAll(RegExp(r'/$'), ''));

  bool get adminOpsBound => _transport != null;

  /// GET /mission/crusades
  @override
  Future<AppResult<List<JsonObject>>> getCrusades(JsonObject filters) async {
    return _getPublicList('/mission/crusades', filters);
  }

  /// GET /mission/crusades/{ulid}
  Future<AppResult<JsonObject>> getCrusade(String ulid) async {
    final id = ulid.trim();
    if (!_looksLikeUlid(id)) {
      return const AppError(
        ValidationFailure('A valid crusade ULID is required.'),
      );
    }

    try {
      final uri = _root.replace(path: '${_root.path}/mission/crusades/$id');
      final response = await _http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      return _mapObjectResponse(response, notFoundMessage: 'Crusade not found.');
    } on AppFailure catch (failure) {
      return AppError(failure);
    } catch (error) {
      return AppError(
        NetworkFailure(
          'Unable to reach the mission catalogue.',
          cause: error,
        ),
      );
    }
  }

  /// GET /mission/locations
  Future<AppResult<List<JsonObject>>> getLocations(JsonObject filters) async {
    return _getPublicList('/mission/locations', filters);
  }

  /// GET /admin/mission/souls
  Future<AppResult<List<JsonObject>>> listSouls([JsonObject filters = const {}]) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(const AppError(_adminTransportRequired));
    }

    final query = <String, Object?>{};
    final scopeHeaders = <String, String>{};
    for (final entry in filters.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty) continue;
      if (key == 'scope_type') {
        scopeHeaders['X-Scope-Type'] = text;
        continue;
      }
      if (key == 'scope_id') {
        scopeHeaders['X-Scope-ID'] = text;
        continue;
      }
      if (key == 'filter.status' || key == 'filter.search') {
        query[key] = text;
        continue;
      }
      if (key == 'status') {
        query['filter.status'] = text;
        continue;
      }
      if (key == 'search') {
        query['filter.search'] = text;
        continue;
      }
      if (key == 'page' || key == 'per_page') {
        query[key] = text;
      }
    }
    _ensureScopeHeaders(scopeHeaders);

    return sendList(
      transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/admin/mission/souls',
        query: query,
        headers: scopeHeaders,
      ),
    );
  }

  /// GET /admin/mission/souls/{id}
  @override
  Future<AppResult<JsonObject>> getSoul(String id) async {
    final soulId = id.trim();
    if (!_looksLikeUlid(soulId)) {
      return const AppError(
        ValidationFailure('A valid soul journey ULID is required.'),
      );
    }
    final transport = _transport;
    if (transport == null) {
      return const AppError(_adminTransportRequired);
    }
    final scopeHeaders = <String, String>{};
    _ensureScopeHeaders(scopeHeaders);
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/admin/mission/souls/${encodeId(soulId)}',
        headers: scopeHeaders,
      ),
    );
  }

  /// POST /user/mission/invitations
  Future<AppResult<JsonObject>> submitInvitation(JsonObject payload) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(_adminTransportRequired);
    }
    final title = _stringField(payload, 'title');
    if (title == null) {
      return const AppError(ValidationFailure('A title is required.'));
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/mission/invitations',
        body: {
          'title': title,
          if (_stringField(payload, 'type') != null) 'type': _stringField(payload, 'type'),
          if (_stringField(payload, 'start') != null) 'start': _stringField(payload, 'start'),
          if (_stringField(payload, 'location') != null) 'location': _stringField(payload, 'location'),
          if (_stringField(payload, 'details') != null) 'details': _stringField(payload, 'details'),
          'idempotency_key': _stringField(payload, 'idempotency_key') ??
              newIdempotencyKey('mission-invite'),
        },
        idempotencyKey: _stringField(payload, 'idempotency_key') ??
            newIdempotencyKey('mission-invite'),
      ),
    );
  }

  /// POST /admin/mission/crusades/{crusade}/souls
  ///
  /// Required payload keys: `crusade_id`, plus either `person_id` or
  /// `given_name` + `family_name`. Optional: `middle_name`, `preferred_name`,
  /// `scope_type`, `scope_id` (default `global` / `platform`).
  @override
  Future<AppResult<JsonObject>> createSoul(JsonObject soul) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(_adminTransportRequired);
    }

    final crusadeId = _stringField(soul, 'crusade_id');
    if (crusadeId == null || !_looksLikeUlid(crusadeId)) {
      return const AppError(
        ValidationFailure(
          'createSoul requires a valid crusade_id ULID for POST /admin/mission/crusades/{crusade}/souls.',
        ),
      );
    }

    final personId = _stringField(soul, 'person_id');
    final givenName = _stringField(soul, 'given_name');
    final familyName = _stringField(soul, 'family_name');
    if (personId != null && !_looksLikeUlid(personId)) {
      return const AppError(
        ValidationFailure('person_id must be a valid ULID when provided.'),
      );
    }
    if (personId == null &&
        (givenName == null ||
            givenName.isEmpty ||
            familyName == null ||
            familyName.isEmpty)) {
      return const AppError(
        ValidationFailure(
          'Capture requires person_id or both given_name and family_name.',
        ),
      );
    }

    final body = <String, Object?>{
      if (personId != null) 'person_id': personId,
      if (givenName != null) 'given_name': givenName,
      if (familyName != null) 'family_name': familyName,
      if (_stringField(soul, 'middle_name') != null)
        'middle_name': _stringField(soul, 'middle_name'),
      if (_stringField(soul, 'preferred_name') != null)
        'preferred_name': _stringField(soul, 'preferred_name'),
    };

    final scopeHeaders = <String, String>{
      if (_stringField(soul, 'scope_type') != null)
        'X-Scope-Type': _stringField(soul, 'scope_type')!,
      if (_stringField(soul, 'scope_id') != null)
        'X-Scope-ID': _stringField(soul, 'scope_id')!,
    };
    _ensureScopeHeaders(scopeHeaders);

    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/admin/mission/crusades/${encodeId(crusadeId)}/souls',
        body: body,
        headers: scopeHeaders,
        idempotencyKey: newIdempotencyKey('capture-soul'),
      ),
    );
  }

  /// POST /admin/mission/souls/{soul}/mentor-assignment
  ///
  /// [mentorId] is the Laravel `mission_team_assignment_id` ULID (not a person
  /// display name). Optional [scopeType]/[scopeId] default to global/platform.
  @override
  Future<AppResult<void>> assignMentor(
    String soulId,
    String mentorId, {
    String? scopeType,
    String? scopeId,
  }) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(_adminTransportRequired);
    }

    final soul = soulId.trim();
    final teamAssignmentId = mentorId.trim();
    if (!_looksLikeUlid(soul)) {
      return const AppError(
        ValidationFailure('A valid soul journey ULID is required.'),
      );
    }
    if (!_looksLikeUlid(teamAssignmentId)) {
      return const AppError(
        ValidationFailure(
          'assignMentor requires a mission_team_assignment_id ULID (not a display name).',
        ),
      );
    }

    final scopeHeaders = <String, String>{
      if (scopeType != null && scopeType.trim().isNotEmpty)
        'X-Scope-Type': scopeType.trim(),
      if (scopeId != null && scopeId.trim().isNotEmpty)
        'X-Scope-ID': scopeId.trim(),
    };
    _ensureScopeHeaders(scopeHeaders);

    return sendVoid(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/admin/mission/souls/${encodeId(soul)}/mentor-assignment',
        body: {'mission_team_assignment_id': teamAssignmentId},
        headers: scopeHeaders,
        idempotencyKey: newIdempotencyKey('assign-mentor'),
      ),
    );
  }

  /// POST /admin/mission/souls/{soul}/follow-ups
  ///
  /// Required [body] keys: `mentor_assignment_id`, `channel_code`,
  /// `outcome_code`, `occurred_at`. Optional: `scope_type`, `scope_id`
  /// (default `global` / `platform`).
  @override
  Future<AppResult<JsonObject>> recordFollowUp(
    String soulId,
    JsonObject body,
  ) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(_adminTransportRequired);
    }

    final soul = soulId.trim();
    if (!_looksLikeUlid(soul)) {
      return const AppError(
        ValidationFailure('A valid soul journey ULID is required.'),
      );
    }

    final mentorAssignmentId = _stringField(body, 'mentor_assignment_id');
    final channelCode = _stringField(body, 'channel_code');
    final outcomeCode = _stringField(body, 'outcome_code');
    final occurredAt = _stringField(body, 'occurred_at');
    if (mentorAssignmentId == null || !_looksLikeUlid(mentorAssignmentId)) {
      return const AppError(
        ValidationFailure(
          'recordFollowUp requires a mentor_assignment_id ULID.',
        ),
      );
    }
    if (channelCode == null ||
        outcomeCode == null ||
        occurredAt == null) {
      return const AppError(
        ValidationFailure(
          'recordFollowUp requires channel_code, outcome_code, and occurred_at.',
        ),
      );
    }

    final scopeHeaders = <String, String>{
      if (_stringField(body, 'scope_type') != null)
        'X-Scope-Type': _stringField(body, 'scope_type')!,
      if (_stringField(body, 'scope_id') != null)
        'X-Scope-ID': _stringField(body, 'scope_id')!,
    };
    _ensureScopeHeaders(scopeHeaders);

    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/admin/mission/souls/${encodeId(soul)}/follow-ups',
        body: {
          'mentor_assignment_id': mentorAssignmentId,
          'channel_code': channelCode,
          'outcome_code': outcomeCode,
          'occurred_at': occurredAt,
        },
        headers: scopeHeaders,
        idempotencyKey: newIdempotencyKey('follow-up'),
      ),
    );
  }

  /// POST /admin/mission/souls/{soul}/follow-up-completion
  ///
  /// [body] must include `reason_code`. Optional: `scope_type`, `scope_id`.
  @override
  Future<AppResult<JsonObject>> completeFollowUp(
    String soulId, [
    JsonObject body = const {},
  ]) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(_adminTransportRequired);
    }

    final soul = soulId.trim();
    if (!_looksLikeUlid(soul)) {
      return const AppError(
        ValidationFailure('A valid soul journey ULID is required.'),
      );
    }

    final reasonCode = _stringField(body, 'reason_code');
    if (reasonCode == null) {
      return const AppError(
        ValidationFailure('completeFollowUp requires reason_code.'),
      );
    }

    final scopeHeaders = <String, String>{
      if (_stringField(body, 'scope_type') != null)
        'X-Scope-Type': _stringField(body, 'scope_type')!,
      if (_stringField(body, 'scope_id') != null)
        'X-Scope-ID': _stringField(body, 'scope_id')!,
    };
    _ensureScopeHeaders(scopeHeaders);

    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/admin/mission/souls/${encodeId(soul)}/follow-up-completion',
        body: {'reason_code': reasonCode},
        headers: scopeHeaders,
      ),
    );
  }

  Future<AppResult<List<JsonObject>>> _getPublicList(
    String path,
    JsonObject filters,
  ) async {
    final query = <String, Object?>{};
    for (final entry in filters.entries) {
      final value = entry.value;
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty) continue;
      query[entry.key] = text;
    }

    final transport = _transport;
    if (transport != null) {
      return sendList(
        transport,
        ApiRequest(
          method: ApiMethod.get,
          path: path,
          query: query,
          skipAuth: true,
        ),
      );
    }

    try {
      final uri = _root.replace(
        path: '${_root.path}$path',
        queryParameters: {
          for (final entry in query.entries) entry.key: '${entry.value}',
        },
      );
      final response = await _http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      return _mapListResponse(response);
    } on AppFailure catch (failure) {
      return AppError(failure);
    } catch (error) {
      return AppError(
        NetworkFailure(
          'Unable to reach the mission catalogue.',
          cause: error,
        ),
      );
    }
  }

  AppResult<List<JsonObject>> _mapListResponse(http.Response response) {
    final failure = _failureForStatus(response);
    if (failure != null) return AppError(failure);

    final body = _decodeBody(response.body);
    final data = body['data'];
    if (data is! List) {
      return const AppError(
        ServerFailure('Mission catalogue returned an unexpected payload.'),
      );
    }

    return AppSuccess([
      for (final item in data)
        if (item is Map<String, dynamic>)
          Map<String, Object?>.from(item)
        else if (item is Map)
          Map<String, Object?>.from(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
    ]);
  }

  AppResult<JsonObject> _mapObjectResponse(
    http.Response response, {
    required String notFoundMessage,
  }) {
    final failure = _failureForStatus(
      response,
      notFoundMessage: notFoundMessage,
    );
    if (failure != null) return AppError(failure);

    final body = _decodeBody(response.body);
    final data = body['data'];
    if (data is! Map) {
      return const AppError(
        ServerFailure('Mission catalogue returned an unexpected payload.'),
      );
    }

    return AppSuccess(
      Map<String, Object?>.from(
        data.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  AppFailure? _failureForStatus(
    http.Response response, {
    String notFoundMessage = 'Resource not found.',
  }) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) return null;

    final body = _tryDecodeBody(response.body);
    final error = body?['error'];
    final message = error is Map
        ? (error['message'] as String?)?.trim()
        : null;

    return switch (code) {
      401 => UnauthorizedFailure(message ?? 'Sign in required.'),
      403 => ForbiddenFailure(message ?? 'Access denied.'),
      404 => NotFoundFailure(message ?? notFoundMessage),
      409 => ConflictFailure(message ?? 'Request conflict.'),
      422 => ValidationFailure(
          message ?? 'The mission catalogue request was invalid.',
        ),
      429 => RateLimitFailure(
          message ?? 'Too many requests. Please wait and try again.',
        ),
      _ when code >= 500 => ServerFailure(
          message ?? 'Mission catalogue is temporarily unavailable.',
        ),
      _ => UnknownFailure(
          message ?? 'Unexpected mission catalogue response ($code).',
        ),
    };
  }

  Map<String, dynamic> _decodeBody(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return Map<String, dynamic>.from(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    throw const FormatException('Expected a JSON object envelope.');
  }

  Map<String, dynamic>? _tryDecodeBody(String raw) {
    try {
      return _decodeBody(raw);
    } catch (_) {
      return null;
    }
  }

  static void _ensureScopeHeaders(Map<String, String> headers) {
    headers.putIfAbsent('X-Scope-Type', () => 'global');
    headers.putIfAbsent('X-Scope-ID', () => 'platform');
  }

  static String? _stringField(JsonObject source, String key) {
    final value = source[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool _looksLikeUlid(String value) =>
      RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$', caseSensitive: false).hasMatch(value);
}

const IntegrationUnavailableFailure _adminTransportRequired =
    IntegrationUnavailableFailure(
  'Admin mission soul/mentor operations require an authenticated API transport (bearer, device binding, scope headers, recent MFA).',
);

/// Shared copy for UI when a mission admin mutation cannot run.
const String missionSoulOpsUnavailableAction =
    'Soul capture, mentor assignment, or follow-up';

String? missionCrusadeIdFromRoute(String? routeName) {
  if (routeName == null || routeName.isEmpty) return null;
  final match = RegExp(
    r'^/mission/crusade/([0-9A-HJKMNP-TV-Z]{26})/?$',
    caseSensitive: false,
  ).firstMatch(routeName);
  return match?.group(1);
}

String? missionSoulIdFromRoute(String? routeName) {
  if (routeName == null || routeName.isEmpty) return null;
  final match = RegExp(
    r'^/mission/soul(?:s/profile)?/([0-9A-HJKMNP-TV-Z]{26})/?$',
    caseSensitive: false,
  ).firstMatch(routeName);
  return match?.group(1);
}

bool looksLikeMissionUlid(String? value) {
  if (value == null) return false;
  return RegExp(
    r'^[0-9A-HJKMNP-TV-Z]{26}$',
    caseSensitive: false,
  ).hasMatch(value.trim());
}

String formatMissionDateRange({
  String? startsAt,
  String? endsAt,
}) {
  final start = _formatMissionDate(startsAt);
  final end = _formatMissionDate(endsAt);
  if (start == null && end == null) return 'Dates to be announced';
  if (start != null && end != null && start != end) return '$start – $end';
  return start ?? end!;
}

String formatMissionLocation(JsonObject? location) {
  if (location == null) return 'Location to be announced';
  final name = (location['name'] as String?)?.trim();
  final locality = (location['locality'] as String?)?.trim();
  final country = location['country'];
  final countryName = country is Map
      ? (country['name'] as String?)?.trim()
      : null;

  final parts = <String>[
    if (name != null && name.isNotEmpty) name,
    if (locality != null && locality.isNotEmpty) locality,
    if (countryName != null && countryName.isNotEmpty) countryName,
  ];
  if (parts.isEmpty) return 'Location to be announced';
  if (parts.length == 1) return parts.first;
  if (parts.length == 2) return '${parts[0]}, ${parts[1]}';
  return '${parts[0]} • ${parts[1]}, ${parts[2]}';
}

String? _formatMissionDate(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(iso.trim());
  if (parsed == null) return iso.trim();
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = parsed.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

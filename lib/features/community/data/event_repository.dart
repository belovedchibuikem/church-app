import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// Public catalogue + authenticated registration / feedback client.
///
/// - List/detail: `GET /events`, `GET /events/{ulid}` (public)
/// - Register: `POST /user/events/{event}/registrations` when [transport] is set
/// - Tickets: `GET /user/events/registrations/{registration}` when [transport] is set
/// - Feedback: `POST /user/events/feedback` when [transport] is set
final class RemoteEventRepository
    with TransportRepositoryHelpers
    implements EventRepository {
  RemoteEventRepository({
    String? baseUrl,
    http.Client? httpClient,
    ApiTransport? transport,
  })  : baseUrl = resolveFhcApiUrl(override: baseUrl),
        _http = httpClient ?? http.Client(),
        _transport = transport;

  final String baseUrl;
  final http.Client _http;
  final ApiTransport? _transport;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  @override
  Future<AppResult<List<JsonObject>>> list(JsonObject filters) async {
    final query = <String, String>{};
    for (final entry in filters.entries) {
      final value = entry.value;
      if (value == null) continue;
      query[entry.key] = '$value';
    }
    query.putIfAbsent('per_page', () => '50');
    query.putIfAbsent('sort', () => 'starts_at');
    return _getList(_uri('/events', query));
  }

  @override
  Future<AppResult<JsonObject>> get(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Event id is required.'));
    }
    return _getObject(_uri('/events/${Uri.encodeComponent(trimmed)}'));
  }

  @override
  Future<AppResult<JsonObject>> register(
    String eventId,
    JsonObject attendee,
  ) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Event registration requires an authenticated API transport. '
          'No registration was submitted.',
        ),
      );
    }

    final trimmed = eventId.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Event id is required.'));
    }

    final key = (attendee['idempotency_key'] as String?)?.trim().isNotEmpty ==
            true
        ? attendee['idempotency_key'] as String
        : newIdempotencyKey('event-reg');

    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/events/${encodeId(trimmed)}/registrations',
        body: <String, Object?>{'idempotency_key': key},
        idempotencyKey: key,
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> getTicket(String registrationId) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Event tickets require an authenticated API transport. '
          'No ticket was loaded.',
        ),
      );
    }

    final trimmed = registrationId.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Registration id is required.'));
    }

    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/events/registrations/${encodeId(trimmed)}',
      ),
    );
  }

  /// `GET /user/events/registrations?filter[when]=upcoming|past|all`
  @override
  Future<AppResult<List<JsonObject>>> listMyRegistrations({
    String when = 'all',
  }) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Event registrations require an authenticated API transport. '
          'No registration list is shown.',
        ),
      );
    }

    final filter = when.trim().isEmpty ? 'all' : when.trim().toLowerCase();
    return sendList(
      transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/events/registrations',
        query: {'filter[when]': filter},
      ),
    );
  }

  /// POST /user/events/feedback {registration_id, rating}
  @override
  Future<AppResult<JsonObject>> recordFeedback(
    String registrationId,
    int rating,
  ) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Event feedback requires an authenticated API transport. '
          'No rating was submitted.',
        ),
      );
    }

    final trimmed = registrationId.trim();
    if (trimmed.isEmpty) {
      return const AppError(
        ValidationFailure('registration_id is required.'),
      );
    }
    if (rating < 1 || rating > 5) {
      return const AppError(
        ValidationFailure('rating must be an integer from 1 to 5.'),
      );
    }

    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/events/feedback',
        body: <String, Object?>{
          'registration_id': trimmed,
          'rating': rating,
        },
      ),
    );
  }

  Future<AppResult<List<JsonObject>>> _getList(Uri uri) async {
    try {
      final response = await _http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      final decoded = _decodeBody(response.body);
      if (decoded == null) {
        return AppError(
          ServerFailure('Invalid events response (${response.statusCode}).'),
        );
      }
      final failure = _failureFromEnvelope(response.statusCode, decoded);
      if (failure != null) return AppError(failure);

      final data = decoded['data'];
      if (data is! List) {
        return const AppError(ServerFailure('Events envelope missing data[].'));
      }
      return AppSuccess(
        data
            .whereType<Map>()
            .map((item) => _asJsonObject(Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to reach events API.', cause: error),
      );
    } catch (error) {
      return AppError(UnknownFailure('Events request failed.', cause: error));
    }
  }

  Future<AppResult<JsonObject>> _getObject(Uri uri) async {
    try {
      final response = await _http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      final decoded = _decodeBody(response.body);
      if (decoded == null) {
        return AppError(
          ServerFailure('Invalid event response (${response.statusCode}).'),
        );
      }
      final failure = _failureFromEnvelope(response.statusCode, decoded);
      if (failure != null) return AppError(failure);

      final data = decoded['data'];
      if (data is! Map) {
        return const AppError(ServerFailure('Event envelope missing data.'));
      }
      return AppSuccess(_asJsonObject(Map<String, dynamic>.from(data)));
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to reach events API.', cause: error),
      );
    } catch (error) {
      return AppError(UnknownFailure('Event request failed.', cause: error));
    }
  }
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

JsonObject _asJsonObject(Map<String, dynamic> source) {
  return source.map((key, value) => MapEntry(key, value as Object?));
}

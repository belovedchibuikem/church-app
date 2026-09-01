import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

final class HttpBibleRepository
    with TransportRepositoryHelpers
    implements BibleRepository {
  HttpBibleRepository({
    String? baseUrl,
    http.Client? httpClient,
    ApiTransport? transport,
  }) : baseUrl = resolveFhcApiUrl(override: baseUrl),
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

  Map<String, Object?> _versionQueryObject(String? version) {
    final id = version?.trim() ?? '';
    if (id.isEmpty) return const {};
    return {'version': id};
  }

  Future<AppResult<JsonObject>> _publicObject(
    String path, [
    Map<String, Object?> query = const {},
  ]) {
    final transport = _transport;
    if (transport != null) {
      return sendObject(
        transport,
        ApiRequest(
          method: ApiMethod.get,
          path: path,
          query: query,
          skipAuth: true,
        ),
      );
    }
    return _getObject(
      _uri(
        path,
        {
          for (final entry in query.entries)
            if (entry.value != null) entry.key: '${entry.value}',
        },
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> books({String? version}) =>
      _publicObject('/bible/books', _versionQueryObject(version));

  @override
  Future<AppResult<JsonObject>> chapter(
    String book,
    int chapter, {
    String? version,
  }) {
    return _publicObject(
      '/bible/books/${Uri.encodeComponent(book)}/chapters/$chapter',
      _versionQueryObject(version),
    );
  }

  @override
  Future<AppResult<JsonObject>> search(String query, {String? version}) {
    return _publicObject('/bible/search', {
      'q': query,
      'limit': '30',
      ..._versionQueryObject(version),
    });
  }

  @override
  Future<AppResult<List<JsonObject>>> plans() async {
    final transport = _transport;
    if (transport != null) {
      return sendList(
        transport,
        const ApiRequest(
          method: ApiMethod.get,
          path: '/bible/plans',
          skipAuth: true,
        ),
      );
    }
    final result = await _getRaw(_uri('/bible/plans'));
    return switch (result) {
      AppSuccess(:final value) => _asList(value),
      AppError(:final failure) => AppError(failure),
    };
  }

  @override
  Future<AppResult<JsonObject>> progress() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(
        const AppError(
          IntegrationUnavailableFailure(
            'Bible plans require a signed-in session.',
          ),
        ),
      );
    }
    return sendObject(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/bible/progress'),
    );
  }

  @override
  Future<AppResult<JsonObject>> enroll(String planCode, {int? durationDays}) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(
        const AppError(
          IntegrationUnavailableFailure(
            'Starting a Bible plan requires a signed-in session.',
          ),
        ),
      );
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/bible/enrollments',
        body: {
          if (planCode.trim().isNotEmpty) 'plan_code': planCode.trim(),
          if (durationDays != null) 'duration_days': durationDays,
        },
        idempotencyKey: newIdempotencyKey('bible-enroll'),
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> completeDay(String enrollmentId, int day) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(
        const AppError(
          IntegrationUnavailableFailure(
            'Completing a Bible day requires a signed-in session.',
          ),
        ),
      );
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path:
            '/user/bible/enrollments/${Uri.encodeComponent(enrollmentId)}/days/$day/complete',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> savePosition(String book, int chapter) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(const AppSuccess(<String, Object?>{}));
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.put,
        path: '/user/bible/position',
        body: {'book': book, 'chapter': chapter},
      ),
    );
  }

  Future<AppResult<Object?>> _getRaw(Uri uri) async {
    try {
      final response = await _http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      final decoded = _decodeBody(response.body);
      if (decoded == null) {
        return AppError(
          ServerFailure('Invalid Bible response (${response.statusCode}).'),
        );
      }
      final failure = _failureFromEnvelope(response.statusCode, decoded);
      if (failure != null) return AppError(failure);
      return AppSuccess(decoded['data']);
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to reach the Bible API.', cause: error),
      );
    } catch (error) {
      return AppError(UnknownFailure('Bible request failed.', cause: error));
    }
  }

  Future<AppResult<JsonObject>> _getObject(Uri uri) async {
    final result = await _getRaw(uri);
    return switch (result) {
      AppSuccess(:final value) when value is Map => AppSuccess(
        _asJsonObject(Map<String, dynamic>.from(value)),
      ),
      AppSuccess() => const AppError(
        ServerFailure('Bible envelope missing data.'),
      ),
      AppError(:final failure) => AppError(failure),
    };
  }

  AppResult<List<JsonObject>> _asList(Object? data) {
    if (data is List) {
      return AppSuccess([
        for (final item in data)
          if (item is Map) _asJsonObject(Map<String, dynamic>.from(item)),
      ]);
    }
    return const AppError(ServerFailure('Expected a list of Bible plans.'));
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

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

class ChurchLocationSummary {
  const ChurchLocationSummary({
    required this.id,
    required this.name,
    this.locality,
    this.timezone,
    this.countryCode,
    this.countryName,
    this.administrativeUnitId,
    this.administrativeUnitName,
  });

  final String id;
  final String name;
  final String? locality;
  final String? timezone;
  final String? countryCode;
  final String? countryName;
  final String? administrativeUnitId;
  final String? administrativeUnitName;

  String get placeLabel {
    final parts = <String>[
      if (locality != null && locality!.trim().isNotEmpty) locality!.trim(),
      if (countryName != null && countryName!.trim().isNotEmpty)
        countryName!.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return name;
  }

  factory ChurchLocationSummary.fromJson(Map<String, dynamic> json) {
    final country = json['country'] as Map<String, dynamic>? ?? const {};
    final unit =
        json['administrative_unit'] as Map<String, dynamic>? ?? const {};
    return ChurchLocationSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      locality: json['locality'] as String?,
      timezone: json['timezone'] as String?,
      countryCode: country['code'] as String?,
      countryName: country['name'] as String?,
      administrativeUnitId: unit['id'] as String?,
      administrativeUnitName: unit['name'] as String?,
    );
  }
}

class ChurchSummary {
  const ChurchSummary({
    required this.id,
    required this.name,
    required this.location,
    this.publishedAt,
  });

  final String id;
  final String name;
  final ChurchLocationSummary location;
  final String? publishedAt;

  factory ChurchSummary.fromJson(Map<String, dynamic> json) {
    final locationJson =
        json['location'] as Map<String, dynamic>? ?? const {};
    return ChurchSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: ChurchLocationSummary.fromJson(locationJson),
      publishedAt: json['published_at'] as String?,
    );
  }

  JsonObject toJson() => {
        'id': id,
        'name': name,
        'published_at': publishedAt,
        'location': {
          'id': location.id,
          'name': location.name,
          'locality': location.locality,
          'timezone': location.timezone,
          'country': {
            'code': location.countryCode,
            'name': location.countryName,
          },
          'administrative_unit': location.administrativeUnitId == null
              ? null
              : {
                  'id': location.administrativeUnitId,
                  'name': location.administrativeUnitName,
                },
        },
      };
}

class ChurchListPage {
  const ChurchListPage({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  final List<ChurchSummary> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
}

/// Public catalogue + authenticated membership client.
///
/// - List/detail: `GET /churches`, `GET /churches/{ulid}` (public)
/// - Membership: `POST /user/churches/{church}/memberships` when [transport] is set
final class ChurchRepositoryImpl
    with TransportRepositoryHelpers
    implements ChurchRepository {
  ChurchRepositoryImpl({
    String? baseUrl,
    http.Client? httpClient,
    ApiTransport? transport,
  })  : baseUrl = resolveFhcApiUrl(override: baseUrl),
        _http = httpClient ?? http.Client(),
        _transport = transport;

  final String baseUrl;
  final http.Client _http;
  final ApiTransport? _transport;

  Future<AppResult<ChurchListPage>> listChurches({
    String? name,
    String? country,
    String? administrativeUnitId,
    String sort = 'name',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final query = <String, String>{
        'sort': sort,
        'page': '$page',
        'per_page': '$perPage',
      };
      if (name != null && name.trim().isNotEmpty) {
        query['filter[name]'] = name.trim();
      }
      if (country != null && country.trim().isNotEmpty) {
        query['filter[country]'] = country.trim().toUpperCase();
      }
      if (administrativeUnitId != null &&
          administrativeUnitId.trim().isNotEmpty) {
        query['filter[administrative_unit]'] = administrativeUnitId.trim();
      }

      final uri = Uri.parse('$baseUrl/churches').replace(queryParameters: query);
      final response = await _http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      final failure = _mapError(response);
      if (failure != null) return AppError(failure);

      final body = _decodeBody(response.body);
      final data = body['data'] as Map<String, dynamic>? ?? const {};
      final itemsJson = data['items'] as List<dynamic>? ?? const [];
      final meta = body['meta'] as Map<String, dynamic>? ?? const {};
      final pagination =
          meta['pagination'] as Map<String, dynamic>? ?? const {};

      return AppSuccess(
        ChurchListPage(
          items: itemsJson
              .whereType<Map<String, dynamic>>()
              .map(ChurchSummary.fromJson)
              .where((c) => c.id.isNotEmpty)
              .toList(),
          currentPage: (pagination['current_page'] as num?)?.toInt() ?? page,
          perPage: (pagination['per_page'] as num?)?.toInt() ?? perPage,
          total: (pagination['total'] as num?)?.toInt() ?? itemsJson.length,
          lastPage: (pagination['last_page'] as num?)?.toInt() ?? 1,
        ),
      );
    } catch (error, stack) {
      debugPrint('ChurchRepository.listChurches: $error\n$stack');
      return AppError(NetworkFailure('Unable to load churches.', cause: error));
    }
  }

  Future<AppResult<ChurchSummary>> getChurchById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Church id is required.'));
    }

    try {
      final uri = Uri.parse('$baseUrl/churches/$trimmed');
      final response = await _http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      final failure = _mapError(response);
      if (failure != null) return AppError(failure);

      final body = _decodeBody(response.body);
      final data = body['data'] as Map<String, dynamic>? ?? const {};
      final church = ChurchSummary.fromJson(data);
      if (church.id.isEmpty) {
        return const AppError(ServerFailure('Church payload was incomplete.'));
      }
      return AppSuccess(church);
    } catch (error, stack) {
      debugPrint('ChurchRepository.getChurchById: $error\n$stack');
      return AppError(NetworkFailure('Unable to load church.', cause: error));
    }
  }

  @override
  Future<AppResult<List<JsonObject>>> searchChurches(JsonObject filters) async {
    final result = await listChurches(
      name: filters['name'] as String?,
      country: filters['country'] as String?,
      administrativeUnitId: filters['administrative_unit'] as String?,
      sort: (filters['sort'] as String?) ?? 'name',
      page: (filters['page'] as num?)?.toInt() ?? 1,
      perPage: (filters['per_page'] as num?)?.toInt() ?? 20,
    );
    return switch (result) {
      AppSuccess(:final value) =>
        AppSuccess(value.items.map((c) => c.toJson()).toList()),
      AppError(:final failure) => AppError(failure),
    };
  }

  @override
  Future<AppResult<JsonObject>> getChurch(String id) async {
    final result = await getChurchById(id);
    return switch (result) {
      AppSuccess(:final value) => AppSuccess(value.toJson()),
      AppError(:final failure) => AppError(failure),
    };
  }

  /// `POST /user/churches/{church}/memberships` (recent MFA). Optional body:
  /// `{home_church_id}`. 422 is mapped honestly (e.g. unlinked person).
  @override
  Future<AppResult<void>> requestMembership(String churchId) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Church membership requires an authenticated API transport. '
          'No membership request was submitted.',
        ),
      );
    }

    final trimmed = churchId.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Church id is required.'));
    }

    return sendVoid(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/churches/${encodeId(trimmed)}/memberships',
        body: const <String, Object?>{},
        idempotencyKey: newIdempotencyKey('church-mem'),
      ),
    );
  }

  /// `GET /user/memberships` — current person's church memberships.
  @override
  Future<AppResult<List<JsonObject>>> listMemberships() async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Memberships require an authenticated API transport. '
          'No membership list is shown.',
        ),
      );
    }
    return sendList(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/memberships'),
    );
  }

  AppResult<T> _needsTransport<T>(String feature) {
    return AppError(
      IntegrationUnavailableFailure(
        '$feature requires an authenticated API transport.',
      ),
    );
  }

  /// `GET /user/churches/{church}/members`
  @override
  Future<AppResult<List<JsonObject>>> listChurchMembers(String churchId) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('Church members'));
    }
    final trimmed = churchId.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Church id is required.')),
      );
    }
    return sendList(
      transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/churches/${encodeId(trimmed)}/members',
      ),
    );
  }

  /// `GET /user/groups`
  @override
  Future<AppResult<List<JsonObject>>> listGroups() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('Church groups'));
    }
    return sendList(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/groups'),
    );
  }

  /// `POST /user/groups/{id}/join`
  @override
  Future<AppResult<void>> joinGroup(String groupId) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('Joining a group'));
    }
    final trimmed = groupId.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Group id is required.')),
      );
    }
    return sendVoid(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/groups/${encodeId(trimmed)}/join',
        body: const <String, Object?>{},
        idempotencyKey: newIdempotencyKey('group-join'),
      ),
    );
  }

  /// `POST /user/groups/{id}/leave`
  @override
  Future<AppResult<void>> leaveGroup(String groupId) {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('Leaving a group'));
    }
    final trimmed = groupId.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Group id is required.')),
      );
    }
    return sendVoid(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/groups/${encodeId(trimmed)}/leave',
        body: const <String, Object?>{},
        idempotencyKey: newIdempotencyKey('group-leave'),
      ),
    );
  }

  /// `GET /user/announcements`
  @override
  Future<AppResult<List<JsonObject>>> listAnnouncements() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('Announcements'));
    }
    return sendList(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/announcements'),
    );
  }

  /// `GET /user/documents`
  @override
  Future<AppResult<List<JsonObject>>> listDocuments() {
    final transport = _transport;
    if (transport == null) {
      return Future.value(_needsTransport('Documents'));
    }
    return sendList(
      transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/documents'),
    );
  }

  Map<String, dynamic> _decodeBody(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return const {};
  }

  AppFailure? _mapError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return null;

    Map<String, dynamic> body = const {};
    try {
      body = _decodeBody(response.body);
    } catch (_) {}

    final error = body['error'] as Map<String, dynamic>? ?? const {};
    final message = (error['message'] as String?)?.trim();
    final details = error['details'] as Map<String, dynamic>? ?? const {};
    final fieldsRaw = details['fields'];
    final fields = <String, List<String>>{};
    if (fieldsRaw is Map) {
      for (final entry in fieldsRaw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is List) {
          fields[key] = value.map((e) => e.toString()).toList();
        } else if (value != null) {
          fields[key] = [value.toString()];
        }
      }
    }

    final fallback = message?.isNotEmpty == true
        ? message!
        : 'Request failed (${response.statusCode}).';

    return switch (response.statusCode) {
      401 => UnauthorizedFailure(fallback),
      403 => ForbiddenFailure(fallback),
      404 => NotFoundFailure(fallback),
      409 => ConflictFailure(fallback),
      422 => ValidationFailure(fallback, errors: fields),
      429 => RateLimitFailure(fallback),
      >= 500 => ServerFailure(fallback),
      _ => UnknownFailure(fallback),
    };
  }
}

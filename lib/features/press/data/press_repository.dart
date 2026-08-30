import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';
import '../../../core/l10n/locale_holder.dart';

/// Public catalogue + authenticated admin create / file upload.
///
/// [download] GETs `/press/publications/{id}/download` as a binary stream.
/// [uploadAdminFile] POSTs multipart to `/admin/platform/files`.
/// [createPublication] POSTs `/admin/press/publications` (optionally with
/// `content_file_asset_id` / `cover_file_asset_id` from [uploadAdminFile]).
final class RemotePressRepository
    with TransportRepositoryHelpers
    implements PressRepository {
  RemotePressRepository({
    String? baseUrl,
    http.Client? httpClient,
    ApiTransport? transport,
    SessionTokenStore? tokenStore,
  })  : baseUrl = resolveFhcApiUrl(override: baseUrl),
        _http = httpClient ?? http.Client(),
        _transport = transport,
        _tokenStore = tokenStore;

  final String baseUrl;
  final http.Client _http;
  final ApiTransport? _transport;
  final SessionTokenStore? _tokenStore;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  @override
  Future<AppResult<List<JsonObject>>> search(JsonObject filters) async {
    final query = <String, String>{};
    for (final entry in filters.entries) {
      final value = entry.value;
      if (value == null) continue;
      final key = entry.key;
      // OpenAPI uses filter[language], filter[category], filter[format].
      if (key == 'language' || key == 'category' || key == 'format') {
        query['filter[$key]'] = '$value';
      } else {
        query[key] = '$value';
      }
    }
    query.putIfAbsent('per_page', () => '50');
    query.putIfAbsent('sort', () => 'title');
    return _getList(_uri('/press/publications', query));
  }

  @override
  Future<AppResult<JsonObject>> getPublication(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Publication id is required.'));
    }
    return _getObject(
      _uri('/press/publications/${Uri.encodeComponent(trimmed)}'),
    );
  }

  @override
  Future<AppResult<JsonObject>> download(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Publication id is required.'));
    }

    try {
      final response = await _http.get(
        _uri('/press/publications/${Uri.encodeComponent(trimmed)}/download'),
        headers: const {'Accept': '*/*'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentType = response.headers['content-type'] ??
            'application/octet-stream';
        final filename = _filenameFromDisposition(
              response.headers['content-disposition'],
            ) ??
            'publication';
        return AppSuccess(<String, Object?>{
          'bytes': response.bodyBytes,
          'content_type': contentType,
          'filename': filename,
        });
      }

      final decoded = _decodeBody(response.body);
      if (decoded != null) {
        final failure = _failureFromEnvelope(response.statusCode, decoded);
        if (failure != null) return AppError(failure);
      }

      if (response.statusCode == 404) {
        return const AppError(
          NotFoundFailure('Publication download was not found.'),
        );
      }

      return AppError(
        ServerFailure('Press download failed (${response.statusCode}).'),
      );
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to reach press API.', cause: error),
      );
    } catch (error) {
      return AppError(
        UnknownFailure('Press download request failed.', cause: error),
      );
    }
  }

  /// `POST /admin/platform/files` multipart — returns file asset public id.
  @override
  Future<AppResult<JsonObject>> uploadAdminFile({
    required List<int> bytes,
    required String filename,
    String purpose = 'press_content',
    String classification = 'internal',
  }) async {
    final tokenStore = _tokenStore;
    if (tokenStore == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Press file upload requires a session token store.',
        ),
      );
    }
    if (bytes.isEmpty) {
      return const AppError(ValidationFailure('File bytes are required.'));
    }
    final safeName = filename.trim().isEmpty ? 'upload.bin' : filename.trim();

    try {
      final access = await tokenStore.readAccessToken();
      final deviceId = await tokenStore.readDeviceIdentifier();
      if (access == null || access.isEmpty) {
        return const AppError(UnauthorizedFailure('Sign in required.'));
      }

      final uri = _uri('/admin/platform/files');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        'Accept-Language': FhcLocaleHolder.languageCode,
        'X-Client-Channel': 'mobile',
        'Authorization': 'Bearer $access',
        if (deviceId != null && deviceId.isNotEmpty)
          'X-Device-Identifier': deviceId,
        'Idempotency-Key': newIdempotencyKey('press-file'),
        'X-Scope-Type': 'global',
        'X-Scope-ID': 'platform',
      });
      request.fields['purpose'] = purpose;
      request.fields['classification'] = classification;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: safeName,
        ),
      );

      final streamed = await _http.send(request).timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamed);
      final decoded = _decodeBody(response.body);
      if (decoded == null) {
        return AppError(
          ServerFailure(
            'Invalid file upload response (${response.statusCode}).',
          ),
        );
      }
      final failure = _failureFromEnvelope(response.statusCode, decoded);
      if (failure != null) return AppError(failure);

      final data = decoded['data'];
      if (data is! Map) {
        return const AppError(
          ServerFailure('File upload envelope missing data.'),
        );
      }
      return AppSuccess(_asJsonObject(Map<String, dynamic>.from(data)));
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to upload press file.', cause: error),
      );
    } catch (error) {
      return AppError(
        UploadFailure('Press file upload failed.', cause: error),
      );
    }
  }

  /// `POST /admin/press/publications` — may include file asset ids.
  @override
  Future<AppResult<JsonObject>> createPublication(JsonObject body) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Press admin create requires an authenticated API transport.',
        ),
      );
    }
    final title = '${body['title'] ?? ''}'.trim();
    final format = '${body['format'] ?? ''}'.trim().toLowerCase();
    if (title.isEmpty) {
      return const AppError(ValidationFailure('Title is required.'));
    }
    if (format.isEmpty) {
      return const AppError(ValidationFailure('Format is required.'));
    }
    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/admin/press/publications',
        headers: const {
          'X-Scope-Type': 'global',
          'X-Scope-ID': 'platform',
        },
        body: {
          'publisher_name': 'Family House Press',
          'language_code': 'en',
          ...body,
          'title': title,
          'format': format,
        },
        idempotencyKey: newIdempotencyKey('press-pub'),
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
          ServerFailure(
            'Invalid press publications response (${response.statusCode}).',
          ),
        );
      }
      final failure = _failureFromEnvelope(response.statusCode, decoded);
      if (failure != null) return AppError(failure);

      final data = decoded['data'];
      if (data is! List) {
        return const AppError(
          ServerFailure('Press publications envelope missing data[].'),
        );
      }
      return AppSuccess(
        data
            .whereType<Map>()
            .map((item) => _asJsonObject(Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to reach press API.', cause: error),
      );
    } catch (error) {
      return AppError(UnknownFailure('Press list request failed.', cause: error));
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
          ServerFailure(
            'Invalid press publication response (${response.statusCode}).',
          ),
        );
      }
      final failure = _failureFromEnvelope(response.statusCode, decoded);
      if (failure != null) return AppError(failure);

      final data = decoded['data'];
      if (data is! Map) {
        return const AppError(
          ServerFailure('Press publication envelope missing data.'),
        );
      }
      return AppSuccess(_asJsonObject(Map<String, dynamic>.from(data)));
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to reach press API.', cause: error),
      );
    } catch (error) {
      return AppError(
        UnknownFailure('Press publication request failed.', cause: error),
      );
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

String? _filenameFromDisposition(String? header) {
  if (header == null || header.trim().isEmpty) return null;

  final utf8Name = RegExp(
    r"filename\*\s*=\s*UTF-8''([^;]+)",
    caseSensitive: false,
  ).firstMatch(header);
  if (utf8Name != null) {
    try {
      final decoded = Uri.decodeComponent(utf8Name.group(1)!.trim());
      if (decoded.isNotEmpty) return decoded;
    } catch (_) {
      // Fall through to the plain filename parameter.
    }
  }

  final quoted = RegExp(
    r'filename\s*=\s*"([^"]*)"',
    caseSensitive: false,
  ).firstMatch(header);
  if (quoted != null) {
    final value = quoted.group(1)!.trim();
    if (value.isNotEmpty) return value;
  }

  final plain = RegExp(
    r'filename\s*=\s*([^;]+)',
    caseSensitive: false,
  ).firstMatch(header);
  if (plain != null) {
    final value = plain.group(1)!.trim().replaceAll('"', '');
    if (value.isNotEmpty) return value;
  }

  return null;
}

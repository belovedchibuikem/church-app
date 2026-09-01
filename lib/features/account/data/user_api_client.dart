import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// Thin Laravel `/user/*` client. Always sends Bearer + `X-Device-Identifier`.
final class UserApiClient {
  UserApiClient({
    required this.tokenStore,
    String? baseUrl,
    http.Client? httpClient,
    ApiTransport? transport,
  }) : baseUrl = resolveFhcApiUrl(override: baseUrl),
       _http = httpClient ?? http.Client(),
       _transport = transport;

  final SessionTokenStore tokenStore;
  final String baseUrl;
  final http.Client _http;
  final ApiTransport? _transport;

  Future<AppResult<JsonObject>> getObject(String path) async {
    final raw = await _send(ApiMethod.get, path);
    return switch (raw) {
      AppSuccess(:final value) => _asObject(value),
      AppError(:final failure) => AppError(failure),
    };
  }

  Future<AppResult<List<JsonObject>>> getList(String path) async {
    final raw = await _send(ApiMethod.get, path);
    return switch (raw) {
      AppSuccess(:final value) => _asList(value),
      AppError(:final failure) => AppError(failure),
    };
  }

  Future<AppResult<JsonObject>> putObject(String path, JsonObject body) async {
    final raw = await _send(ApiMethod.put, path, body: body);
    return switch (raw) {
      AppSuccess(:final value) => _asObject(value),
      AppError(:final failure) => AppError(failure),
    };
  }

  Future<AppResult<JsonObject>> postObject(String path, JsonObject body) async {
    final raw = await _send(ApiMethod.post, path, body: body);
    return switch (raw) {
      AppSuccess(:final value) => _asObject(value),
      AppError(:final failure) => AppError(failure),
    };
  }

  Future<AppResult<JsonObject>> deleteObject(String path) async {
    final raw = await _send(ApiMethod.delete, path);
    return switch (raw) {
      AppSuccess(:final value) => _asObject(value),
      AppError(:final failure) => AppError(failure),
    };
  }

  Future<AppResult<Object?>> _send(
    ApiMethod method,
    String path, {
    JsonObject? body,
  }) async {
    final access = await tokenStore.readAccessToken();
    final deviceId = await tokenStore.readDeviceIdentifier();
    if (access == null ||
        access.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty) {
      return const AppError(
        UnauthorizedFailure(
          'Sign in again. A mobile access token and device identifier are required.',
        ),
      );
    }

    final correlationId = _newCorrelationId();
    final normalized = path.startsWith('/') ? path : '/$path';
    final transport = _transport;
    if (transport != null) {
      final result = await transport.send(
        ApiRequest(
          method: method,
          path: normalized,
          body: body,
          correlationId: correlationId,
        ),
      );
      return switch (result) {
        AppSuccess(:final value) => AppSuccess(ApiEnvelope.dataOf(value.body)),
        AppError(:final failure) => AppError(failure),
      };
    }

    final uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/$'), '')}$normalized',
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $access',
      'X-Device-Identifier': deviceId,
      'X-Correlation-ID': correlationId,
      if (body != null) 'Content-Type': 'application/json',
    };

    try {
      final response = switch (method) {
        ApiMethod.get => await _http.get(uri, headers: headers),
        ApiMethod.post => await _http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        ApiMethod.put => await _http.put(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        ApiMethod.patch => await _http.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        ApiMethod.delete => await _http.delete(uri, headers: headers),
      };
      return _decodeEnvelope(response);
    } on http.ClientException catch (error) {
      return AppError(NetworkFailure('Network request failed.', cause: error));
    } catch (error) {
      return AppError(UnknownFailure('Unexpected transport error.', cause: error));
    }
  }

  AppResult<Object?> _decodeEnvelope(http.Response response) {
    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (error) {
        return AppError(
          ServerFailure(
            'Invalid JSON from server (${response.statusCode}).',
            cause: error,
          ),
        );
      }
    }

    final envelope =
        decoded is Map ? Map<String, Object?>.from(
          decoded.map((key, value) => MapEntry('$key', value)),
        ) : <String, Object?>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AppSuccess(envelope['data']);
    }

    final errorNode = envelope['error'];
    final errorMap =
        errorNode is Map
            ? Map<String, Object?>.from(
              errorNode.map((key, value) => MapEntry('$key', value)),
            )
            : const <String, Object?>{};
    final message =
        (errorMap['message'] as String?) ??
        'Request failed (${response.statusCode}).';
    final code = errorMap['code'] as String?;
    final details = errorMap['details'];
    final fieldErrors = <String, List<String>>{};
    if (details is Map) {
      for (final entry in details.entries) {
        final value = entry.value;
        if (value is List) {
          fieldErrors['${entry.key}'] =
              value.map((item) => '$item').toList(growable: false);
        } else if (value != null) {
          fieldErrors['${entry.key}'] = ['$value'];
        }
      }
    }

    return AppError(
      _failureForStatus(response.statusCode, message, fieldErrors, code: code),
    );
  }

  AppFailure _failureForStatus(
    int status,
    String message,
    Map<String, List<String>> errors, {
    String? code,
  }) {
    final mfaHint = _looksLikeRecentMfa(message, code);
    return switch (status) {
      401 => UnauthorizedFailure(message, code: code),
      403 => ForbiddenFailure(
        message,
        code: mfaHint ? (code ?? 'MFA_RECENT_REQUIRED') : code,
      ),
      404 => NotFoundFailure(message, code: code),
      409 => ConflictFailure(message, code: code),
      422 => ValidationFailure(message, errors: errors, code: code),
      429 => RateLimitFailure(message, code: code),
      >= 500 => ServerFailure(message, code: code),
      _ => UnknownFailure(message, code: code),
    };
  }

  bool _looksLikeRecentMfa(String message, String? code) {
    final normalized = '${code ?? ''} $message'.toLowerCase();
    return normalized.contains('mfa') ||
        normalized.contains('multi-factor') ||
        normalized.contains('multifactor');
  }

  AppResult<JsonObject> _asObject(Object? data) {
    if (data is Map) {
      return AppSuccess(
        Map<String, Object?>.from(
          data.map((key, value) => MapEntry('$key', value)),
        ),
      );
    }
    return const AppError(
      ServerFailure('Expected an object payload in data.'),
    );
  }

  AppResult<List<JsonObject>> _asList(Object? data) {
    if (data is List) {
      return AppSuccess([
        for (final item in data)
          if (item is Map)
            Map<String, Object?>.from(
              item.map((key, value) => MapEntry('$key', value)),
            ),
      ]);
    }
    return const AppError(ServerFailure('Expected a list payload in data.'));
  }

  String _newCorrelationId() {
    final millis = DateTime.now().toUtc().millisecondsSinceEpoch;
    return 'fhc-mobile-$millis';
  }
}

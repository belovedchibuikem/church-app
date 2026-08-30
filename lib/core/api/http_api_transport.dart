import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_envelope.dart';
import 'api_transport.dart';
import 'app_failure.dart';
import 'fhc_api_config.dart';
import '../l10n/locale_holder.dart';

/// Production [ApiTransport] over `package:http`.
///
/// - Resolves paths against the `/api/v1` base from [resolveFhcApiUrl].
/// - Attaches opaque `Authorization: Bearer` + `X-Device-Identifier` when
///   present in [tokenStore] (unless [ApiRequest.skipAuth]).
/// - Forwards `X-Correlation-ID` / `Idempotency-Key` when the request provides them.
/// - Maps Laravel error envelopes to [AppFailure] subtypes.
/// - Optionally retries once after [SessionRefresher] on HTTP 401.
///   The refresher must persist the **rotated refresh token** itself before
///   returning the new access token (reuse detection revokes the family).
///
/// Inject [httpClient] in tests. Generated clients under
/// `api/clients/dart` use the **host** base ([resolveFhcPublicApiBaseUrl]);
/// this transport uses the `/api/v1` base — see [fhc_api_config.dart].
final class HttpApiTransport implements ApiTransport {
  HttpApiTransport({
    required SessionTokenStore tokenStore,
    String? baseUrl,
    SessionRefresher? refresher,
    http.Client? httpClient,
    bool ownsClient = false,
  })  : _tokenStore = tokenStore,
        _baseUrl = resolveFhcApiUrl(override: baseUrl),
        _refresher = refresher,
        _http = httpClient ?? http.Client(),
        _ownsClient = httpClient == null || ownsClient;

  final SessionTokenStore _tokenStore;
  final String _baseUrl;
  final SessionRefresher? _refresher;
  final http.Client _http;
  final bool _ownsClient;
  final Set<String> _cancelledRequestIds = {};

  String get baseUrl => _baseUrl;

  @override
  Future<AppResult<ApiResponse>> send(ApiRequest request) async {
    return _send(request, allowRefresh: true);
  }

  Future<AppResult<ApiResponse>> _send(
    ApiRequest request, {
    required bool allowRefresh,
  }) async {
    final requestId = request.headers['X-Request-ID'];
    if (requestId != null && _cancelledRequestIds.contains(requestId)) {
      _cancelledRequestIds.remove(requestId);
      return const AppError(UnknownFailure('Request cancelled.'));
    }

    late final Uri uri;
    try {
      uri = _buildUri(request.path, request.query);
    } catch (error) {
      return AppError(
        UnknownFailure('Invalid request URL.', cause: error),
      );
    }

    final headers = await _buildHeaders(request);

    try {
      final response = await _dispatch(request.method, uri, headers, request.body)
          .timeout(request.timeout);

      if (response.statusCode == 401 &&
          allowRefresh &&
          !request.skipAuth &&
          _refresher != null) {
        final refreshed = await _refresher.refreshAccessToken();
        if (refreshed is AppSuccess<String>) {
          await _tokenStore.writeAccessToken(refreshed.value);
          return _send(request, allowRefresh: false);
        }
        if (refreshed is AppError<String>) {
          return AppError(refreshed.failure);
        }
      }

      return _mapResponse(response);
    } on TimeoutException catch (error) {
      return AppError(
        NetworkFailure('The request timed out.', cause: error),
      );
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Network request failed.', cause: error),
      );
    } catch (error) {
      // Avoid dart:io (breaks web); IOClient may still surface SocketException.
      if (error.runtimeType.toString() == 'SocketException') {
        return AppError(
          NetworkFailure('Network request failed.', cause: error),
        );
      }
      return AppError(
        UnknownFailure('Unexpected transport error.', cause: error),
      );
    }
  }

  @override
  Future<void> cancel(String requestId) async {
    _cancelledRequestIds.add(requestId);
  }

  void close() {
    if (_ownsClient) {
      _http.close();
    }
  }

  Uri _buildUri(String path, Map<String, Object?> query) {
    final base = _baseUrl.replaceAll(RegExp(r'/$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    var uri = Uri.parse('$base$normalized');
    if (query.isNotEmpty) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          for (final entry in query.entries)
            if (entry.value != null) entry.key: '${entry.value}',
        },
      );
    }
    return uri;
  }

  Future<Map<String, String>> _buildHeaders(ApiRequest request) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': FhcLocaleHolder.languageCode,
      'X-Client-Channel': 'mobile',
      ...request.headers,
    };

    if (request.correlationId != null &&
        request.correlationId!.isNotEmpty &&
        !headers.containsKey('X-Correlation-ID')) {
      headers['X-Correlation-ID'] = request.correlationId!;
    }

    if (request.idempotencyKey != null &&
        request.idempotencyKey!.isNotEmpty &&
        !headers.containsKey('Idempotency-Key')) {
      headers['Idempotency-Key'] = request.idempotencyKey!;
    }

    if (!request.skipAuth) {
      final accessToken = await _tokenStore.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        headers.putIfAbsent('Authorization', () => 'Bearer $accessToken');
      }

      final deviceId = await _tokenStore.readDeviceIdentifier();
      if (deviceId != null && deviceId.isNotEmpty) {
        headers.putIfAbsent('X-Device-Identifier', () => deviceId);
      }
    }

    if (request.body != null && !headers.containsKey('Content-Type')) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  Future<http.Response> _dispatch(
    ApiMethod method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) {
    final encoded = _encodeBody(body);
    return switch (method) {
      ApiMethod.get => _http.get(uri, headers: headers),
      ApiMethod.post => _http.post(uri, headers: headers, body: encoded),
      ApiMethod.put => _http.put(uri, headers: headers, body: encoded),
      ApiMethod.patch => _http.patch(uri, headers: headers, body: encoded),
      ApiMethod.delete => _http.delete(uri, headers: headers, body: encoded),
    };
  }

  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  AppResult<ApiResponse> _mapResponse(http.Response response) {
    final decoded = ApiEnvelope.tryDecodeJson(response.body);
    final envelopeCorrelation = ApiEnvelope.correlationIdOf(decoded);
    final headerCorrelation = response.headers['x-correlation-id'];
    final correlationId = envelopeCorrelation ?? headerCorrelation;

    final apiResponse = ApiResponse(
      statusCode: response.statusCode,
      body: decoded,
      headers: response.headers,
      correlationId: correlationId,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AppSuccess(apiResponse);
    }

    final parsedError = ApiEnvelope.errorOf(decoded);
    final validationErrors = parsedError == null
        ? const <String, List<String>>{}
        : ApiEnvelope.validationFieldsOf(parsedError);

    return AppError(
      mapHttpStatusToFailure(
        statusCode: response.statusCode,
        message: parsedError?.message,
        code: parsedError?.code,
        correlationId: correlationId ?? parsedError?.correlationId,
        validationErrors: validationErrors,
        cause: decoded,
      ),
    );
  }
}

/// Convenience bootstrap for repositories and feature workers.
HttpApiTransport createHttpApiTransport({
  required SessionTokenStore tokenStore,
  String? baseUrl,
  SessionRefresher? refresher,
  http.Client? httpClient,
}) {
  return HttpApiTransport(
    tokenStore: tokenStore,
    baseUrl: baseUrl,
    refresher: refresher,
    httpClient: httpClient,
  );
}

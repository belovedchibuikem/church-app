import 'dart:convert';

import 'package:family_house_connect_public_api/public_api.dart';
import 'package:http/http.dart' as http;

/// Browser- and IO-safe adapter for the generated public Dart client.
///
/// Prefer this over `IoPublicApiTransport` when the app may run on Flutter web
/// (visual review) in addition to future native targets.
final class HttpPublicApiTransport implements PublicApiTransport {
  HttpPublicApiTransport({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<PublicApiTransportResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    final response = await _client.get(uri, headers: headers);
    return _decode(response);
  }

  @override
  Future<PublicApiTransportResponse> post(
    Uri uri, {
    Map<String, String> headers = const {},
    JsonMap body = const {},
  }) async {
    final response = await _client.post(
      uri,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  PublicApiTransportResponse _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException(
        'The public API response must be a JSON object.',
      );
    }
    return PublicApiTransportResponse(
      statusCode: response.statusCode,
      body: Map<String, Object?>.from(decoded),
    );
  }
}

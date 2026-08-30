import 'dart:convert';

/// Shared helpers for Laravel `/api/v1` JSON envelopes.
///
/// Success: `{ data, meta, correlation_id }`
/// Error: `{ error: { code, message, details }, meta, correlation_id }`
final class ApiEnvelope {
  const ApiEnvelope._();

  static String? correlationIdOf(Object? body) {
    if (body is Map) {
      final value = body['correlation_id'];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  static Object? dataOf(Object? body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return null;
  }

  static Map<String, Object?> metaOf(Object? body) {
    if (body is Map && body['meta'] is Map) {
      return Map<String, Object?>.from(body['meta'] as Map);
    }
    return const {};
  }

  static ParsedApiError? errorOf(Object? body) {
    if (body is! Map) return null;
    final error = body['error'];
    if (error is! Map) return null;

    final detailsRaw = error['details'];
    final details = detailsRaw is Map
        ? Map<String, Object?>.from(detailsRaw)
        : <String, Object?>{};

    return ParsedApiError(
      code: (error['code'] as String?) ?? 'UNKNOWN',
      message: (error['message'] as String?) ?? 'Request failed.',
      details: details,
      correlationId: correlationIdOf(body),
    );
  }

  /// Laravel validation details use `{ fields: { field: [messages] } }`.
  static Map<String, List<String>> validationFieldsOf(ParsedApiError error) {
    final fields = error.details['fields'];
    if (fields is! Map) return const {};

    final mapped = <String, List<String>>{};
    fields.forEach((key, value) {
      if (value is List) {
        mapped['$key'] = value.map((e) => '$e').toList(growable: false);
      } else if (value != null) {
        mapped['$key'] = ['$value'];
      }
    });
    return mapped;
  }

  static Object? tryDecodeJson(String raw) {
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return raw;
    }
  }
}

final class ParsedApiError {
  const ParsedApiError({
    required this.code,
    required this.message,
    this.details = const {},
    this.correlationId,
  });

  final String code;
  final String message;
  final Map<String, Object?> details;
  final String? correlationId;
}

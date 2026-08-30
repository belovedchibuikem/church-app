import 'api_envelope.dart';
import 'api_transport.dart';
import 'app_failure.dart';
import '../contracts/mobile_repository_contracts.dart';

/// Shared envelope parsing for repositories that use [ApiTransport].
mixin TransportRepositoryHelpers {
  Future<AppResult<JsonObject>> sendObject(
    ApiTransport transport,
    ApiRequest request,
  ) async {
    final result = await transport.send(request);
    return switch (result) {
      AppSuccess(:final value) => _asObject(ApiEnvelope.dataOf(value.body)),
      AppError(:final failure) => AppError(failure),
    };
  }

  Future<AppResult<List<JsonObject>>> sendList(
    ApiTransport transport,
    ApiRequest request,
  ) async {
    final result = await transport.send(request);
    return switch (result) {
      AppSuccess(:final value) => _asList(ApiEnvelope.dataOf(value.body)),
      AppError(:final failure) => AppError(failure),
    };
  }

  Future<AppResult<void>> sendVoid(
    ApiTransport transport,
    ApiRequest request,
  ) async {
    final result = await transport.send(request);
    return switch (result) {
      AppSuccess() => const AppSuccess(null),
      AppError(:final failure) => AppError(failure),
    };
  }

  AppResult<JsonObject> _asObject(Object? data) {
    if (data is Map) {
      return AppSuccess(_jsonObject(data));
    }
    if (data == null) {
      return const AppSuccess(<String, Object?>{});
    }
    return const AppError(
      ServerFailure('Expected an object payload in data.'),
    );
  }

  AppResult<List<JsonObject>> _asList(Object? data) {
    if (data is List) {
      return AppSuccess([
        for (final item in data)
          if (item is Map) _jsonObject(item),
      ]);
    }
    if (data is Map) {
      final nested = data['items'] ?? data['data'] ?? data['results'];
      if (nested is List) {
        return AppSuccess([
          for (final item in nested)
            if (item is Map) _jsonObject(item),
        ]);
      }
    }
    if (data == null) {
      return const AppSuccess(<JsonObject>[]);
    }
    return const AppError(
      ServerFailure('Expected a list payload in data.'),
    );
  }

  JsonObject _jsonObject(Map source) {
    return Map<String, Object?>.from(
      source.map((key, value) => MapEntry('$key', value)),
    );
  }

  String newIdempotencyKey(String prefix) {
    final millis = DateTime.now().toUtc().millisecondsSinceEpoch;
    return '$prefix-$millis';
  }

  String encodeId(String id) => Uri.encodeComponent(id.trim());
}

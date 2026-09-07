import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// Laravel `/user/testimonies` client.
final class HttpTestimonyRepository
    with TransportRepositoryHelpers
    implements TestimonyRepository {
  HttpTestimonyRepository({required ApiTransport transport})
      : _transport = transport;

  final ApiTransport _transport;

  @override
  Future<AppResult<List<JsonObject>>> listOwn() {
    return sendList(
      _transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/testimonies'),
    );
  }

  @override
  Future<AppResult<JsonObject>> create(JsonObject request) {
    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/testimonies',
        body: request,
        idempotencyKey: newIdempotencyKey('testimony'),
      ),
    );
  }
}

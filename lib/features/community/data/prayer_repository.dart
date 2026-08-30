import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// Laravel `/user/prayers` client.
final class HttpPrayerRepository
    with TransportRepositoryHelpers
    implements PrayerRepository {
  HttpPrayerRepository({required ApiTransport transport})
      : _transport = transport;

  final ApiTransport _transport;

  @override
  Future<AppResult<List<JsonObject>>> listOwn() {
    return sendList(
      _transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/prayers'),
    );
  }

  @override
  Future<AppResult<JsonObject>> create(JsonObject request) {
    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/prayers',
        body: request,
        idempotencyKey: newIdempotencyKey('prayer'),
      ),
    );
  }
}

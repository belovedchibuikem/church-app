import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// Laravel `/user/notifications` client.
final class HttpNotificationRepository
    with TransportRepositoryHelpers
    implements NotificationRepository {
  HttpNotificationRepository({required ApiTransport transport})
      : _transport = transport;

  final ApiTransport _transport;

  @override
  Future<AppResult<List<JsonObject>>> list() {
    return sendList(
      _transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/notifications'),
    );
  }

  @override
  Future<AppResult<JsonObject>> markRead(String notificationId) {
    final id = notificationId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Notification id is required.')),
      );
    }
    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/notifications/${encodeId(id)}/read',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> resolveDestination(String notificationId) async {
    final marked = await markRead(notificationId);
    return switch (marked) {
      AppError(:final failure) => AppError(failure),
      AppSuccess(:final value) => AppSuccess({
          ...value,
          'destination':
              value['destination'] ??
              value['route'] ??
              value['deep_link'] ??
              value['url'],
        }),
    };
  }
}

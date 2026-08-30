import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// Laravel `/user/messages/*` client.
final class HttpMessageRepository
    with TransportRepositoryHelpers
    implements MessageRepository {
  HttpMessageRepository({required ApiTransport transport})
      : _transport = transport;

  final ApiTransport _transport;

  @override
  Future<AppResult<List<JsonObject>>> conversations() {
    return sendList(
      _transport,
      const ApiRequest(
        method: ApiMethod.get,
        path: '/user/messages/conversations',
      ),
    );
  }

  @override
  Future<AppResult<List<JsonObject>>> messages(String conversationId) {
    final id = conversationId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Conversation id is required.')),
      );
    }
    return sendList(
      _transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/messages/conversations/${encodeId(id)}/messages',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> createConversation(JsonObject body) {
    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/messages/conversations',
        body: body,
        idempotencyKey: newIdempotencyKey('conversation'),
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> send(
    String conversationId,
    JsonObject message,
  ) {
    final id = conversationId.trim();
    if (id.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Conversation id is required.')),
      );
    }
    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/messages/conversations/${encodeId(id)}/messages',
        body: message,
        idempotencyKey: newIdempotencyKey('message'),
      ),
    );
  }
}

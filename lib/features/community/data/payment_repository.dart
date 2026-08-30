import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// Reads Laravel `amount_minor` (or legacy major-unit `amount` / `total`).
int? paymentAmountMinorOf(JsonObject json) {
  final minor = json['amount_minor'];
  if (minor is int) return minor;
  if (minor is num) return minor.round();
  final major = json['amount'] ?? json['total'];
  if (major is int) return major * 100;
  if (major is num) return (major * 100).round();
  if (major is String) {
    final parsed = num.tryParse(major.trim());
    if (parsed != null) return (parsed * 100).round();
  }
  return null;
}

/// Formats minor units for display (NGN defaults to ₦ with thousand separators).
String formatPaymentAmountMinor(
  int amountMinor, {
  String currency = 'NGN',
}) {
  final major = amountMinor / 100;
  final whole = major.round();
  final raw = whole.toString();
  final symbol = currency.toUpperCase() == 'NGN' ? '₦' : '$currency ';
  final buffer = StringBuffer(symbol);
  for (var i = 0; i < raw.length; i++) {
    final fromEnd = raw.length - i;
    if (i > 0 && fromEnd % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return buffer.toString();
}

/// HTTPS checkout URL from a giving or event payment intent payload.
String? hostedCheckoutUrlOf(JsonObject intent) {
  final payload = intent['client_payload'];
  if (payload is Map) {
    final url = '${payload['checkout_url'] ?? ''}';
    if (url.startsWith('https://')) return url;
  }
  return null;
}

/// Next in-app route after an intent status change.
String paymentIntentRoute(JsonObject intent) {
  final id = '${intent['id'] ?? intent['ulid'] ?? ''}'.trim();
  final status = '${intent['status'] ?? ''}'.toLowerCase();
  final encoded = id.isEmpty ? '' : '?id=${Uri.encodeComponent(id)}';
  return switch (status) {
    'succeeded' => '/payments/success$encoded',
    'failed' || 'cancelled' || 'expired' => '/payments/failed$encoded',
    _ => '/payments/processing$encoded',
  };
}

String paymentPurposeLabel(JsonObject intent) {
  return switch ('${intent['purpose_code'] ?? ''}') {
    'event_payment' => 'Event registration',
    'giving' => 'Giving',
    final value when value.isNotEmpty => value,
    _ => 'Payment',
  };
}

String paymentFailureMessage(AppFailure failure) {
  final isGovernance = failure.code == 'PAYMENT_GOVERNANCE_DENIED' ||
      failure.message.toLowerCase().contains('governance');
  if (isGovernance) {
    return failure.message.isNotEmpty
        ? failure.message
        : 'Giving is not available — payment governance denied this request.';
  }
  if (failure is ForbiddenFailure) {
    return failure.message.isNotEmpty
        ? failure.message
        : 'Giving is not permitted for this account under current '
            'payment governance rules.';
  }
  if (failure is PaymentFailure || failure is ValidationFailure) {
    return failure.message;
  }
  if (failure is UnauthorizedFailure) {
    return 'Sign in again to continue giving.';
  }
  if (failure is NotFoundFailure ||
      failure is IntegrationUnavailableFailure) {
    return failure.message.isNotEmpty
        ? failure.message
        : 'Payment services are not available yet. No charge was made.';
  }
  return failure.message;
}

/// Laravel `/user/payments/*` client.
final class HttpPaymentRepository
    with TransportRepositoryHelpers
    implements PaymentRepository {
  HttpPaymentRepository({required ApiTransport transport})
      : _transport = transport;

  final ApiTransport _transport;

  @override
  Future<AppResult<List<JsonObject>>> listIntents() {
    return sendList(
      _transport,
      const ApiRequest(method: ApiMethod.get, path: '/user/payments/intents'),
    );
  }

  @override
  Future<AppResult<JsonObject>> getIntent(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Giving intent id is required.')),
      );
    }
    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/payments/intents/${encodeId(trimmed)}',
      ),
    );
  }

  @override
  Future<AppResult<List<JsonObject>>> listTransactions() {
    return sendList(
      _transport,
      const ApiRequest(
        method: ApiMethod.get,
        path: '/user/payments/transactions',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> initiate(JsonObject payment) {
    final key =
        (payment['idempotency_key'] as String?)?.trim().isNotEmpty == true
            ? payment['idempotency_key'] as String
            : newIdempotencyKey('giving');

    final amountMinor = _resolveAmountMinor(payment);
    if (amountMinor == null || amountMinor < 1) {
      return Future.value(
        const AppError(ValidationFailure('A valid giving amount is required.')),
      );
    }

    final currency =
        ((payment['currency'] as String?)?.trim().toUpperCase().isNotEmpty ==
                true)
            ? (payment['currency'] as String).trim().toUpperCase()
            : 'NGN';

    // Strict contract: CreateGivingIntentRequest accepts only these fields.
    final body = <String, Object?>{
      'amount_minor': amountMinor,
      'currency': currency,
      'idempotency_key': key,
      'checkout_return': 'mobile',
    };

    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/payments/giving-intents',
        body: body,
        idempotencyKey: key,
        headers: const {'X-Client-Channel': 'mobile'},
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> completeGivingIntent(String intentId) {
    final trimmed = intentId.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Giving intent id is required.')),
      );
    }
    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/payments/giving-intents/${encodeId(trimmed)}/complete',
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> initiateEventPayment(String registrationId) {
    final trimmed = registrationId.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const AppError(
          ValidationFailure('Event registration id is required.'),
        ),
      );
    }
    final key = newIdempotencyKey('event-pay');
    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/events/registrations/${encodeId(trimmed)}/payment-intents',
        body: <String, Object?>{
          'checkout_return': 'mobile',
          'idempotency_key': key,
        },
        idempotencyKey: key,
        headers: const {'X-Client-Channel': 'mobile'},
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> getConfiguration() {
    return sendObject(
      _transport,
      const ApiRequest(
        method: ApiMethod.get,
        path: '/payments/configuration',
        skipAuth: true,
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> getTransaction(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Transaction id is required.'));
    }
    final listed = await listTransactions();
    switch (listed) {
      case AppError(:final failure):
        return AppError(failure);
      case AppSuccess(:final value):
        for (final item in value) {
          final itemId = '${item['id'] ?? item['ulid'] ?? ''}';
          if (itemId == trimmed) return AppSuccess(item);
        }
        return AppError(
          NotFoundFailure('Transaction $trimmed was not found.'),
        );
    }
  }

  @override
  Future<AppResult<JsonObject>> getReceipt(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Receipt id is required.')),
      );
    }
    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/payments/receipts/${encodeId(trimmed)}',
      ),
    );
  }

  /// Accepts `amount_minor`, or major-unit `amount` (converted ×100).
  static int? _resolveAmountMinor(JsonObject payment) {
    return paymentAmountMinorOf(payment);
  }
}

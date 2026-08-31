import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
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
    'tithe' => 'Tithe',
    'offering' => 'Offering',
    'missions' => 'Missions',
    'projects' => 'Building Project',
    'donation' => 'Donation',
    'kca' => 'KCA',
    'publication' => 'Publication',
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
  HttpPaymentRepository({
    required ApiTransport transport,
    SessionTokenStore? tokenStore,
    String? baseUrl,
    http.Client? httpClient,
  }) : _transport = transport,
       _tokenStore = tokenStore,
       _baseUrl = resolveFhcApiUrl(override: baseUrl),
       _http = httpClient ?? http.Client();

  final ApiTransport _transport;
  final SessionTokenStore? _tokenStore;
  final String _baseUrl;
  final http.Client _http;

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

    final purpose = '${payment['purpose_code'] ?? ''}'.trim().toLowerCase();
    final proofId = '${payment['proof_file_asset_id'] ?? ''}'.trim();
    final body = <String, Object?>{
      'amount_minor': amountMinor,
      'currency': currency,
      'purpose_code': purpose.isEmpty ? 'tithe' : purpose,
      'idempotency_key': key,
      'checkout_return': 'mobile',
    };
    if (proofId.isNotEmpty) {
      body['proof_file_asset_id'] = proofId;
    }

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
  Future<AppResult<JsonObject>> completeGivingIntent(
    String intentId, {
    String? proofFileAssetId,
  }) {
    final trimmed = intentId.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const AppError(ValidationFailure('Giving intent id is required.')),
      );
    }
    final proof = proofFileAssetId?.trim() ?? '';
    if (proof.isEmpty) {
      return Future.value(
        const AppError(
          ValidationFailure(
            'Upload a payment receipt before completing a manual gift.',
          ),
        ),
      );
    }
    return sendObject(
      _transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/payments/giving-intents/${encodeId(trimmed)}/complete',
        body: <String, Object?>{'proof_file_asset_id': proof},
      ),
    );
  }

  @override
  Future<AppResult<JsonObject>> uploadPaymentProof({
    required List<int> bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      return const AppError(
        ValidationFailure('Choose a payment receipt to upload.'),
      );
    }
    final store = _tokenStore;
    if (store == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Payment receipt upload requires a signed-in session.',
        ),
      );
    }
    final access = await store.readAccessToken();
    final deviceId = await store.readDeviceIdentifier();
    if (access == null ||
        access.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty) {
      return const AppError(
        UnauthorizedFailure(
          'Sign in again to upload a payment receipt.',
        ),
      );
    }
    final safeName =
        filename.trim().isEmpty ? 'payment-receipt.jpg' : filename.trim();
    final idempotencyKey =
        'proof-${DateTime.now().toUtc().millisecondsSinceEpoch}';
    final uri = Uri.parse(
      '${_baseUrl.replaceAll(RegExp(r'/$'), '')}/user/files',
    );
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $access',
        'X-Device-Identifier': deviceId,
        'Idempotency-Key': idempotencyKey,
        'X-Correlation-ID': 'fhc-mobile-proof-$idempotencyKey',
      });
      request.fields['purpose'] = 'payment.proof';
      request.fields['classification'] = 'internal';
      request.fields['idempotency_key'] = idempotencyKey;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: safeName),
      );
      final streamed = await _http.send(request);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AppError(
          ServerFailure(
            'Payment receipt upload failed (${response.statusCode}).',
          ),
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] is Map) {
        return AppSuccess(
          Map<String, Object?>.from(decoded['data'] as Map),
        );
      }
      if (decoded is Map) {
        return AppSuccess(Map<String, Object?>.from(decoded));
      }
      return const AppError(
        ServerFailure('Payment receipt upload returned an unexpected payload.'),
      );
    } catch (error) {
      return AppError(ServerFailure('$error'));
    }
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

sealed class AppFailure {
  const AppFailure(this.message, {this.cause, this.code, this.correlationId});

  final String message;
  final Object? cause;

  /// Laravel `error.code` when available (e.g. `VALIDATION_FAILED`).
  final String? code;

  final String? correlationId;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });

  /// True when Laravel `mfa.recent` (or equivalent) rejected the call.
  bool get requiresRecentMfa {
    final normalized = '${code ?? ''} $message'.toLowerCase();
    return normalized.contains('mfa') ||
        normalized.contains('multi-factor') ||
        normalized.contains('multifactor');
  }
}

/// Whether [failure] is a recent-MFA gate (not a generic permission denial).
bool isRecentMfaRequired(AppFailure failure) {
  if (failure is ForbiddenFailure) return failure.requiresRecentMfa;
  final normalized = '${failure.code ?? ''} ${failure.message}'.toLowerCase();
  return normalized.contains('mfa') ||
      normalized.contains('multi-factor') ||
      normalized.contains('multifactor');
}

/// User-facing copy for MFA step-up. Does not invent a successful challenge.
String honestMfaRequiredMessage(AppFailure failure) {
  if (failure.message.trim().isNotEmpty &&
      failure.message.toLowerCase().contains('multi-factor')) {
    return failure.message;
  }
  return 'Recent multi-factor authentication is required. Open MFA challenge, then retry.';
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(
    super.message, {
    this.errors = const {},
    super.cause,
    super.code,
    super.correlationId,
  });

  final Map<String, List<String>> errors;
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

final class ServerFailure extends AppFailure {
  const ServerFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

final class OfflineFailure extends AppFailure {
  const OfflineFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

final class UploadFailure extends AppFailure {
  const UploadFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

final class PaymentFailure extends AppFailure {
  const PaymentFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

final class IntegrationUnavailableFailure extends AppFailure {
  const IntegrationUnavailableFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(
    super.message, {
    super.cause,
    super.code,
    super.correlationId,
  });
}

sealed class AppResult<T> {
  const AppResult();
}

final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);

  final T value;
}

final class AppError<T> extends AppResult<T> {
  const AppError(this.failure);

  final AppFailure failure;
}

/// Maps an HTTP status (+ optional Laravel error envelope fields) to [AppFailure].
AppFailure mapHttpStatusToFailure({
  required int statusCode,
  String? message,
  String? code,
  String? correlationId,
  Map<String, List<String>> validationErrors = const {},
  Object? cause,
}) {
  final resolvedMessage = (message != null && message.isNotEmpty)
      ? message
      : 'Request failed ($statusCode).';

  return switch (statusCode) {
    401 => UnauthorizedFailure(
        resolvedMessage,
        cause: cause,
        code: code,
        correlationId: correlationId,
      ),
    403 => ForbiddenFailure(
        resolvedMessage,
        cause: cause,
        code: code,
        correlationId: correlationId,
      ),
    404 => NotFoundFailure(
        resolvedMessage,
        cause: cause,
        code: code,
        correlationId: correlationId,
      ),
    409 => ConflictFailure(
        resolvedMessage,
        cause: cause,
        code: code,
        correlationId: correlationId,
      ),
    422 => code == 'PAYMENT_GOVERNANCE_DENIED'
        ? PaymentFailure(
            resolvedMessage,
            cause: cause,
            code: code,
            correlationId: correlationId,
          )
        : ValidationFailure(
            resolvedMessage,
            errors: validationErrors,
            cause: cause,
            code: code ?? 'VALIDATION_FAILED',
            correlationId: correlationId,
          ),
    429 => RateLimitFailure(
        resolvedMessage,
        cause: cause,
        code: code,
        correlationId: correlationId,
      ),
    503 => IntegrationUnavailableFailure(
        resolvedMessage,
        cause: cause,
        code: code,
        correlationId: correlationId,
      ),
    >= 500 => ServerFailure(
        resolvedMessage,
        cause: cause,
        code: code,
        correlationId: correlationId,
      ),
    _ => UnknownFailure(
        resolvedMessage,
        cause: cause,
        code: code,
        correlationId: correlationId,
      ),
  };
}

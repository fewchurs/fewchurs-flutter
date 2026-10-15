/// Base class of every SDK error. Switch over it to handle each case.
sealed class FewchursException implements Exception {
  const FewchursException(this.message, {this.statusCode});

  /// Developer-facing detail, usually the server message.
  final String message;
  final int? statusCode;

  /// Machine-readable code, e.g. `invalid_key`.
  String get code;

  /// A short English message that is safe to show to end users.
  String get userMessage;

  @override
  String toString() =>
      'FewchursException($code${statusCode == null ? '' : ', HTTP $statusCode'}): $message';
}

const _generic = 'Something went wrong. Try again.';

/// The API key is wrong, or its app was deleted (401).
final class FewchursInvalidApiKeyException extends FewchursException {
  const FewchursInvalidApiKeyException(super.message, {super.statusCode});

  @override
  String get code => 'invalid_key';

  @override
  String get userMessage =>
      'Invalid API key. Check the key in your Fewchurs dashboard.';
}

/// The input was rejected (400).
final class FewchursValidationException extends FewchursException {
  const FewchursValidationException(super.message, {super.statusCode});

  @override
  String get code => 'validation_failed';

  @override
  String get userMessage => message;
}

/// The device hit its daily submission or comment limit (429).
final class FewchursRateLimitedException extends FewchursException {
  const FewchursRateLimitedException(super.message, {super.statusCode});

  @override
  String get code => 'rate_limited';

  @override
  String get userMessage => "You've reached today's limit. Try again tomorrow.";
}

/// The board isn't accepting this action (402). Rare.
final class FewchursLimitReachedException extends FewchursException {
  const FewchursLimitReachedException(super.message, {super.statusCode});

  @override
  String get code => 'limit_reached';

  @override
  String get userMessage => "This board isn't accepting requests right now.";
}

/// The request doesn't exist or isn't visible to this device (404).
final class FewchursNotFoundException extends FewchursException {
  const FewchursNotFoundException(super.message, {super.statusCode});

  @override
  String get code => 'not_found';

  @override
  String get userMessage => 'This request no longer exists.';
}

/// The server failed (5xx).
final class FewchursServerException extends FewchursException {
  const FewchursServerException(super.message, {super.statusCode});

  @override
  String get code => 'internal';

  @override
  String get userMessage => _generic;
}

/// The device is offline or the request timed out.
final class FewchursNetworkException extends FewchursException {
  const FewchursNetworkException(super.message);

  @override
  String get code => 'network';

  @override
  String get userMessage => "You're offline.";
}

/// Any other failure, including 403.
final class FewchursUnknownException extends FewchursException {
  const FewchursUnknownException(super.message, {super.statusCode});

  @override
  String get code => 'unknown';

  @override
  String get userMessage => _generic;
}

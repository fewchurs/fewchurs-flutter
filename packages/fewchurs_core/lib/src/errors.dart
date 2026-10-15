sealed class FewchursException implements Exception {
  const FewchursException(this.message, {this.statusCode});

  /// Developer-facing detail, usually the server message.
  final String message;
  final int? statusCode;

  String get code;

  /// A short English message that is safe to show to end users.
  String get userMessage;

  @override
  String toString() =>
      'FewchursException($code${statusCode == null ? '' : ', HTTP $statusCode'}): $message';
}

const _generic = 'Something went wrong. Try again.';

final class FewchursInvalidApiKeyException extends FewchursException {
  const FewchursInvalidApiKeyException(super.message, {super.statusCode});

  @override
  String get code => 'invalid_key';

  @override
  String get userMessage =>
      'Invalid API key. Check the key in your Fewchurs dashboard.';
}

final class FewchursValidationException extends FewchursException {
  const FewchursValidationException(super.message, {super.statusCode});

  @override
  String get code => 'validation_failed';

  @override
  String get userMessage => message;
}

final class FewchursRateLimitedException extends FewchursException {
  const FewchursRateLimitedException(super.message, {super.statusCode});

  @override
  String get code => 'rate_limited';

  @override
  String get userMessage =>
      "You've reached today's limit. Try again tomorrow.";
}

final class FewchursLimitReachedException extends FewchursException {
  const FewchursLimitReachedException(super.message, {super.statusCode});

  @override
  String get code => 'limit_reached';

  @override
  String get userMessage => "This board isn't accepting requests right now.";
}

final class FewchursNotFoundException extends FewchursException {
  const FewchursNotFoundException(super.message, {super.statusCode});

  @override
  String get code => 'not_found';

  @override
  String get userMessage => 'This request no longer exists.';
}

final class FewchursServerException extends FewchursException {
  const FewchursServerException(super.message, {super.statusCode});

  @override
  String get code => 'internal';

  @override
  String get userMessage => _generic;
}

final class FewchursNetworkException extends FewchursException {
  const FewchursNetworkException(super.message);

  @override
  String get code => 'network';

  @override
  String get userMessage => "You're offline.";
}

final class FewchursUnknownException extends FewchursException {
  const FewchursUnknownException(super.message, {super.statusCode});

  @override
  String get code => 'unknown';

  @override
  String get userMessage => _generic;
}

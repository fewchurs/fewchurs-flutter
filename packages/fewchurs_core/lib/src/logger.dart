/// How much the SDK logs. The API key is never logged.
enum FewchursLogLevel { none, error, debug }

/// Receives each log line.
typedef FewchursLogSink = void Function(String message);

/// Writes SDK log lines to [sink] at or below [level].
class FewchursLogger {
  const FewchursLogger({
    this.level = FewchursLogLevel.error,
    this.sink = _print,
  });

  final FewchursLogLevel level;
  final FewchursLogSink sink;

  /// Logs [message] only at [FewchursLogLevel.debug].
  void debug(String message) {
    if (level == FewchursLogLevel.debug) sink('[Fewchurs] $message');
  }

  /// Logs [message] unless the level is [FewchursLogLevel.none].
  void error(String message) {
    if (level != FewchursLogLevel.none) sink('[Fewchurs] $message');
  }
}

// ignore: avoid_print
void _print(String message) => print(message);

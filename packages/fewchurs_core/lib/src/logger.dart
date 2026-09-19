enum FewchursLogLevel { none, error, debug }

typedef FewchursLogSink = void Function(String message);

class FewchursLogger {
  const FewchursLogger({
    this.level = FewchursLogLevel.error,
    this.sink = _print,
  });

  final FewchursLogLevel level;
  final FewchursLogSink sink;

  void debug(String message) {
    if (level == FewchursLogLevel.debug) sink('[Fewchurs] $message');
  }

  void error(String message) {
    if (level != FewchursLogLevel.none) sink('[Fewchurs] $message');
  }
}

// ignore: avoid_print
void _print(String message) => print(message);

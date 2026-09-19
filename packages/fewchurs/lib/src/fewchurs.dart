import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'controllers/board_controller.dart';
import 'controllers/feature_detail_controller.dart';
import 'controllers/vote_queue.dart';
import 'identity/prefs_device_id_store.dart';
import 'l10n/fewchurs_strings.dart';
import 'runtime.dart';
import 'screens/board_screen.dart';
import 'theme/fewchurs_theme.dart';
import 'widgets/adaptive.dart';

const fewchursVersion = '1.0.0';

/// Entry point: call [configure] once in `main()`, then [showBoard],
/// [showBoardSheet] or embed a [FewchursBoard].
class Fewchurs {
  Fewchurs._();

  static FewchursRuntime get _rt => FewchursRuntime.instance;

  /// Synchronous and does no network work, so it's safe in `main()`.
  static void configure({
    required String apiKey,
    String? baseUrl,
    FutureOr<String?> Function()? deviceId,
    DeviceIdStore? deviceIdStore,
    http.Client? httpClient,
    FewchursStyle style = FewchursStyle.material,
    BoardOptions board = const BoardOptions(),
    FewchursStrings? strings,
    FutureOr<bool> Function()? isSubscriber,
    FutureOr<String?> Function()? userEmail,
    FewchursLogLevel logLevel = FewchursLogLevel.error,
  }) {
    _rt.reset();
    final logger = FewchursLogger(level: logLevel, sink: (m) => debugPrint(m));
    final client = FewchursClient(
      apiKey: apiKey,
      baseUrl: baseUrl,
      httpClient: httpClient,
      identity: DeviceIdentity(
        store: deviceIdStore ?? const PrefsDeviceIdStore(),
        resolver: deviceId,
      ),
      sdkHeader: 'flutter/$fewchursVersion (${_platformName()})',
      localeProvider: () => PlatformDispatcher.instance.locale.toLanguageTag(),
      logger: logger,
      onEvent: _rt.emit,
    );
    _rt
      ..logger = logger
      ..client = client
      ..votes = VoteQueue(client)
      ..config = FewchursConfig(
        apiKey: apiKey,
        style: style,
        board: board,
        strings: strings,
        isSubscriber: isSubscriber,
        userEmail: userEmail,
      );
    if (!apiKey.startsWith('fr_')) {
      logger.error('The API key doesn\'t look like a Fewchurs key (fr_live_…).');
    }
  }

  static bool get isConfigured => _rt.client != null;

  static FewchursClient get client {
    final c = _rt.client;
    if (c == null) {
      throw StateError('Call Fewchurs.configure(apiKey: ...) first.');
    }
    return c;
  }

  static FewchursConfig get config =>
      _rt.config ?? (throw StateError('Call Fewchurs.configure(apiKey: ...) first.'));

  /// Analytics-friendly events. The package itself sends no analytics.
  static Stream<FewchursEvent> get events => _rt.events.stream;

  /// Server settings such as branding and hidden vote counts; cached.
  static ValueListenable<RemoteConfig> get remoteConfig {
    _rt.loadRemoteConfig();
    return _rt.remote;
  }

  static Future<void> showBoard(
    BuildContext context, {
    FewchursBoard board = const FewchursBoard(showCloseButton: true),
  }) {
    return Navigator.of(context).push<void>(
      fewchursRoute(context, (_) => board, fullscreenDialog: true),
    );
  }

  static Future<void> showBoardSheet(
    BuildContext context, {
    FewchursBoard board = const FewchursBoard(showCloseButton: true),
    double heightFactor = 0.92,
  }) {
    final radius = FewchursThemeData.of(context).sheetRadius;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: heightFactor,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          child: board,
        ),
      ),
    );
  }

  /// Submits a request from your own UI. Throws a [FewchursException].
  static Future<Feature> submitFeature({
    required String title,
    String description = '',
    String? email,
    bool? isSubscriber,
  }) async {
    final c = _rt.client;
    if (c == null) {
      throw const FewchursUnknownException(
          'Call Fewchurs.configure(apiKey: ...) first.');
    }
    final feature = await c.submitFeature(
      title: title,
      description: description,
      email: email,
      isSubscriber: isSubscriber ?? await _rt.isSubscriber(),
    );
    _rt.submitted.add(feature);
    return feature;
  }

  static BoardController boardController({
    FeatureSort sort = FeatureSort.top,
    Set<FeatureStatus>? statuses,
    bool? showDeclined,
    int? pageSize,
    bool autoLoad = true,
  }) {
    final options = config.board;
    return BoardController(
      client: client,
      votes: _rt.votes,
      sort: sort,
      statuses: statuses,
      showDeclined: showDeclined ?? options.showDeclined,
      pageSize: pageSize ?? options.pageSize,
      autoLoad: autoLoad,
    );
  }

  static FeatureDetailController detailController(
    Feature feature, {
    ValueChanged<Feature>? onFeatureChanged,
  }) {
    return FeatureDetailController(
      client: client,
      votes: _rt.votes,
      feature: feature,
      onFeatureChanged: onFeatureChanged,
    );
  }

  /// Forgets the configuration. Mainly for tests.
  @visibleForTesting
  static void reset() => _rt.reset();

  static String _platformName() =>
      kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
}

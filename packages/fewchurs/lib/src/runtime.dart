import 'dart:async';

import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config.dart';
import 'controllers/vote_queue.dart';
import 'identity/prefs_device_id_store.dart';

/// Internal shared state behind the `Fewchurs` facade. Not exported.
class FewchursRuntime {
  FewchursRuntime._();

  static final instance = FewchursRuntime._();

  FewchursConfig? config;
  FewchursClient? client;
  VoteQueue? votes;
  FewchursLogger logger = const FewchursLogger();
  final prefs = const FewchursPrefs();
  final events = StreamController<FewchursEvent>.broadcast();
  final submitted = StreamController<Feature>.broadcast();
  final remote = ValueNotifier<RemoteConfig>(const RemoteConfig());
  bool _remoteLoaded = false;
  bool _warnedNotConfigured = false;

  String draftTitle = '';
  String draftDescription = '';

  void emit(FewchursEvent event) {
    if (events.hasListener) events.add(event);
  }

  void warnNotConfigured() {
    if (_warnedNotConfigured) return;
    _warnedNotConfigured = true;
    debugPrint('[Fewchurs] Fewchurs.configure(apiKey: ...) must be called '
        'before showing the board.');
  }

  void loadRemoteConfig() {
    final c = client;
    if (c == null || _remoteLoaded) return;
    c.getConfig().then((value) {
      _remoteLoaded = true;
      remote.value = value;
    }, onError: (Object _) {});
  }

  void reset() {
    client?.close();
    client = null;
    config = null;
    votes = null;
    _remoteLoaded = false;
    remote.value = const RemoteConfig();
    draftTitle = '';
    draftDescription = '';
  }

  Future<String?> knownEmail() async {
    try {
      final fromApp = await config?.userEmail?.call();
      if (fromApp != null && fromApp.trim().isNotEmpty) return fromApp.trim();
    } catch (_) {}
    return prefs.get(FewchursPrefs.emailKey);
  }

  Future<bool?> isSubscriber() async {
    try {
      return await config?.isSubscriber?.call();
    } catch (_) {
      return null;
    }
  }

  bool useCupertino(BuildContext context) {
    switch (config?.style ?? FewchursStyle.material) {
      case FewchursStyle.material:
        return false;
      case FewchursStyle.cupertino:
        return true;
      case FewchursStyle.adaptive:
        final platform = Theme.of(context).platform;
        return platform == TargetPlatform.iOS ||
            platform == TargetPlatform.macOS;
    }
  }
}

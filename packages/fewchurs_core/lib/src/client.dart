import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'events.dart';
import 'identity.dart';
import 'json.dart';
import 'logger.dart';
import 'models.dart';

const fewchursCoreVersion = '1.1.0';

typedef _Response = ({Map<String, Object?> json, String deviceId});

class FewchursClient {
  FewchursClient({
    required this.apiKey,
    String? baseUrl,
    http.Client? httpClient,
    DeviceIdentity? identity,
    this.sdkHeader = 'dart/$fewchursCoreVersion',
    this.localeProvider,
    this.logger = const FewchursLogger(),
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 400),
    this.onEvent,
  })  : baseUrl = _trimSlash(baseUrl ?? defaultBaseUrl),
        identity = identity ?? DeviceIdentity(),
        _http = httpClient ?? http.Client(),
        _ownsHttp = httpClient == null;

  static const defaultBaseUrl = 'https://www.fewchurs.shop/api/v1';

  static const titleMin = 3;
  static const titleMax = 100;
  static const descriptionMax = 1000;
  static const commentMax = 1000;
  static const authorNameMax = 60;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());

  final String apiKey;
  final String baseUrl;
  final DeviceIdentity identity;
  final String sdkHeader;
  final String? Function()? localeProvider;
  final FewchursLogger logger;
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;
  final void Function(FewchursEvent event)? onEvent;

  final http.Client _http;
  final bool _ownsHttp;
  Future<RemoteConfig>? _config;

  Future<RemoteConfig> getConfig({bool refresh = false}) {
    final cached = _config;
    if (cached != null && !refresh) return cached;
    final future = _send('GET', '/config', retry: true)
        .then((r) => RemoteConfig.fromJson(r.json));
    _config = future;
    future.then<void>((_) {}, onError: (Object _) {
      if (identical(_config, future)) _config = null;
    });
    return future;
  }

  Future<FeaturePage> listFeatures({
    FeatureSort sort = FeatureSort.top,
    int limit = 20,
    String? cursor,
    Set<FeatureStatus>? statuses,
  }) async {
    final r = await _send('GET', '/features', retry: true, query: {
      'sort': sort.wireName,
      'limit': '${limit.clamp(1, 100)}',
      if (cursor != null) 'cursor': cursor,
      if (statuses != null && statuses.isNotEmpty)
        'status': statuses.map((s) => s.wireName).join(','),
    });
    var features = readList(r.json['features'])
        .map((j) => Feature.fromJson(j, deviceId: r.deviceId));
    if (statuses != null && statuses.isNotEmpty) {
      features = features.where((f) => statuses.contains(f.status));
    }
    return FeaturePage(
      features: features.toList(),
      nextCursor: readOptionalString(r.json['nextCursor']),
    );
  }

  /// Fetches one request, e.g. for a deep link or a notification. A request
  /// hidden by the board's plan is returned only to the device that submitted
  /// it; everyone else gets a [FewchursNotFoundException].
  Future<Feature> getFeature(String featureId) async {
    final r = await _send(
        'GET', '/features/${Uri.encodeComponent(featureId)}',
        retry: true);
    final json = r.json['feature'];
    return Feature.fromJson(
        json is Map<String, Object?> ? json : r.json,
        deviceId: r.deviceId);
  }

  Future<Feature> submitFeature({
    required String title,
    String description = '',
    String? email,
    bool? isSubscriber,
  }) async {
    final t = title.trim();
    final d = description.trim();
    final e = email?.trim();
    if (t.length < titleMin || t.length > titleMax) {
      throw _invalid('Title must be $titleMin–$titleMax characters.');
    }
    if (d.length > descriptionMax) {
      throw _invalid('Description must be at most $descriptionMax characters.');
    }
    if (e != null && e.isNotEmpty && !isValidEmail(e)) {
      throw _invalid('Enter a valid email address.');
    }
    final r = await _send('POST', '/features', body: {
      'title': t,
      'description': d,
      if (e != null && e.isNotEmpty) 'email': e,
      if (isSubscriber != null) 'isSubscriber': isSubscriber,
    });
    final feature = Feature.fromJson(r.json, deviceId: r.deviceId);
    onEvent?.call(FeatureSubmitted(feature.id));
    return feature;
  }

  Future<VoteResult> vote(String featureId) => _vote(featureId, true);

  Future<VoteResult> unvote(String featureId) => _vote(featureId, false);

  Future<VoteResult> _vote(String featureId, bool add) async {
    final r = await _send(add ? 'POST' : 'DELETE',
        '/features/${Uri.encodeComponent(featureId)}/vote',
        retry: true);
    final result = VoteResult.fromJson(r.json);
    onEvent?.call(Voted(featureId, voted: result.hasVoted));
    return result;
  }

  Future<void> follow(String featureId, {required String email}) async {
    if (!isValidEmail(email)) throw _invalid('Enter a valid email address.');
    await _send('POST', '/features/${Uri.encodeComponent(featureId)}/follow',
        body: {'email': email.trim()});
    onEvent?.call(Followed(featureId, following: true));
  }

  Future<void> unfollow(String featureId) async {
    await _send(
        'DELETE', '/features/${Uri.encodeComponent(featureId)}/follow',
        retry: true);
    onEvent?.call(Followed(featureId, following: false));
  }

  Future<CommentPage> listComments(
    String featureId, {
    int limit = 20,
    String? cursor,
  }) async {
    final r = await _send(
        'GET', '/features/${Uri.encodeComponent(featureId)}/comments',
        retry: true,
        query: {
          'limit': '${limit.clamp(1, 100)}',
          if (cursor != null) 'cursor': cursor,
        });
    return CommentPage(
      comments: readList(r.json['comments'])
          .map((j) => Comment.fromJson(j, deviceId: r.deviceId))
          .toList(),
      nextCursor: readOptionalString(r.json['nextCursor']),
    );
  }

  Future<Comment> addComment(
    String featureId, {
    required String text,
    String? authorName,
  }) async {
    final t = text.trim();
    final name = authorName?.trim();
    if (t.isEmpty || t.length > commentMax) {
      throw _invalid('Comment must be 1–$commentMax characters.');
    }
    if (name != null && name.length > authorNameMax) {
      throw _invalid('Name must be at most $authorNameMax characters.');
    }
    final r = await _send('POST', '/comments', body: {
      'featureId': featureId,
      'text': t,
      if (name != null && name.isNotEmpty) 'authorName': name,
    });
    final comment = Comment.fromJson(r.json, deviceId: r.deviceId);
    onEvent?.call(Commented(featureId, comment.id));
    return comment;
  }

  void close() {
    if (_ownsHttp) _http.close();
  }

  FewchursValidationException _invalid(String message) {
    final e = FewchursValidationException(message);
    onEvent?.call(FewchursErrorEvent(e));
    return e;
  }

  Future<_Response> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, Object?>? body,
    bool retry = false,
  }) async {
    final deviceId = await identity.id;
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    String? locale;
    try {
      locale = localeProvider?.call();
    } catch (_) {}
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'X-Device-Id': deviceId,
      'X-Fewchurs-Sdk': sdkHeader,
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
      if (locale != null && locale.isNotEmpty) 'Accept-Language': locale,
    };

    var attempt = 0;
    while (true) {
      try {
        final json = await _once(method, uri, headers, body);
        return (json: json, deviceId: deviceId);
      } on FewchursException catch (e) {
        final retryable =
            e is FewchursNetworkException || e is FewchursServerException;
        if (!retry || !retryable || attempt >= maxRetries) {
          _report(e);
          rethrow;
        }
        attempt++;
        logger.debug('Retrying $method $path (attempt $attempt)');
        await Future<void>.delayed(retryDelay * (attempt * attempt));
      }
    }
  }

  Future<Map<String, Object?>> _once(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, Object?>? body,
  ) async {
    logger.debug('$method $uri');
    final http.Response res;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _http.send(request).timeout(timeout);
      res = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const FewchursNetworkException('Request timed out.');
    } catch (e) {
      throw FewchursNetworkException('Network error: $e');
    }

    Object? decoded;
    if (res.bodyBytes.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      } on FormatException {
        decoded = null;
      }
    }
    logger.debug('${res.statusCode} $method ${uri.path}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded is Map<String, Object?>) return decoded;
      throw FewchursUnknownException('Unexpected response body.',
          statusCode: res.statusCode);
    }
    throw _mapError(res.statusCode, decoded);
  }

  FewchursException _mapError(int status, Object? body) {
    String? code;
    var message = 'HTTP $status';
    if (body is Map && body['error'] is Map) {
      final error = body['error'] as Map;
      if (error['code'] is String) code = error['code'] as String;
      if (error['message'] is String) message = error['message'] as String;
    }
    return switch ((code, status)) {
      ('invalid_key' || 'unauthorized', _) || (null, 401) =>
        FewchursInvalidApiKeyException(message, statusCode: status),
      ('validation_failed' || 'missing_device_id', _) || (null, 400) =>
        FewchursValidationException(message, statusCode: status),
      ('rate_limited', _) || (null, 429) =>
        FewchursRateLimitedException(message, statusCode: status),
      ('limit_reached', _) || (null, 402) =>
        FewchursLimitReachedException(message, statusCode: status),
      ('not_found', _) || (null, 404) =>
        FewchursNotFoundException(message, statusCode: status),
      ('internal', _) || (_, >= 500) =>
        FewchursServerException(message, statusCode: status),
      // A generic error, so the sealed exception set stays stable.
      ('forbidden', _) || (null, 403) =>
        FewchursUnknownException(message, statusCode: status),
      _ => FewchursUnknownException(message, statusCode: status),
    };
  }

  void _report(FewchursException e) {
    if (e is FewchursInvalidApiKeyException) {
      logger.error('Invalid or inactive API key. Check the key passed to '
          'Fewchurs.configure() against your Fewchurs dashboard.');
    } else {
      logger.error(e.toString());
    }
    onEvent?.call(FewchursErrorEvent(e));
  }

  static String _trimSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}

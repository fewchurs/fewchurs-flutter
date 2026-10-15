import 'dart:convert';

import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

Map<String, Object?> featureJson(String id, {String status = 'open'}) => {
      'id': id,
      'title': 'Title $id',
      'description': '',
      'status': status,
      'upvoteCount': 3,
      'commentCount': 1,
      'followerCount': 0,
      'authorDeviceId': 'device-1',
      'hasVoted': false,
      'isFollowing': false,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'someNewField': 42,
    };

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

FewchursClient makeClient(MockClientHandler handler) => FewchursClient(
      apiKey: 'fr_live_test',
      httpClient: MockClient(handler),
      identity: DeviceIdentity(resolver: () => 'device-1'),
      retryDelay: Duration.zero,
      logger: const FewchursLogger(level: FewchursLogLevel.none),
    );

void main() {
  test('sends auth, device and sdk headers', () async {
    late http.Request captured;
    final client = makeClient((req) async {
      captured = req;
      return jsonResponse({'features': [], 'nextCursor': null});
    });
    await client.listFeatures(sort: FeatureSort.newest, limit: 500);
    expect(captured.headers['Authorization'], 'Bearer fr_live_test');
    expect(captured.headers['X-Device-Id'], 'device-1');
    expect(captured.headers['X-Fewchurs-Sdk'], startsWith('dart/'));
    expect(captured.url.queryParameters['sort'], 'new');
    expect(captured.url.queryParameters['limit'], '100');
  });

  test('parses features, ignores unknown fields and computes isMine', () async {
    final client = makeClient((_) async => jsonResponse({
          'features': [
            featureJson('a'),
            featureJson('b', status: 'shipped_to_mars'),
          ],
          'nextCursor': 'b',
        }));
    final page = await client.listFeatures();
    expect(page.features, hasLength(2));
    expect(page.features.first.isMine, isTrue);
    expect(page.features.last.status, FeatureStatus.unknown);
    expect(page.nextCursor, 'b');
  });

  test('maps error envelopes to typed exceptions', () async {
    Future<FewchursException> errorFor(String code, int status) async {
      final client = makeClient((_) async => jsonResponse({
            'error': {'code': code, 'message': 'msg'}
          }, status));
      try {
        await client.vote('x');
      } on FewchursException catch (e) {
        return e;
      }
      fail('expected exception');
    }

    expect(await errorFor('invalid_key', 401),
        isA<FewchursInvalidApiKeyException>());
    expect(await errorFor('validation_failed', 400),
        isA<FewchursValidationException>());
    expect(await errorFor('rate_limited', 429),
        isA<FewchursRateLimitedException>());
    expect(await errorFor('limit_reached', 402),
        isA<FewchursLimitReachedException>());
    expect(await errorFor('not_found', 404), isA<FewchursNotFoundException>());
    expect(await errorFor('unauthorized', 401),
        isA<FewchursInvalidApiKeyException>());
    expect(await errorFor('forbidden', 403), isA<FewchursUnknownException>());
  });

  test('defaults to the live Fewchurs server', () async {
    expect(FewchursClient.defaultBaseUrl, 'https://www.fewchurs.shop/api/v1');
    late Uri url;
    final client = FewchursClient(
      apiKey: 'k',
      identity: DeviceIdentity(resolver: () => 'd'),
      logger: const FewchursLogger(level: FewchursLogLevel.none),
      httpClient: MockClient((req) async {
        url = req.url;
        return jsonResponse({'showBranding': false});
      }),
    );
    await client.getConfig();
    expect(url.toString(), 'https://www.fewchurs.shop/api/v1/config');
  });

  test('getFeature fetches one request', () async {
    late http.Request captured;
    final client = makeClient((req) async {
      captured = req;
      return jsonResponse(featureJson('a/b'));
    });
    final feature = await client.getFeature('a/b');
    expect(captured.method, 'GET');
    expect(captured.url.path, endsWith('/features/a%2Fb'));
    expect(feature.id, 'a/b');
    expect(feature.isMine, isTrue);

    final wrapped =
        makeClient((_) async => jsonResponse({'feature': featureJson('c')}));
    expect((await wrapped.getFeature('c')).id, 'c');

    final missing = makeClient((_) async => jsonResponse({
          'error': {'code': 'not_found', 'message': 'gone'}
        }, 404));
    await expectLater(
        missing.getFeature('x'), throwsA(isA<FewchursNotFoundException>()));
  });

  test('RemoteConfig shows branding unless the server hides it', () {
    expect(const RemoteConfig().showBranding, isTrue);
    expect(RemoteConfig.fromJson(const {}).showBranding, isTrue);
    expect(RemoteConfig.fromJson(const {'showBranding': false}).showBranding,
        isFalse);
  });

  test('retries GET on 5xx but never retries POST /features', () async {
    var gets = 0;
    var posts = 0;
    final client = makeClient((req) async {
      if (req.method == 'GET') gets++;
      if (req.method == 'POST') posts++;
      return jsonResponse({
        'error': {'code': 'internal', 'message': 'boom'}
      }, 500);
    });
    await expectLater(
        client.listFeatures(), throwsA(isA<FewchursServerException>()));
    await expectLater(client.submitFeature(title: 'Dark mode'),
        throwsA(isA<FewchursServerException>()));
    expect(gets, 3);
    expect(posts, 1);
  });

  test('network failures become FewchursNetworkException', () async {
    final client =
        makeClient((_) async => throw http.ClientException('no route'));
    await expectLater(client.getConfig(),
        throwsA(isA<FewchursNetworkException>()));
  });

  test('validates input before hitting the network', () async {
    var calls = 0;
    final client = makeClient((_) async {
      calls++;
      return jsonResponse({});
    });
    await expectLater(client.submitFeature(title: 'hi'),
        throwsA(isA<FewchursValidationException>()));
    await expectLater(client.follow('x', email: 'nope'),
        throwsA(isA<FewchursValidationException>()));
    await expectLater(client.addComment('x', text: '   '),
        throwsA(isA<FewchursValidationException>()));
    expect(calls, 0);
  });

  test('emits events for mutations', () async {
    final events = <FewchursEvent>[];
    final client = FewchursClient(
      apiKey: 'k',
      identity: DeviceIdentity(resolver: () => 'd'),
      onEvent: events.add,
      httpClient: MockClient(
          (_) async => jsonResponse({'upvoteCount': 4, 'hasVoted': true})),
    );
    final result = await client.vote('f1');
    expect(result.upvoteCount, 4);
    expect(events.single, isA<Voted>());
  });
}

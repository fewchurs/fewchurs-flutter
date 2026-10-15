import 'dart:convert';

import 'package:fewchurs/fewchurs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> featureJson(String id,
        {int votes = 0, bool voted = false, String status = 'open'}) =>
    {
      'id': id,
      'title': 'Feature $id',
      'description': '',
      'status': status,
      'upvoteCount': votes,
      'hasVoted': voted,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
    };

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

FewchursClient clientFor(MockClientHandler handler) => FewchursClient(
      apiKey: 'fr_test',
      httpClient: MockClient(handler),
      identity: DeviceIdentity(resolver: () => 'device'),
      retryDelay: Duration.zero,
      logger: const FewchursLogger(level: FewchursLogLevel.none),
    );

Future<void> settle(BoardController c) async {
  while (c.state is BoardLoading) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('loads, hides declined and pages', () async {
    final client = clientFor((req) async {
      final cursor = req.url.queryParameters['cursor'];
      return cursor == null
          ? json({
              'features': [
                featureJson('a'),
                featureJson('x', status: 'declined'),
              ],
              'nextCursor': 'x',
            })
          : json({
              'features': [featureJson('b')],
              'nextCursor': null,
            });
    });
    final board = BoardController(client: client);
    await settle(board);
    expect(board.features.map((f) => f.id), ['a']);
    expect((board.state as BoardContent).canLoadMore, isTrue);

    await board.loadMore();
    expect(board.features.map((f) => f.id), ['a', 'b']);
    expect((board.state as BoardContent).canLoadMore, isFalse);
    board.dispose();
  });

  test('optimistic vote reconciles with the server count', () async {
    final client = clientFor((req) async {
      if (req.method == 'GET') {
        return json({
          'features': [featureJson('a', votes: 4)]
        });
      }
      return json({'upvoteCount': 10, 'hasVoted': true});
    });
    final board = BoardController(client: client);
    await settle(board);

    final pending = board.toggleVote('a');
    expect(board.featureById('a')!.hasVoted, isTrue);
    expect(board.featureById('a')!.upvoteCount, 5);
    await pending;
    expect(board.featureById('a')!.upvoteCount, 10);
    board.dispose();
  });

  test('failed vote rolls back and reports the error', () async {
    final client = clientFor((req) async {
      if (req.method == 'GET') {
        return json({
          'features': [featureJson('a', votes: 4)]
        });
      }
      return json({
        'error': {'code': 'rate_limited', 'message': 'no'}
      }, 429);
    });
    final board = BoardController(client: client);
    await settle(board);
    final errors = <FewchursException>[];
    board.actionErrors.listen(errors.add);

    await board.toggleVote('a');
    await Future<void>.delayed(Duration.zero);
    expect(board.featureById('a')!.hasVoted, isFalse);
    expect(board.featureById('a')!.upvoteCount, 4);
    expect(errors.single, isA<FewchursRateLimitedException>());
    board.dispose();
  });

  test('first load error surfaces as BoardError', () async {
    final client =
        clientFor((_) async => throw http.ClientException('offline'));
    final board = BoardController(client: client);
    await settle(board);
    final state = board.state;
    expect(state, isA<BoardError>());
    expect((state as BoardError).error, isA<FewchursNetworkException>());
    board.dispose();
  });
}

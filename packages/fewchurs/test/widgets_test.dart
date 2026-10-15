import 'dart:convert';

import 'package:fewchurs/fewchurs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  var requests = 0;

  setUp(() {
    requests = 0;
    SharedPreferences.setMockInitialValues({});
    Fewchurs.configure(
      apiKey: 'fr_test',
      logLevel: FewchursLogLevel.none,
      httpClient: MockClient((req) async {
        requests++;
        return http.Response(
            jsonEncode({'features': [], 'showBranding': true}), 200,
            headers: {'content-type': 'application/json'});
      }),
    );
  });

  tearDown(Fewchurs.reset);

  testWidgets('submit form validates before sending', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FewchursSubmitForm()),
    ));
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(find.text('Use at least 3 characters.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('vote button exposes semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FewchursVoteButton(
          state: VoteButtonState(
              voted: true, count: 12, hideCount: false, onPressed: () {}),
        ),
      ),
    ));
    expect(find.bySemanticsLabel('Upvote, 12 votes, voted'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('board shows the empty state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FewchursBoard()));
    await tester.pumpAndSettle();
    expect(find.text('No requests yet'), findsWidgets);
    expect(find.text('Suggest a feature'), findsOneWidget);
  });

  testWidgets('custom strings override defaults', (tester) async {
    Fewchurs.configure(
      apiKey: 'fr_test',
      logLevel: FewchursLogLevel.none,
      strings: const FewchursStrings(boardTitle: 'Ideas'),
      httpClient:
          MockClient((_) async => http.Response('{"features":[]}', 200)),
    );
    await tester.pumpWidget(const MaterialApp(home: FewchursBoard()));
    await tester.pumpAndSettle();
    expect(find.text('Ideas'), findsOneWidget);
  });

  testWidgets('a wrong API key shows the invalid-key message', (tester) async {
    Fewchurs.configure(
      apiKey: 'fr_live_wrong',
      logLevel: FewchursLogLevel.none,
      httpClient: MockClient((_) async => http.Response(
          jsonEncode({
            'error': {'code': 'invalid_key', 'message': 'Invalid API key'}
          }),
          401)),
    );
    await tester.pumpWidget(const MaterialApp(home: FewchursBoard()));
    await tester.pumpAndSettle();
    expect(
        find.text('Invalid API key. Check the key in your Fewchurs dashboard.'),
        findsOneWidget);
    expect(find.text('Something went wrong. Try again.'), findsNothing);
  });

  testWidgets('ignores the removed Roadmap tab', (tester) async {
    final statuses = <String?>[];
    Fewchurs.configure(
      apiKey: 'fr_test',
      logLevel: FewchursLogLevel.none,
      board: const BoardOptions(
        // ignore: deprecated_member_use_from_same_package
        tabs: [BoardTab.top, BoardTab.newest, BoardTab.roadmap],
      ),
      httpClient: MockClient((req) async {
        statuses.add(req.url.queryParameters['status']);
        return http.Response('{"features":[]}', 200);
      }),
    );
    await tester.pumpWidget(const MaterialApp(home: FewchursBoard()));
    await tester.pumpAndSettle();
    expect(find.text('Top'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Roadmap'), findsNothing);
    expect(statuses.whereType<String>(), isEmpty);
  });

  testWidgets('shows the badge when /config fails', (tester) async {
    Fewchurs.configure(
      apiKey: 'fr_test',
      logLevel: FewchursLogLevel.none,
      httpClient: MockClient((req) async => req.url.path.endsWith('/config')
          ? http.Response('oops', 500)
          : http.Response('{"features":[]}', 200)),
    );
    await tester.pumpWidget(const MaterialApp(home: FewchursBoard()));
    await tester.pumpAndSettle();
    expect(find.text('Powered by Fewchurs'), findsNothing); // still retrying
    await tester.pump(const Duration(seconds: 3)); // past both retries
    await tester.pumpAndSettle();
    expect(find.text('Powered by Fewchurs'), findsOneWidget);
  });

  testWidgets('hides the badge when the server says so', (tester) async {
    Fewchurs.configure(
      apiKey: 'fr_test',
      logLevel: FewchursLogLevel.none,
      httpClient: MockClient((req) async => http.Response(
          jsonEncode({'features': [], 'showBranding': false}), 200)),
    );
    await tester.pumpWidget(const MaterialApp(home: FewchursBoard()));
    await tester.pumpAndSettle();
    expect(find.text('Powered by Fewchurs'), findsNothing);
  });

  testWidgets('initialFeatureId opens that request', (tester) async {
    final paths = <String>[];
    Fewchurs.configure(
      apiKey: 'fr_test',
      logLevel: FewchursLogLevel.none,
      httpClient: MockClient((req) async {
        paths.add(req.url.path);
        final body = req.url.path.endsWith('/features/f1')
            ? {
                'id': 'f1',
                'title': 'Dark mode please',
                'status': 'open',
                'createdAt': '2026-01-01T00:00:00.000Z',
                'updatedAt': '2026-01-01T00:00:00.000Z',
              }
            : {'features': [], 'comments': []};
        return http.Response(jsonEncode(body), 200);
      }),
    );
    await tester.pumpWidget(
        const MaterialApp(home: FewchursBoard(initialFeatureId: 'f1')));
    await tester.pumpAndSettle();
    expect(paths, contains(endsWith('/features/f1')));
    expect(find.text('Dark mode please'), findsWidgets);
  });

  testWidgets('initialFeatureId shows a message when not found',
      (tester) async {
    Fewchurs.configure(
      apiKey: 'fr_test',
      logLevel: FewchursLogLevel.none,
      httpClient: MockClient((req) async => req.url.path.endsWith('/features/x')
          ? http.Response(
              jsonEncode({
                'error': {'code': 'not_found', 'message': 'gone'}
              }),
              404)
          : http.Response('{"features":[]}', 200)),
    );
    await tester.pumpWidget(
        const MaterialApp(home: FewchursBoard(initialFeatureId: 'x')));
    await tester.pumpAndSettle();
    expect(find.text('This request no longer exists.'), findsOneWidget);
  });
}

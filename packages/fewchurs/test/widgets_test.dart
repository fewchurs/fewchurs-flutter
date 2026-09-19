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
      httpClient: MockClient((_) async => http.Response('{"features":[]}', 200)),
    );
    await tester.pumpWidget(const MaterialApp(home: FewchursBoard()));
    await tester.pumpAndSettle();
    expect(find.text('Ideas'), findsOneWidget);
  });
}

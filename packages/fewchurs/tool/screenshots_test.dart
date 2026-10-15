// Renders the README and pub.dev screenshots into doc/screenshots/ with
// sample data. Run from packages/fewchurs:
//
//   flutter test tool/screenshots_test.dart --update-goldens
//
// It lives outside test/ so CI doesn't compare images across machines.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';

import 'package:fewchurs/fewchurs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _seed = Color(0xFFED5F18);
const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

Map<String, Object?> _feature(
  String id,
  String title,
  String description,
  int votes, {
  String status = 'open',
  bool voted = false,
  int comments = 0,
}) =>
    {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'upvoteCount': votes,
      'commentCount': comments,
      'hasVoted': voted,
      'createdAt': '2026-10-01T00:00:00.000Z',
      'updatedAt': '2026-10-01T00:00:00.000Z',
    };

final _features = [
  _feature('1', 'Dark mode', 'A dark theme for working late at night.', 128,
      voted: true, comments: 3),
  _feature('2', 'Export to CSV',
      'Download every task and its due date as a spreadsheet.', 86,
      status: 'planned', comments: 5),
  _feature('3', 'Recurring tasks', 'Repeat a task every week or month.', 64,
      status: 'in_progress', comments: 2),
  _feature('4', 'Calendar sync', 'Show tasks in Google and Apple Calendar.', 41,
      comments: 1),
  _feature('5', 'Home screen widget',
      "See today's tasks without opening the app.", 27,
      status: 'done'),
  _feature('6', 'Shared lists', 'Plan groceries together with family.', 19),
];

final _comments = [
  {
    'id': 'c1',
    'text': 'Yes please! My eyes hurt when I plan at night.',
    'authorName': 'Sam',
    'createdAt': '2026-10-02T00:00:00.000Z',
  },
  {
    'id': 'c2',
    'text': "It's next on our list. Thanks for all the votes!",
    'authorName': 'Taskly team',
    'isDeveloper': true,
    'createdAt': '2026-10-03T00:00:00.000Z',
  },
  {
    'id': 'c3',
    'text': 'Would love an automatic option that follows the system.',
    'authorName': 'Priya',
    'createdAt': '2026-10-04T00:00:00.000Z',
  },
];

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/Applications/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> bytes(String file) async =>
      ByteData.sublistView(File('$dir/$file').readAsBytesSync());
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    roboto.addFont(bytes('Roboto-$w.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')
        ..addFont(bytes('MaterialIcons-Regular.otf')))
      .load();
}

ThemeData _theme(Brightness brightness) => ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorSchemeSeed: _seed,
      brightness: brightness,
    );

/// A plain host app, so sheets have something to sit over.
class _HostApp extends StatelessWidget {
  const _HostApp({required this.onOpen});

  final void Function(BuildContext context) onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taskly')),
      body: ListView(
        children: [
          for (final task in [
            'Book flights for the trip',
            'Review the Q4 roadmap',
            'Renew the gym membership',
            'Call the plumber',
            'Send invoices',
          ])
            CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: Text(task),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => onOpen(context),
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: const Text('Feature requests'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Fewchurs.configure(
      apiKey: 'fr_live_screenshots',
      logLevel: FewchursLogLevel.none,
      httpClient: MockClient((req) async {
        final path = req.url.path;
        final Object body;
        if (path.endsWith('/config')) {
          body = {'showBranding': true};
        } else if (path.endsWith('/comments')) {
          body = {'comments': _comments};
        } else if (path.endsWith('/features/1')) {
          body = _features.first;
        } else if (req.url.queryParameters['sort'] == 'new') {
          body = {'features': _features.reversed.toList()};
        } else {
          body = {'features': _features};
        }
        return http.Response(jsonEncode(body), 200,
            headers: {'content-type': 'application/json'});
      }),
    );
  });

  tearDown(Fewchurs.reset);

  Future<void> shoot(
    WidgetTester tester,
    String name, {
    required Size size,
    required Widget home,
    Brightness brightness = Brightness.light,
    Future<void> Function(WidgetTester tester)? act,
  }) async {
    tester.view
      ..physicalSize = size * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    debugDisableShadows = false;
    try {
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme(brightness),
        home: home,
      ));
      await tester.pumpAndSettle();
      await act?.call(tester);
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../doc/screenshots/$name.png'));
    } finally {
      debugDisableShadows = true;
    }
  }

  Future<void> openHost(WidgetTester tester) async {
    await tester.tap(find.text('Feature requests'));
  }

  testWidgets('board', (tester) async {
    await shoot(tester, 'board', size: _phone, home: const FewchursBoard());
  });

  testWidgets('detail', (tester) async {
    await shoot(tester, 'detail',
        size: _phone, home: const FewchursBoard(initialFeatureId: '1'));
  });

  testWidgets('submit', (tester) async {
    await shoot(tester, 'submit', size: _phone, home: const FewchursBoard(),
        act: (tester) async {
      await tester.tap(find.text('Suggest a feature'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextField).first, 'Offline mode for flights');
      await tester.enterText(find.byType(TextField).at(1),
          'Let me add and check off tasks without a connection.');
      FocusManager.instance.primaryFocus?.unfocus();
    });
  });

  testWidgets('dark', (tester) async {
    await shoot(tester, 'dark',
        size: _phone, brightness: Brightness.dark, home: const FewchursBoard());
  });

  testWidgets('side_sheet', (tester) async {
    await shoot(tester, 'side_sheet',
        size: _desktop,
        home: _HostApp(onOpen: (context) => Fewchurs.showBoardSheet(context)),
        act: openHost);
  });

  testWidgets('wide', (tester) async {
    await shoot(tester, 'wide',
        size: const Size(1440, 900),
        home: const FewchursBoard(initialFeatureId: '1'));
  });
}

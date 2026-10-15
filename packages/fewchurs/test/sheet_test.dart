import 'dart:convert';

import 'package:fewchurs/fewchurs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Fewchurs.configure(
      apiKey: 'fr_test',
      logLevel: FewchursLogLevel.none,
      httpClient: MockClient((req) async {
        final body = req.url.path.endsWith('/features')
            ? {
                'features': [
                  {
                    'id': 'f1',
                    'title': 'Dark mode',
                    'status': 'open',
                    'createdAt': '2026-01-01T00:00:00.000Z',
                    'updatedAt': '2026-01-01T00:00:00.000Z',
                  }
                ]
              }
            : {'comments': [], 'showBranding': false};
        return http.Response(jsonEncode(body), 200);
      }),
    );
  });

  tearDown(Fewchurs.reset);

  void setScreen(WidgetTester tester, Size size) {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpAt(WidgetTester tester, Size size,
      {FewchursSheetPosition position = FewchursSheetPosition.adaptive}) async {
    setScreen(tester, size);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                Fewchurs.showBoardSheet(context, position: position),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('wide screens get a side sheet', (tester) async {
    await pumpAt(tester, const Size(1280, 800));
    expect(find.byType(BottomSheet), findsNothing);
    final board = tester.getRect(find.byType(FewchursBoard));
    expect(board.width, 440);
    expect(board.right, 1280);
    expect(board.height, 800);
  });

  testWidgets('phones get a bottom sheet', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('position overrides the adaptive choice', (tester) async {
    await pumpAt(tester, const Size(1280, 800),
        position: FewchursSheetPosition.bottom);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('a request opens inside the side sheet', (tester) async {
    await pumpAt(tester, const Size(1280, 800));
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    final detail = tester.getRect(find.byType(FewchursFeatureDetail));
    expect(detail.width, 440);
    expect(detail.right, 1280);

    // Back returns to the list, still inside the sheet.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(FewchursFeatureDetail), findsNothing);
    expect(find.byType(FewchursBoard), findsOneWidget);
  });

  testWidgets('the close button closes the side sheet', (tester) async {
    await pumpAt(tester, const Size(1280, 800));
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(FewchursBoard), findsNothing);
  });

  testWidgets('submit form is a dialog on wide screens', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showFewchursSubmitSheet(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('submit form stays inside the side sheet', (tester) async {
    await pumpAt(tester, const Size(1280, 800));
    await tester.tap(find.text('Suggest a feature').last);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.getRect(find.byType(FewchursSubmitForm)).left,
        greaterThanOrEqualTo(1280 - 440));
  });
}

# Fewchurs for Flutter

[![pub package](https://img.shields.io/pub/v/fewchurs.svg)](https://pub.dev/packages/fewchurs)
[![CI](https://github.com/fewchurs/fewchurs-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/fewchurs/fewchurs-flutter/actions/workflows/ci.yml)

Add a feature-request board to your Flutter app with one dependency and one line of code. Users browse ideas, vote, comment, follow requests and suggest new ones, and you see it all in the [Fewchurs dashboard](https://www.fewchurs.shop).

<p>
  <img src="https://raw.githubusercontent.com/fewchurs/fewchurs-flutter/main/packages/fewchurs/doc/screenshots/board.png" width="240" alt="The board with votes and statuses">
  <img src="https://raw.githubusercontent.com/fewchurs/fewchurs-flutter/main/packages/fewchurs/doc/screenshots/detail.png" width="240" alt="A request with comments">
  <img src="https://raw.githubusercontent.com/fewchurs/fewchurs-flutter/main/packages/fewchurs/doc/screenshots/submit.png" width="240" alt="The submit form">
</p>

<img src="https://raw.githubusercontent.com/fewchurs/fewchurs-flutter/main/packages/fewchurs/doc/screenshots/side_sheet.png" width="740" alt="The board as a side sheet on desktop">

- **Ready-made board:** Top and New tabs, instant voting, comments, follow by email, pull to refresh and infinite scroll.
- **Fits every screen:** a bottom sheet on phones, a side sheet on web and desktop, and list and detail side by side on wide pages.
- **Matches your app:** reads your `ThemeData` (light and dark). Change one color, a few tokens, or build a fully custom UI.
- **No analytics, no tracking:** a random per-device ID, and email only if the user types it.

Runs on **Android, iOS, web, macOS, Windows and Linux**.
Requires **Flutter 3.10+** and **Dart 3.0+**.

---

## Contents

1. [Installation](#1-installation)
2. [Platform setup](#2-platform-setup)
3. [Quick start](#3-quick-start)
4. [Showing the board](#4-showing-the-board)
5. [Submitting from your own UI](#5-submitting-from-your-own-ui)
6. [Configuration reference](#6-configuration-reference)
7. [Theming](#7-theming)
8. [Text and translations](#8-text-and-translations)
9. [Replacing parts of the UI (builders)](#9-replacing-parts-of-the-ui-builders)
10. [Headless: build your own UI](#10-headless-build-your-own-ui)
11. [User identity](#11-user-identity)
12. [Events and analytics](#12-events-and-analytics)
13. [Error handling](#13-error-handling)
14. [Privacy and security](#14-privacy-and-security)
15. [Troubleshooting](#15-troubleshooting)
16. [Development](#16-development)

---

## 1. Installation

### Get an API key

Open the [Fewchurs dashboard](https://www.fewchurs.shop), select your app and copy the API key (`fr_live_…`) from its settings. The key is shown only once. If you lose it, generate a new one.

### Add the package

```bash
flutter pub add fewchurs
```

That's it: `fewchurs_core` is installed with it.

To try an unreleased version from GitHub, see [Development](#16-development).

### Import

```dart
import 'package:fewchurs/fewchurs.dart';
```

This single import gives you everything: widgets, theming, controllers, the API client, models and errors.

---

## 2. Platform setup

| Platform | What to do |
|---|---|
| **Android** | Add `<uses-permission android:name="android.permission.INTERNET"/>` to `android/app/src/main/AndroidManifest.xml`. Debug builds include it automatically, but **release builds need it**, and forgetting it is the most common "works in debug, fails in release" issue. |
| **iOS** | Nothing. |
| **macOS** | Add `<key>com.apple.security.network.client</key><true/>` to **both** `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`. |
| **Web** | Nothing. The device ID is stored per browser, so clearing site data resets it. |
| **Windows / Linux** | Nothing. |

---

## 3. Quick start

```dart
import 'package:fewchurs/fewchurs.dart';
import 'package:flutter/material.dart';

void main() {
  Fewchurs.configure(apiKey: 'fr_live_xxx');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Fewchurs.showBoard(context),
              child: const Text('Feature requests'),
            ),
          ),
        ),
      ),
    );
  }
}
```

`configure` is synchronous and makes no network calls, so it doesn't slow down app startup.

> Tip: keep the key out of source control with
> `flutter run --dart-define=FEWCHURS_API_KEY=fr_live_xxx` and
> `const String.fromEnvironment('FEWCHURS_API_KEY')`.

---

## 4. Showing the board

You can present the board in three ways. All three share the same features: Top and New tabs, instant voting, comments, follow, submit, pull to refresh and infinite scroll.

### As a full-screen page

```dart
Fewchurs.showBoard(context);
```

### As a sheet

```dart
Fewchurs.showBoardSheet(context);
```

The sheet adapts to the screen. On phones it's a bottom sheet. On screens 840 px and wider (web, desktop, tablets in landscape) it slides in from the side at full height, and requests and the submit form open inside it.

```dart
Fewchurs.showBoardSheet(context, heightFactor: 0.8);       // bottom sheet height on phones
Fewchurs.showBoardSheet(context, sideSheetWidth: 480);     // side sheet width on wide screens
Fewchurs.showBoardSheet(context, position: FewchursSheetPosition.side);   // always a side sheet
Fewchurs.showBoardSheet(context, position: FewchursSheetPosition.bottom); // always a bottom sheet
```

The breakpoint is `BoardOptions.wideLayoutBreakpoint`.

### As a widget anywhere: a tab, a drawer page or a route

```dart
const FewchursBoard();

// Inside a bottom navigation tab (no close button):
const FewchursBoard(showCloseButton: false);

// Inside a page that already has its own app bar:
const FewchursBoard(showAppBar: false);
```

With **go_router** (no extra dependency needed):

```dart
GoRoute(path: '/ideas', builder: (context, state) => const FewchursBoard());
```

### Open a specific request

For deep links and notifications, pass the request's ID. The board opens and then shows that request:

```dart
Fewchurs.showBoard(context, board: FewchursBoard(showCloseButton: true, initialFeatureId: id));
```

If the request was deleted, or is hidden by the board's plan, the user sees "This request no longer exists." A request hidden by the plan is still returned to the device that submitted it.

### Only the submit form

```dart
final feature = await showFewchursSubmitSheet(context); // null if dismissed
```

It's a bottom sheet on phones and a centered dialog on screens 600 px and wider.

### `FewchursBoard` parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `options` | `BoardOptions?` | from `configure` | Per-widget override of the board options. |
| `initialFeatureId` | `String?` | — | Opens this request once the board is shown. For deep links and notifications. |
| `title` | `String?` | strings.boardTitle | App bar title. |
| `showAppBar` | `bool` | `true` | Set to `false` when embedding under your own app bar. |
| `showCloseButton` | `bool?` | `null` | `true` shows an ✕ button and closes on Esc. `false` hides the leading button. `null` uses Flutter's default. |
| `headerBuilder` | `WidgetBuilder?` | — | Widget shown above the list. |
| `emptyBuilder` | `WidgetBuilder?` | — | Replaces the empty state. |
| `featureCardBuilder` | `FeatureCardBuilder?` | — | Replaces each card. |
| `voteButtonBuilder` | `VoteButtonBuilder?` | — | Replaces the vote button. |
| `statusChipBuilder` | `StatusChipBuilder?` | — | Replaces the status chip. |

On wide screens (840 px and up by default: tablets, web and desktop), the board shows the list and the selected request side by side, with the tabs above the list.

<img src="https://raw.githubusercontent.com/fewchurs/fewchurs-flutter/main/packages/fewchurs/doc/screenshots/wide.png" width="640" alt="List and detail side by side">

---

## 5. Submitting from your own UI

```dart
try {
  final feature = await Fewchurs.submitFeature(
    title: 'Add dark mode',                  // 3–100 characters
    description: 'Would love a dark theme.', // optional, up to 1000
    email: 'sam@example.com',                // optional: follows the request
    isSubscriber: user.isPro,                // optional; defaults to configure(isSubscriber:)
  );
  print('Submitted ${feature.id}');
} on FewchursException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage)));
}
```

Input is checked before any request is sent, using the same rules as the server. Any open board shows the new request at the top of the **New** tab.

---

## 6. Configuration reference

```dart
Fewchurs.configure(
  apiKey: 'fr_live_xxx',                       // required
  style: FewchursStyle.adaptive,               // material (default) | cupertino | adaptive
  board: const BoardOptions(
    tabs: [BoardTab.top, BoardTab.newest],
    defaultTab: BoardTab.top,
    showDeclined: false,
    allowSubmissions: true,
    allowComments: true,
    allowFollow: true,
    emailField: EmailField.optional,          // hidden | optional | required
    submitButton: SubmitButtonPlacement.fab,  // fab | bottomBar | appBarAction
    pageSize: 20,
    maxContentWidth: 720,
    wideLayoutBreakpoint: 840,
  ),
  strings: const FewchursStrings(boardTitle: 'Ideas'),
  isSubscriber: () => billing.hasActiveSubscription,  // sync or async
  userEmail: () => auth.currentUser?.email,           // skips the email prompt when following
  deviceId: () async => hashedUserId,                 // see "User identity"
  deviceIdStore: MySecureStore(),                     // custom storage for the generated ID
  httpClient: myHttpClient,                           // package:http Client (logging, proxy, pinning)
  baseUrl: 'https://staging.fewchurs.shop/api/v1',    // override for staging
  logLevel: FewchursLogLevel.error,                   // none | error | debug (never logs the key)
);
```

| Option | Notes |
|---|---|
| `style` | `adaptive` uses Cupertino dialogs, spinners and page transitions on iOS and macOS, and Material everywhere else. |
| `tabs` | `BoardTab.top` and `BoardTab.newest`. `BoardTab.roadmap` is deprecated and ignored. |
| `showDeclined` | Declined requests are hidden unless this is `true`. |
| `userEmail` | If set, **Follow** uses this email right away. Otherwise the user is asked once, and can choose to have it remembered on the device. |

You can call `configure` again at any time, for example after sign-in or when switching styles.

---

## 7. Theming

### Level 1: automatic

The board reads `Theme.of(context)`, including the color scheme, text theme and light/dark mode. In a Material 3 app it already looks like the rest of the app.

### Level 2: app-wide tokens with a `ThemeExtension`

```dart
MaterialApp(
  theme: ThemeData(
    colorSchemeSeed: const Color(0xFFED5F18),
    extensions: const [
      FewchursThemeData(
        cardRadius: 14,
        voteButtonStyle: VoteButtonStyle.pill,  // column (default) | pill | minimal
        density: FewchursDensity.compact,       // comfortable (default) | compact
        statusColors: {FeatureStatus.done: Color(0xFF16A34A)},
      ),
    ],
  ),
);
```

Put a different `FewchursThemeData` in `darkTheme` to style dark mode separately. Theme changes animate.

<img src="https://raw.githubusercontent.com/fewchurs/fewchurs-flutter/main/packages/fewchurs/doc/screenshots/dark.png" width="240" alt="Dark mode">

### Level 3: scoped to one board

```dart
FewchursTheme(
  data: const FewchursThemeData(primary: Colors.teal, fontFamily: 'Inter'),
  child: const FewchursBoard(),
);
```

The scoped theme also applies to the detail page, submit sheet and dialogs opened from that board.

### All tokens

| Group | Tokens |
|---|---|
| Colors | `primary`, `onPrimary`, `background`, `surface`, `onSurface`, `muted`, `border`, `error`, `statusColors` |
| Shapes | `cardRadius`, `buttonRadius`, `chipRadius`, `sheetRadius`, `cardElevation` |
| Text | `titleStyle`, `bodyStyle`, `labelStyle`, `fontFamily` |
| Layout | `density`, `voteButtonStyle` |

Any token you leave `null` comes from your `ThemeData`. To read the final values in your own widgets, call `FewchursThemeData.of(context)`.

---

## 8. Text and translations

Override any text:

```dart
Fewchurs.configure(
  apiKey: '…',
  strings: const FewchursStrings(
    boardTitle: 'Ideas',
    submitButton: 'Suggest an idea',
    emptyTitle: 'No ideas yet',
    votesCount: '{count} votes',
  ),
);
```

Every label, button, status name, empty state and error message is a field on `FewchursStrings`. Fields you don't set keep their English default.

To load strings through Flutter's localization system, register the delegate:

```dart
MaterialApp(
  localizationsDelegates: const [FewchursLocalizations.delegate /*, ...your delegates */],
);
```

Text passed to `configure(strings:)` wins over the delegate.

---

## 9. Replacing parts of the UI (builders)

Builders receive state and actions, so paging, instant voting and error handling keep working.

```dart
FewchursBoard(
  headerBuilder: (context) => const Text('Vote for what we build next.'),
  emptyBuilder: (context) => const MyEmptyIllustration(),
  featureCardBuilder: (context, feature, actions) => ListTile(
    title: Text(feature.title),
    subtitle: Text(feature.description, maxLines: 1),
    onTap: actions.open,
    trailing: IconButton(
      icon: Icon(feature.hasVoted ? Icons.thumb_up : Icons.thumb_up_outlined),
      onPressed: actions.toggleVote,
    ),
  ),
  voteButtonBuilder: (context, state) => MyVoteChip(
    voted: state.voted, count: state.count, onTap: state.onPressed,
  ),
  statusChipBuilder: (context, status) => Text(status.name),
);
```

The built-in pieces are public too, so you can reuse them: `FewchursFeatureCard`, `FewchursVoteButton`, `FewchursStatusChip`, `FewchursPoweredBy`, `FewchursFeatureDetail`, `FewchursSubmitForm`.

---

## 10. Headless: build your own UI

### Controllers

Controllers are plain `ChangeNotifier`s. They work with `setState`, Provider, Riverpod, Bloc or anything else.

```dart
class MyIdeasPage extends StatefulWidget { … }

class _MyIdeasPageState extends State<MyIdeasPage> {
  late final board = Fewchurs.boardController(sort: FeatureSort.top);

  @override
  void dispose() {
    board.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: board,
      builder: (context, _) => switch (board.state) {
        BoardLoading() => const Center(child: CircularProgressIndicator()),
        BoardError(:final error) => Text(error.userMessage),
        BoardContent(:final features, :final canLoadMore) => ListView(
            children: [
              for (final f in features)
                ListTile(
                  title: Text(f.title),
                  trailing: Text('${f.upvoteCount}'),
                  onTap: () => board.toggleVote(f.id),
                ),
              if (canLoadMore)
                TextButton(onPressed: board.loadMore, child: const Text('Load more')),
            ],
          ),
      },
    );
  }
}
```

| `BoardController` | |
|---|---|
| `state` | `BoardLoading`, `BoardError(error)` or `BoardContent(features, canLoadMore, isLoadingMore, isRefreshing, loadMoreError)` |
| `refresh()` / `loadMore()` | Reload the list, or load the next page. |
| `toggleVote(id)` | Updates the list right away and syncs with the server. Rapid taps are merged, and a failed vote is undone. |
| `insertAtTop(f)` / `replace(f)` / `remove(id)` | Change the list yourself. |
| `actionErrors` | Stream of errors from votes and refreshes, e.g. to show a snack bar. |

Filtered list, for example a "coming soon" widget:

```dart
Fewchurs.boardController(statuses: {FeatureStatus.planned, FeatureStatus.inProgress});
```

`Fewchurs.detailController(feature)` returns a `FeatureDetailController` with `comments`, `loadComments()`, `loadMoreComments()`, `toggleVote()`, `setFollowing(bool, email:)` and `addComment(text, authorName:)`.

### Raw API client

```dart
final page = await Fewchurs.client.listFeatures(sort: FeatureSort.newest, limit: 20);
final feature = await Fewchurs.client.getFeature(featureId);
await Fewchurs.client.vote(featureId);
await Fewchurs.client.unvote(featureId);
await Fewchurs.client.follow(featureId, email: 'a@b.com');
await Fewchurs.client.unfollow(featureId);
final comments = await Fewchurs.client.listComments(featureId);
await Fewchurs.client.addComment(featureId, text: '+1', authorName: 'Sam');
final config = await Fewchurs.client.getConfig();
```

### Models

```dart
enum FeatureStatus { open, planned, inProgress, done, declined, unknown }

class Feature {
  String id, title, description;
  FeatureStatus status;
  int upvoteCount, commentCount, followerCount;
  bool hasVoted, isFollowing, isMine;
  DateTime createdAt, updatedAt; // UTC
}

class Comment {
  String id, text, authorName;
  bool isDeveloper, isMine;
  DateTime createdAt;
}
```

A status the SDK doesn't recognize becomes `FeatureStatus.unknown` and never throws.

---

## 11. User identity

Votes, follows, "mine" and rate limits are tied to a **device ID** sent with every request.

- **Default:** the package generates a random UUID the first time and saves it with `shared_preferences`. It stays until the app is uninstalled, or until site data is cleared on web. It never uses hardware or advertising IDs.
- **Signed-in users:** give a stable ID so a user's votes follow them across devices and platforms. Use a **hash** of your user ID, never an email address:

  ```dart
  Fewchurs.configure(
    apiKey: '…',
    deviceId: () async => auth.currentUser == null ? null : sha256Hex(auth.currentUser!.uid),
  );
  ```

  If the function returns `null`, the generated ID is used.
- **Custom storage:** implement `DeviceIdStore`, for example on top of `flutter_secure_storage`:

  ```dart
  class SecureStore implements DeviceIdStore {
    @override Future<String?> read() => storage.read(key: 'fewchurs_id');
    @override Future<void> write(String id) => storage.write(key: 'fewchurs_id', value: id);
  }
  ```

---

## 12. Events and analytics

The package sends **no** analytics. It emits events you can forward to your own tools:

```dart
Fewchurs.events.listen((event) {
  switch (event) {
    case BoardOpened():
      analytics.log('fewchurs_open');
    case FeatureSubmitted(:final featureId):
      analytics.log('fewchurs_submit', {'id': featureId});
    case Voted() || Commented() || Followed():
      analytics.log('fewchurs_${event.name}');
    case FewchursErrorEvent(:final error):
      crashlytics.recordError(error, null);
  }
});
```

---

## 13. Error handling

Every failure is a subclass of `sealed class FewchursException`, so a `switch` can cover all cases. Each one has `userMessage` (safe to show to users), `message` (detail for you), `code` and `statusCode`.

| Exception | When | `userMessage` |
|---|---|---|
| `FewchursInvalidApiKeyException` | Wrong key, or its app was deleted (401, `invalid_key` or `unauthorized`) | "Invalid API key. Check the key in your Fewchurs dashboard." Change it with `FewchursStrings(errorInvalidApiKey:)`. A warning with details is also logged for you. |
| `FewchursValidationException` | Invalid input (400) | The validation message |
| `FewchursRateLimitedException` | 15 submissions or 10 comments per device per day (429) | "You've reached today's limit. Try again tomorrow." |
| `FewchursLimitReachedException` | Rare (402). Plans never block submitting, voting or commenting. | "This board isn't accepting requests right now." |
| `FewchursNotFoundException` | Request was deleted (404) | "This request no longer exists." |
| `FewchursServerException` | Server error (5xx) | "Something went wrong. Try again." |
| `FewchursNetworkException` | Offline or timed out | "You're offline." |
| `FewchursUnknownException` | Forbidden (403) or an unexpected response | "Something went wrong. Try again." |

Reads and votes are retried twice on network or server errors. New content (submissions and comments) is never retried automatically, so it can't be posted twice. Requests time out after 15 seconds.

The built-in UI never crashes your app. If `configure` hasn't been called, the board shows a notice in debug builds and an empty view in release builds.

---

## 14. Privacy and security

- **The API key can be published by design.** It ships inside every app binary and web page. Protection happens on the server with per-device limits.
- Requests use HTTPS only. The key is never logged.
- The key's owner controls the "Powered by Fewchurs" footer. It disappears automatically on the Starter and Pro plans.

Answers for the **Google Play Data safety** form and **Apple privacy labels**:

| Data | Collected | Purpose |
|---|---|---|
| Email address | Optional, typed by the user | Notify them when a request ships |
| User content | Yes: titles, descriptions, comments | App functionality |
| App-scoped identifier | Yes: a random UUID | Votes, follows, rate limits |
| Analytics, ads, location, tracking | **No** | — |

---

## 15. Troubleshooting

| Problem | Fix |
|---|---|
| Works in debug, fails in a release APK | Add the Android `INTERNET` permission. |
| Nothing loads on macOS | Add the `network.client` entitlement to both entitlements files. |
| Nothing loads on web, CORS error in the console | Check that you didn't pass a custom `baseUrl`. The default server allows web apps. |
| "Invalid API key" on the board | Copy the key again from the dashboard and pass it to `Fewchurs.configure(apiKey:)`. If the app was deleted, create a new one. |
| "Something went wrong" everywhere | Set `logLevel: FewchursLogLevel.debug` to see requests. |
| Board shows "configure must be called" | Call `Fewchurs.configure(...)` before `runApp`. |
| Votes reset after reinstalling | Expected with the generated ID. Pass `deviceId:` to keep votes tied to signed-in users. |
| `No MaterialLocalizations found` in a `CupertinoApp` | The board handles this itself. If you use Fewchurs widgets outside the board, wrap them in a `MaterialApp` or add `DefaultMaterialLocalizations.delegate`. |

---

## 16. Development

```
fewchurs-flutter/
├─ packages/
│  ├─ fewchurs/             Flutter package: widgets, theming, controllers, Fewchurs facade
│  │  └─ example/           Small demos of each feature
│  └─ fewchurs_core/        Pure Dart: API client, models, errors, identity
└─ sample_app/              "Taskly", a to-do app that adds Fewchurs in each supported way
```

Run the tests:

```bash
cd packages/fewchurs_core && dart pub get && dart test
cd packages/fewchurs && flutter pub get && flutter test
```

Run the sample app:

```bash
cd sample_app
flutter create . --project-name taskly --platforms=android,ios,web,macos
flutter run --dart-define=FEWCHURS_API_KEY=fr_live_xxx
```

Install straight from GitHub to try unreleased changes. Use the same `ref` (a tag, branch or commit) in both entries:

```yaml
dependencies:
  fewchurs:
    git:
      url: https://github.com/fewchurs/fewchurs-flutter.git
      path: packages/fewchurs
      ref: main

dependency_overrides:
  fewchurs_core:
    git:
      url: https://github.com/fewchurs/fewchurs-flutter.git
      path: packages/fewchurs_core
      ref: main
```

Regenerate the screenshots after UI changes:

```bash
cd packages/fewchurs && flutter test tool/screenshots_test.dart --update-goldens
```

Local development uses `pubspec_overrides.yaml` files, so `fewchurs` depends on the local `fewchurs_core`. To publish, release `fewchurs_core` first and then `fewchurs`: run `dart pub publish` in `packages/fewchurs_core`, then `flutter pub publish` in `packages/fewchurs`.

CI (`.github/workflows/ci.yml`) runs analysis and tests on the **minimum supported Flutter (3.10.6)** and on the **latest stable**. It also checks that `FewchursClient.defaultBaseUrl` resolves and answers, so a dead domain can't ship.

## License

MIT. See [LICENSE](https://github.com/fewchurs/fewchurs-flutter/blob/main/LICENSE).

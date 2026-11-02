# fewchurs_core

The pure Dart client behind [`fewchurs`](https://pub.dev/packages/fewchurs). It contains the API client, models, typed errors and device identity.

Most apps should depend on `fewchurs`, which re-exports this package. Use `fewchurs_core` directly only if you need the client without Flutter.

```dart
final client = FewchursClient(apiKey: 'fr_live_xxx');
final page = await client.listFeatures(sort: FeatureSort.top);
await client.vote(page.features.first.id);
```

Add your Bundle ID / package name / domain to your app in the Fewchurs dashboard. The API key only works there. Outside a browser, pass the same ID as `appId`. It is sent as `X-Fewchurs-App-Id`:

```dart
final client = FewchursClient(apiKey: 'fr_live_xxx', appId: () => 'com.company.app');
```

A key used from an ID that isn't saved throws `FewchursInvalidApiKeyException`, and its `message` names the ID to add (`wrong_app`).

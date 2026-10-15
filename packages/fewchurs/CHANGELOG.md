## 1.4.1

- First release on pub.dev. Install with `flutter pub add fewchurs`.
- Requires `fewchurs_core` 1.2.1.

## 1.4.0

- Cleaner, borderless look. Cards, vote buttons, text fields and the Follow button no longer have outlines, and the dividers under the tabs, above comments, above the comment box and between the list and detail on wide screens are gone. Cards and controls use a light fill instead, in light and dark mode. Text fields still show an outline while focused or invalid.
- When `surface` matches the background (the Material 3 default), cards get a light tint so they stay distinct.
- The `border` theme token now only colors the submit sheet's drag handle.

## 1.3.0

- A wrong API key (or a deleted app) now shows "Invalid API key. Check the key in your Fewchurs dashboard." instead of the generic error. Change it with `FewchursStrings(errorInvalidApiKey:)`.

## 1.2.0

- The board shows only the Top and New tabs. `BoardTab.roadmap` is deprecated and ignored, so existing code still compiles. `FewchursStrings.tabRoadmap` and `roadmapEmptyMessage` are deprecated and unused.
- The headless `statuses` filter on `Fewchurs.boardController` and `FewchursClient.listFeatures` is unchanged.

## 1.1.0

- Works out of the box: the default server is now `https://www.fewchurs.shop/api/v1`.
- Added `FewchursBoard(initialFeatureId:)` to open a request from a deep link or notification.
- If `/config` can't be loaded, the "Powered by Fewchurs" line is shown, like the Kotlin and iOS SDKs. It stays hidden while loading, so paid plans never flash it.
- Docs: the badge is hidden on Starter and Pro; `FewchursLimitReachedException` is rare; install from GitHub with a pinned `ref`.
- Requires `fewchurs_core` 1.1.0.

## 1.0.0

- Initial release.

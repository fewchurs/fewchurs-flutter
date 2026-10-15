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

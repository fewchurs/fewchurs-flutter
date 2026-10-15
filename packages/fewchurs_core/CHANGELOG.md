## 1.2.1

- Documented the public API and added an example, ready for pub.dev.

## 1.2.0

- `FewchursInvalidApiKeyException.userMessage` is now "Invalid API key. Check the key in your Fewchurs dashboard." instead of the generic error.

## 1.1.0

- The default server is now `https://www.fewchurs.shop/api/v1`. The old `fewchurs.com` address never resolved, so every call failed unless the app passed `baseUrl`.
- Added `FewchursClient.getFeature(id)` to open one request.
- A 401 with the `unauthorized` code now throws `FewchursInvalidApiKeyException`. A 403 (`forbidden`) is handled as a generic error.
- `RemoteConfig()` now defaults to `showBranding: true`, matching `RemoteConfig.fromJson` and the Kotlin and iOS SDKs.

## 1.0.0

- Initial release.

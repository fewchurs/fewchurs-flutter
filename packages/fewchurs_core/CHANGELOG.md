## 1.4.0

- `wrong_app`: `FewchursInvalidApiKeyException.userMessage` is now the server's message, which names the ID to add. New `isWrongApp` tells this case apart. Other invalid key errors keep their message.
- Logs a warning once when the app ID can't be read, instead of leaving it out silently. This usually means the app needs a full restart after adding the SDK.

## 1.3.0

- Sends the app ID so your API key only works in your own apps. Handles `wrong_app`.
- New `FewchursClient(appId:)`: returns your Bundle ID, package name or domain, sent as `X-Fewchurs-App-Id` on every request. Leave it unset in browsers, which send `Origin`.
- `wrong_app` (403) throws `FewchursInvalidApiKeyException` (not retried), and `message` names the ID to add in the dashboard.
- Handles `wrong_platform`: the API key belongs to an app made for another platform. It throws `FewchursInvalidApiKeyException` (not retried), and `message` says which SDK the key is for.

## 1.2.2

- Moves to the new domain: the default server is now `https://www.fewchurs.com/api/v1`.

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

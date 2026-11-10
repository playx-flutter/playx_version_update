---
id: ios-and-macos
title: iOS and macOS
sidebar_position: 12
---

# iOS and macOS

Apple platforms have no in-app update API. The package reads the store, shows the update dialog (the
Cupertino style) or page, and opens the store app when the user taps update.

## iOS

The default source calls the App Store lookup API with the bundle id (read from the app, or set it with
[`appIds`](./app-ids-and-store-urls.md)), the country and the language. It returns the version, release
notes, the minimum version tag and the store URL.

```dart
await PlayxVersionUpdate.showUpdateDialog(
  context: context,
  options: PlayxUpdateOptions(country: 'us'),
);
```

The App Store lookup is rate limited (roughly 20 requests per minute per IP). A throttled request
returns `NETWORK_TOO_MANY_REQUESTS`.

## macOS

On macOS the lookup uses the **Mac App Store** (`entity=macSoftware`), found by the bundle id.

- **Sandbox**: sandboxed apps need the network entitlement to run the lookup. Add it to
  `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

  ```xml
  <key>com.apple.security.network.client</key>
  <true/>
  ```

- **Apps outside the Mac App Store**: many Mac apps ship as notarized downloads. The lookup does not
  find them. Use a [custom version source](./version-sources.md) (your backend, a Sparkle appcast...) and
  point `storeUrls` at your download page:

  ```dart
  PlayxUpdateOptions(
    versionSource: PlayxCallbackVersionSource(fetchLatestFromMyServer),
    storeUrls: PlayxPlatformValue(macos: 'https://example.com/download'),
  )
  ```

- The update button opens the Mac App Store app (`macappstores://`) and falls back to the web URL.

## Per-platform ids and versions

If your iOS and macOS apps have different ids or versions, set them per platform with
[`appIds`](./app-ids-and-store-urls.md) and a
[static version source](./version-sources.md#static).

## Windows and Linux

There is no store lookup. Use a [custom version source](./version-sources.md) and show the result with
`PlayxUpdatePage` or your own UI, see [Update dialog and page](./update-dialog-and-page.md).

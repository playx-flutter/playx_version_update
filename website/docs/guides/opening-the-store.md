---
id: opening-the-store
title: Opening the store
sidebar_position: 7
---

# Opening the store

## `openStore`

```dart
await PlayxVersionUpdate.openStore(storeUrl: info.storeUrl);
```

`openStore` opens the **store app** directly when it can, and falls back to the web URL:

| Platform | Store URL | Opened first |
| --- | --- | --- |
| Android | `https://play.google.com/store/apps/details?id=...` | `market://details?id=...` |
| iOS | `https://apps.apple.com/...` | `itms-apps://apps.apple.com/...` |
| macOS | `https://apps.apple.com/...` | `macappstores://apps.apple.com/...` |
| any | another URL (another store, a short link, a custom scheme) | the URL as it is |

Pass `preferStoreApp: false` to open only the web URL. The update dialog and page do the same, and
`PlayxUpdateUIOptions(preferStoreApp: false)` turns it off there.

It returns a `PlayxVersionUpdateResult<bool>`: `success(true)` once something opened, or an error when
nothing could handle the link.

:::info No `<queries>` needed
The package launches the link directly instead of calling `canLaunchUrl` first, so you do not need
`<queries>` entries on Android or `LSApplicationQueriesSchemes` on iOS.
:::

## Without a version check

Call `openStore` without a URL, for an "Update" or "Rate us" button. The URL is worked out from the
options:

```dart
await PlayxVersionUpdate.openStore(
  options: PlayxUpdateOptions(
    storeUrls: PlayxPlatformValue(ios: 'https://apps.apple.com/app/id123456789'),
  ),
);
```

The URL is `storeUrls` for the current platform, then on Android the Google Play URL built from the app id
(no network). On iOS and macOS without `storeUrls` it costs one store lookup (or one request to your
`versionSource`).

## Your own launcher

`storeLauncher` opens the store your own way and reports whether it worked:

```dart
PlayxUpdateUIOptions(
  storeLauncher: (info) async {
    return openMyStore(info.newVersion); // true if the store was opened
  },
  events: PlayxUpdateEvents(
    onStoreOpenResult: (info, opened) => analytics.log('store_opened', opened),
  ),
)
```

On the update button the order is:

1. `onUpdate`: replaces everything and returns nothing
2. `storeLauncher`
3. the default `openStore`

`onStoreOpenResult` fires after the default launcher or `storeLauncher`, with `false` when it failed or
threw. An error thrown by `storeLauncher` is also reported to `FlutterError.onError`.

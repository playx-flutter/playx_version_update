---
id: migrating-to-2
title: Migrating to 2.0
sidebar_position: 1
---

# Migrating from 1.x to 2.0

2.0 raises the minimum SDK, replaces the `playx_network` dependency, fixes several behaviors and
adds a lot (version sources, Later/Skip, events, macOS and more). Most apps need a few small changes.
This page lists them all.

## Checklist

1. Update the SDK and the dependencies you pin.
2. Handle network errors with the new types if you used `playx_network` directly.
3. Handle the new result of `openStore`.
4. Review how you handle in-app update results on Android.
5. Move off the deprecated options (optional now, but they will be removed).

## 1. Requirements

| | 1.x | 2.0 |
| --- | --- | --- |
| Dart | 3.6 | **3.10** |
| Flutter | 3.27 | **3.38.1** |
| `package_info_plus` | 8.3 – 9.x | **^10.2.2** |
| `dio` | via `playx_network` | **^5.11.1** (direct) |
| `playx_network` | yes | **removed** |

```yaml
dependencies:
  playx_version_update: ^2.0.0
```

If your app also depends on `package_info_plus` 8 or 9, upgrade it to 10 (a version solving error
otherwise).

## 2. Network errors (`playx_network` removed)

The package no longer depends on `playx_network`. The exception **names are the same** and are still
exported from `playx_version_update`, but they are now this package's own types. If your code imports
`playx_network` as well, you now have two different `NetworkException` types: use the one from this
package for errors returned by `playx_version_update`.

```dart
// 1.x
if (error is PlayxVersionNetworkError) {
  final network = error.error; // a playx_network NetworkException
  print(network.errorMessage);
}

// 2.0: same shape, plus stable codes
if (error is PlayxVersionNetworkError) {
  print(error.errorCode);          // e.g. NETWORK_NO_INTERNET_CONNECTION
  print(error.statusCode);         // HTTP status, or null
  print(error.error.isRetryable);  // can retrying help?
  print(error.error.cause);        // the original error
}
```

What changed:

- `PlayxVersionNetworkError.errorCode` is now the stable `NetworkErrorCode` (it used to be the status code
  or the message).
- Exceptions have `errorCode`, `message`, `cause` and `isRetryable`. `apiErrorMessage` and
  `shouldShowApiError` are gone. Constructors no longer take messages (the defaults are fixed).
- New types: `AppNotFoundException`, `ConsentRequiredException`, `BadRequestException`,
  `TooManyRequestsException`, `BadCertificateException`.
- Status codes 502 and 504 map to `ServiceUnavailableException`.

See the [error code table](../guides/network-and-errors.md#network-error-codes).

## 3. `openStore`

```dart
// 1.x
final result = await PlayxVersionUpdate.openStore(storeUrl: info.storeUrl);

// 2.0: the same call still works
final result = await PlayxVersionUpdate.openStore(storeUrl: info.storeUrl);
```

- It opens the store **app** first (`market://`, `itms-apps://`, `macappstores://`), then the web URL. Pass
  `preferStoreApp: false` for the old behavior.
- It no longer calls `canLaunchUrl`, so you do not need `<queries>` or `LSApplicationQueriesSchemes`.
- It now returns an **error** whenever nothing could be opened. Before, `launchUrl` returning `false`
  gave `success(false)`.
- `storeUrl` is optional: without it the URL is resolved from `options`, see
  [Opening the store](../guides/opening-the-store.md).

## 4. Android in-app update results

The native results are now correct and match the documentation:

| Situation | 1.x | 2.0 |
| --- | --- | --- |
| the user denies the update | `success(false)` | `error(PlayxInAppUpdateCanceledError)` |
| the flow fails | `success(true)` | `error(PlayxInAppUpdateFailedError)` |
| an immediate update is not allowed | the call never completed | `error(PlayxUpdateNotAllowedError)` |
| no update, `getUpdateStalenessDays` / `getUpdatePriority` | an error | `success(-1)` |

```dart
// 2.0
final result = await PlayxVersionUpdate.startFlexibleUpdate();
result.when(
  success: (started) => listenToDownload(),
  error: (error) {
    if (error is PlayxInAppUpdateCanceledError) {
      // The user declined. This used to arrive as success(false).
    }
  },
);
```

Three error classes were added (`PlayxUpdateNotAvailableError`, `PlayxUpdateInProgressError`,
`PlayxUpdateNotAllowedError`). `PlayxVersionUpdateError` is a sealed class, so an exhaustive `switch`
over it needs the new cases.

## 5. Dialog and page behavior

These were bugs; check that you do not depend on the old behavior:

- A **forced dialog** is no longer closed by its dismiss button, and a custom `onCancel` no longer also
  exits the app. Without an `onCancel`, the button exits the app.
- The **page's dismiss button** now closes a dismissible page (it did nothing).
- The **page** blocks the back button when forced, and reports a system dismissal otherwise.
- The **iOS dialog** no longer pops the route twice.
- `onShown` is only reported when something is really on screen.
- `showUpdateDialog` can return `success(false)` when a reminder suppressed the prompt (only if you pass
  `reminderOptions`).
- A forced update is no longer flagged when the app is already current (an explicit `forceUpdate: true`
  still applies).
- `PlayxUpdateOptions.localVersion` is now honored (it was ignored).
- Versions with a `v` prefix (`v2.0.0`) or spaces are parsed instead of becoming `0.0.0`.

## 6. Deprecated options

They still work, and will be removed in a future major release.

### `newPlatformVersion` / `minPlatformVersion`

```dart
// 1.x
PlayxUpdateOptions(
  newPlatformVersion: PlayxPlatformVersion(android: '2.1.0', ios: '2.0.5'),
  minPlatformVersion: PlayxPlatformVersion(android: '1.5.0', ios: '2.0.0'),
)

// 2.0
PlayxUpdateOptions(
  versionSource: PlayxStaticVersionSource(
    version: PlayxPlatformVersion(android: '2.1.0', ios: '2.0.5'),
    minVersion: PlayxPlatformVersion(android: '1.5.0', ios: '2.0.0'),
  ),
)
```

`PlayxPlatformVersion` itself is not deprecated: it now also has `macos`, `windows` and `linux`.

### `androidPackageName` / `iosBundleId`

```dart
// 1.x
PlayxUpdateOptions(
  androidPackageName: 'com.example.app',
  iosBundleId: 'com.example.app',
)

// 2.0
PlayxUpdateOptions(
  appIds: PlayxPlatformValue(
    android: 'com.example.app',
    ios: 'com.example.app',
  ),
)
```

## What's new

- [Version sources](../guides/version-sources.md): Remote Config, your backend, fixed values, fallback chains.
- [Later and Skip](../guides/later-and-skip.md) with pluggable storage.
- [Events](../guides/events.md) for analytics.
- [Opening the store](../guides/opening-the-store.md) with deep links, your own launcher, and without a
  version check.
- [App ids and store URLs](../guides/app-ids-and-store-urls.md) per platform.
- [Network options](../guides/network-and-errors.md): retries, timeouts, headers, your own `Dio`, logging.
- [macOS](../guides/ios-and-macos.md) support.
- A consent-page error for Google Play in the EU.

The full list is in the [changelog](../changelog.md).

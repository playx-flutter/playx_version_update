---
id: version-sources
title: Version sources
sidebar_position: 5
---

# Version sources

A **version source** decides where the latest version comes from. By default the package reads the
store (Google Play, the App Store or the Mac App Store). Plug in another source to use your own backend
or Firebase Remote Config, to set fixed values per platform, or to chain several sources.

```dart
PlayxUpdateOptions(
  versionSource: PlayxCallbackVersionSource((request) async {
    // Return the latest version from anywhere.
  }),
)
```

Values you set directly in `PlayxUpdateOptions` (`newVersion`, `minVersion`, `forceUpdate`) always win
over what a source returns.

## What a source returns

A source returns a `PlayxRemoteVersionInfo`:

| Field | Meaning |
| --- | --- |
| `version` | the latest version (required) |
| `minVersion` | the minimum version, see [Minimum version](./minimum-version.md) |
| `releaseNotes` | what's new |
| `storeUrl` | where users update. Optional on Android (the Google Play URL is used), needed on iOS and macOS when the store is not queried |

It receives a `PlayxVersionRequest` with the `platform`, `packageId`, `country`, `language`,
`networkOptions` and `enableLog` of the check.

## Built-in sources

### Store (default)

`PlayxStoreVersionSource` reads Google Play (Android), the App Store (iOS) and the Mac App Store
(macOS). When you set `newVersion`, the Android source does not request Google Play at all.

### Callback {#callback}

`PlayxCallbackVersionSource` takes a function: the shortest way to use Firebase Remote Config or your own
API.

```dart
PlayxUpdateOptions(
  versionSource: PlayxCallbackVersionSource((request) async {
    final config = FirebaseRemoteConfig.instance;
    await config.fetchAndActivate();
    return PlayxRemoteVersionInfo(
      version: config.getString('latest_version'),
      minVersion: config.getString('min_version'),
      storeUrl: config.getString('store_url'),
    );
  }),
)
```

A thrown `NetworkException` becomes a `PlayxVersionNetworkError`, any other error a
`DefaultFailureError`.

### Static {#static}

`PlayxStaticVersionSource` holds fixed values per platform. Each platform can have its own version,
minimum version, release notes and store URL:

```dart
PlayxUpdateOptions(
  versionSource: PlayxStaticVersionSource(
    version: PlayxPlatformVersion(android: '2.1.0', ios: '2.0.5'),
    minVersion: PlayxPlatformVersion(android: '1.5.0', ios: '2.0.0'),
    releaseNotes: PlayxPlatformValue(android: 'Bug fixes'),
    storeUrls: PlayxPlatformValue(ios: 'https://apps.apple.com/app/id123456789'),
  ),
)
```

If `version` has no value for the current platform, the check fails with a `DefaultFailureError`.

### Fallback

`PlayxFallbackVersionSource` tries sources in order and uses the first one that succeeds. If all fail, it
returns the last error:

```dart
PlayxUpdateOptions(
  versionSource: PlayxFallbackVersionSource([
    PlayxCallbackVersionSource(fetchFromMyBackend), // your backend first
    PlayxStoreVersionSource(),                     // the store if it fails
  ]),
)
```

## Write your own source

Implement `PlayxVersionSource`:

```dart
class MyBackendVersionSource implements PlayxVersionSource {
  MyBackendVersionSource(this._api);
  final MyApi _api;

  @override
  Future<PlayxVersionUpdateResult<PlayxRemoteVersionInfo>> fetch(
      PlayxVersionRequest request) async {
    try {
      final dto = await _api.latestVersion(platform: request.platform.name);
      return PlayxVersionUpdateResult.success(PlayxRemoteVersionInfo(
        version: dto.version,
        minVersion: dto.minVersion,
        storeUrl: dto.storeUrl,
      ));
    } catch (e) {
      return PlayxVersionUpdateResult.error(DefaultFailureError(errorMsg: '$e'));
    }
  }
}
```

A source reports a failure by **returning** an error. Catch errors inside `fetch` (or wrap the logic in a
`PlayxCallbackVersionSource`, which does it for you).

You can also extend the built-in classes, for example override `fetch` of `PlayxStoreVersionSource` and
change its result.

## Precedence

For the version, minimum version and store URL, the order is:

1. the value in `PlayxUpdateOptions` (`newVersion`, `minVersion`, `forceUpdate`, `storeUrls`)
2. the value the source returns
3. for the store URL on Android, the URL built from the package name

If you pass `newVersion` and the source fails, the failure is ignored and your version is used.

## Other platforms

The default source supports Android, iOS and macOS. On Windows and Linux, `checkVersion` works with a
custom `versionSource`, and you show the result with your own UI or `PlayxUpdatePage`.

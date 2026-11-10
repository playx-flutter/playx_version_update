---
id: app-ids-and-store-urls
title: App ids and store URLs
sidebar_position: 6
---

# App ids and store URLs

## Per-platform values

`PlayxPlatformValue<T>` holds a value for each platform: `android`, `ios`, `macos`, `windows` and
`linux`. You set the platforms you care about and the package picks the one for the current platform.

`PlayxPlatformVersion` is the same container for version strings. The platform enum is `PlayxPlatform`
(`PlayxPlatform.current` is the platform the app runs on, or `null` on the web).

## App ids

The package id (Google Play) and bundle id (App Store) are read from the app. Override them per platform
with `appIds`:

```dart
PlayxUpdateOptions(
  appIds: PlayxPlatformValue(
    android: 'com.example.app',
    ios: 'com.example.app.ios',
    macos: 'com.example.app.mac',
  ),
)
```

This is useful when the id on the store differs from the id of the build, or to look up another app (for
example in a demo).

## Store URLs

Send users somewhere other than the default store page: another store, a marketing link or a `market://`
link:

```dart
PlayxUpdateOptions(
  storeUrls: PlayxPlatformValue(
    android: 'market://details?id=com.example.app',
    ios: 'https://apps.apple.com/app/id123456789',
    macos: 'https://example.com/download',
  ),
)
```

Any scheme works and the URL is used as it is. The precedence is `storeUrls`, then the URL a
[version source](./version-sources.md) returns, then the URL derived from the store.

:::tip
On iOS, passing `storeUrls` together with `newVersion` skips the App Store lookup entirely, because the
lookup was only needed for the store URL.
:::

## Platforms without a store lookup

On Windows and Linux there is no default store lookup. Use a `versionSource` and set `storeUrls`.

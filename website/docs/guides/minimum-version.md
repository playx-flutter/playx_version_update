---
id: minimum-version
title: Minimum version
sidebar_position: 4
---

# Minimum version

An update is **forced** when the installed version is at or below the minimum version. A forced update
shows a full-screen page the user cannot dismiss (by default), and it is the way to retire old versions.

## Where the minimum comes from

In order of priority:

1. `forceUpdate` in `PlayxUpdateOptions`: `true` or `false` overrides everything.
2. `minVersion` in `PlayxUpdateOptions`.
3. The minimum returned by the [version source](./version-sources.md).
4. A `[Minimum Version: X.Y.Z]` tag in the store description (the default store source reads it).

```dart
await PlayxVersionUpdate.showUpdateDialog(
  context: context,
  options: PlayxUpdateOptions(minVersion: '1.5.0'),
);
```

## The store description tag

Add a tag in square brackets to your app's Google Play or App Store description:

```text
[Minimum Version: 1.5.0]
```

These forms work (the tag is case-insensitive):

- `[Minimum Version :1.5.0]`
- `[Minimum Version: 1.5.0]`
- `[Minimum Version = 1.5.0]`
- `[minimum_version:1.5.0]`

The version can use any style the package version parser accepts, for example `519.0.0.44.92` or
`1.2.3-alpha.1+build.456`.

## Different minimums per platform

Each platform can have its own minimum with a [static version source](./version-sources.md#static):

```dart
PlayxUpdateOptions(
  versionSource: PlayxStaticVersionSource(
    version: PlayxPlatformVersion(android: '2.1.0', ios: '2.0.5'),
    minVersion: PlayxPlatformVersion(android: '1.5.0', ios: '2.0.0'),
  ),
)
```

## Details

- The comparison is "installed version ≤ minimum", so being exactly on the minimum is forced.
- A forced update is only automatic when there is a newer version to install. A minimum above the
  store version (a misconfiguration) does not lock an app that is already current. An explicit
  `forceUpdate: true` is always respected.
- An empty `minVersion` (for example an empty Remote Config string) is ignored.

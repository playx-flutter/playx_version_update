---
id: troubleshooting
title: Troubleshooting
sidebar_position: 20
---

# Troubleshooting

Turn on `enableNetworkLogging: true` in `PlayxUpdateOptions` first: it prints the request, the response and
what the error was mapped to.

## The dialog does not show

- `showUpdateDialog` returns a result. Print it:
  - `error(PlayxVersionCantUpdateError)`: the store version is not higher than the installed one.
  - `success(false)`: the user chose "Later" or "Skip this version" before. Call
    `PlayxUpdateReminder(options).reset()` while testing. See [Later and Skip](./guides/later-and-skip.md).
  - `error(NotSupportedException)`: Windows, Linux and the web have no dialog or no store lookup.
- Compare versions: the installed one is `PlayxVersionUpdate.getAppVersion()`. Set `localVersion` in the
  options to test.

## `STORE_APP_NOT_FOUND`

The store has no app for the id. Check:

- the package name or bundle id (set it with [`appIds`](./guides/app-ids-and-store-urls.md));
- that the app is published in the `country` you pass (default `us`);
- on macOS, that the app is in the **Mac App Store**. Apps distributed outside it need a
  [custom version source](./guides/version-sources.md).

## `STORE_CONSENT_REQUIRED`

Google Play asked the user for cookie consent (the EU and UK), so the page cannot be read. Retrying does
not help. Provide the version with a [version source](./guides/version-sources.md) from your own backend, or
send users to the store with [`openStore`](./guides/opening-the-store.md). See
[Google consent page](./guides/network-and-errors.md#consent).

## `NETWORK_TOO_MANY_REQUESTS`

The App Store lookup API is rate limited (roughly 20 requests per minute per IP). Check less often, or use
a [version source](./guides/version-sources.md) of your own. The request is retried once by default.

## `VERSION_FORMAT_ERROR`

A version could not be read or compared: the store page changed, returned an empty version, or your
[version source](./guides/version-sources.md) returned something that is not a version. Print the info with
`enableNetworkLogging` and check the value.

## Nothing happens when I tap Update

- The store URL may be empty. On iOS and macOS a custom [version source](./guides/version-sources.md) must
  return `storeUrl` (or set [`storeUrls`](./guides/app-ids-and-store-urls.md)).
- Listen to `onStoreOpenResult` in the [events](./guides/events.md): `false` means the link could not be
  opened.

## macOS: the lookup fails

A sandboxed app needs the network entitlement. Add `com.apple.security.network.client` to
`DebugProfile.entitlements` and `Release.entitlements`, see [iOS and macOS](./guides/ios-and-macos.md).

## Android in-app updates do not appear

The app must be **installed from Google Play**. A build from Android Studio never gets in-app updates. See
[Testing](./guides/testing.md#android-in-app-updates).

## Release notes are missing

The store did not return any, or `showReleaseNotes` is `false` (the default). Enable it in
[`PlayxUpdateUIOptions`](./guides/customizing-the-ui.md).

## The package does not build with Android Gradle Plugin 9

The plugin supports AGP 8 and 9 (built-in Kotlin). If your build fails, check that your app's Flutter
Gradle plugin version supports AGP 9, see
[Flutter's built-in Kotlin guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers).

## Still stuck?

Search the [issues](https://github.com/playx-flutter/playx_version_update/issues) or open a new one with the
`enableNetworkLogging` output and your `PlayxUpdateOptions`.

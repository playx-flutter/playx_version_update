---
id: check-for-updates
title: Check for updates
sidebar_position: 1
---

# Check for updates

`PlayxVersionUpdate.checkVersion` finds the latest version, compares it with the installed one and
returns a `PlayxVersionUpdateResult<PlayxVersionUpdateInfo>`.

```dart
final result = await PlayxVersionUpdate.checkVersion(
  options: PlayxUpdateOptions(country: 'us', language: 'en'),
);

result.when(
  success: (info) {
    if (info.canUpdate) {
      // A newer version exists.
    }
  },
  error: (error) {
    // error.errorCode and error.message explain what went wrong.
  },
);
```

## The result

Nothing is thrown: every outcome is a `PlayxVersionUpdateResult`, which is either a success with data
or an error.

| Member | Meaning |
| --- | --- |
| `when(success:, error:)` | run a callback for the outcome |
| `map`, `mapAsync` | transform the data, or pass the error on |
| `isSuccess`, `isError` | the state |
| `updateData`, `updateError` | the data, or `null`; the error, or `null` |

## `PlayxVersionUpdateInfo`

| Field | Meaning |
| --- | --- |
| `localVersion` | the installed version |
| `newVersion` | the latest version |
| `canUpdate` | `true` when `newVersion` is higher than `localVersion` |
| `forceUpdate` | `true` when the update is mandatory, see [Minimum version](./minimum-version.md) |
| `minVersion` | the minimum version that may keep running, if known |
| `storeUrl` | where the user updates the app |
| `releaseNotes` | what's new, if the store provides it |
| `country` | the store country that was used |

## `PlayxUpdateOptions`

All options are optional.

| Option | Default | Meaning |
| --- | --- | --- |
| `country`, `language` | `us`, `en` | the store country and language used by the lookup |
| `newVersion` | — | use this as the latest version instead of asking the store |
| `minVersion` | — | the minimum version, see [Minimum version](./minimum-version.md) |
| `forceUpdate` | — | `true` or `false` overrides the automatic decision |
| `localVersion` | — | override the installed version (useful for tests) |
| `appIds` | — | the app id per platform, see [App ids and store URLs](./app-ids-and-store-urls.md) |
| `storeUrls` | — | a custom store URL per platform |
| `versionSource` | the store | where versions come from, see [Version sources](./version-sources.md) |
| `networkOptions` | — | retries, timeouts, headers, custom `Dio`, see [Network and errors](./network-and-errors.md) |
| `enableNetworkLogging` | `false` | log the request, response and errors to the console |

## Providing the version yourself

If you already know the latest version (from your backend, Remote Config or a test), pass it:

```dart
await PlayxVersionUpdate.checkVersion(
  options: PlayxUpdateOptions(newVersion: '2.0.0', minVersion: '1.5.0'),
);
```

On Android the Google Play page is then not requested at all, so a store failure cannot fail the
check. For anything more structured, use a [version source](./version-sources.md).

## Errors

A failed check returns a `PlayxVersionUpdateError`. Network failures are a `PlayxVersionNetworkError`
with a stable `errorCode`. See [Network and errors](./network-and-errors.md).

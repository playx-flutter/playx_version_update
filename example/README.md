# playx_version_update_example

Shows how to use the `playx_version_update` package on Android, iOS and macOS.

```sh
cd example
flutter run            # pick a device: Android, iOS simulator or macOS
```

## Main screen

The buttons cover the original features: reading the app version, checking the
version with a custom UI (`PlayxUpdatePage` / `PlayxUpdateDialog`), the
customizable update dialog, and Google Play in-app updates (immediate and
flexible, Android only).

## More features

The **More features** screen (`lib/features_page.dart`) demonstrates the newer
parts of the package. Its demos use a version source with fixed values, so they
work offline and always have an update to show:

| Demo | Shows |
| --- | --- |
| Events + Later + Skip | `PlayxUpdateEvents`, `reminderOptions` (snooze for a minute, "Skip this version") |
| Reset Later / Skip | `PlayxUpdateReminder.reset()` |
| Custom store launcher | `storeLauncher` and `onStoreOpenResult` |
| Open the store (no check) | `PlayxVersionUpdate.openStore` without a url, with `appIds` and `storeUrls` |
| Per-platform versions | `PlayxStaticVersionSource` with a different minimum version per platform |
| Backend, then the store | `PlayxFallbackVersionSource` and `PlayxCallbackVersionSource` |
| Store lookup with options | `PlayxNetworkOptions` (retries, timeouts, headers) and request logging |
| App not on the store | stable error codes (`STORE_APP_NOT_FOUND`, `isRetryable`) |

Events and results are printed in the event log at the bottom of the screen.

## Notes

- Android needs the Google Play package to be installed from the Play Store to
  try in-app updates (see the package README).
- macOS apps are sandboxed: `macos/Runner/*.entitlements` include
  `com.apple.security.network.client` so the store lookup can run.
- The store lookups use real published apps, so they work without the example
  being on any store (`lib/app_ids.dart`): Gemini on Google Play
  (`com.google.android.apps.bard`), Shortcuts on the App Store
  (`com.apple.shortcuts`) and Xcode on the Mac App Store
  (`com.apple.dt.Xcode`). For your own app the ids are read from the app, so
  you do not need `appIds` at all.

## Tests

```sh
flutter test                                   # widget tests (layout at phone and desktop sizes)
flutter test integration_test -d macos         # real store lookups, needs a network
```

The integration test (`integration_test/store_lookup_test.dart`) reads the
version of the real apps above and checks the "app not on the store" error. It
also runs on an Android or iOS device.

# Changelog

## 2.0.0

A big release: version sources, "Later" and "Skip", events, macOS, a rewritten network layer and many
fixes. **See the [migration guide](https://playx-flutter.github.io/playx_version_update/docs/migration/migrating-to-2)**
for the few changes you may need to make.

### Breaking changes

- The minimum SDK is now **Dart 3.10 and Flutter 3.38.1** (was Dart 3.6 and Flutter 3.27). `package_info_plus`
  is `^10.2.2` and `dio` is `^5.11.1`.
- **`playx_network` is removed.** The package now has its own small `dio` based client. The `NetworkException`
  types are still exported under the same names, but they are this package's own types: they have an
  `errorCode`, `message`, `cause` and `isRetryable`, and no `apiErrorMessage` / `shouldShowApiError`.
  `PlayxVersionNetworkError.errorCode` is now the stable `NetworkErrorCode` (it used to be the status code or the message).
- `PlayxVersionUpdate.openStore` now opens the store app first (`market://`, `itms-apps://`, `macappstores://`)
  and the web URL after it, no longer calls `canLaunchUrl` (no `<queries>` / `LSApplicationQueriesSchemes`
  needed), and returns an **error** whenever nothing could be opened (before, `launchUrl` returning `false`
  gave `success(false)`).
- Android in-app updates report the real result: a denied update is `PlayxInAppUpdateCanceledError` (it was
  `success(false)`) and a failed one is `PlayxInAppUpdateFailedError` (it was `success(true)`).
  `getUpdateStalenessDays` / `getUpdatePriority` return `-1` when there is no update instead of an error.
- `PlayxVersionUpdateError` has three new subclasses (`PlayxUpdateNotAvailableError`,
  `PlayxUpdateInProgressError`, `PlayxUpdateNotAllowedError`), so an exhaustive `switch` needs them.
- `PlayxVersionRequest` (new) exposes `platform: PlayxPlatform` instead of a boolean.

### Added

- **Version sources**: `PlayxUpdateOptions.versionSource` with `PlayxStoreVersionSource` (default),
  `PlayxCallbackVersionSource` (Remote Config or your backend), `PlayxStaticVersionSource` (fixed values per
  platform) and `PlayxFallbackVersionSource`. Implement `PlayxVersionSource` for your own.
- **macOS support**: the default source reads the Mac App Store, the update dialog renders in the Cupertino style
  and the update button opens the Mac App Store app. macOS is listed in the supported platforms.
- **Per-platform values**: `PlayxPlatform` (android, ios, macos, windows, linux), the generic
  `PlayxPlatformValue<T>`, and `PlayxPlatformVersion` with `macos`, `windows` and `linux` values.
  `PlayxUpdateOptions.appIds` sets the app id per platform and `storeUrls` a custom store URL per platform.
  `checkVersion` runs on Windows and Linux with a custom `versionSource`.
- **"Later" and "Skip this version"**: `reminderOptions` on `showUpdateDialog` (`iosReminderOptions` on
  `showInAppUpdateDialog`) with pluggable `PlayxUpdateStorage` (in memory by default) and `PlayxUpdateReminder`.
  `showUpdateDialog` returns `success(false)` when the prompt is suppressed.
- **Events**: `PlayxUpdateEvents` (`PlayxUpdateUIOptions.events`): shown, update tapped, store open result,
  dismissed, skipped, suppressed, and Android in-app update started / result.
- **Opening the store**: `storeLauncher` and `onStoreOpenResult` to open the store yourself, `preferStoreApp`, and
  `openStore` without a URL (it resolves one from the options) for an "Update" or "Rate us" button.
- **Network**: `PlayxUpdateOptions.networkOptions` (`PlayxNetworkOptions`: retries, timeouts, headers, a custom
  `Dio`, a `CancelToken`), full request and response logging with `enableNetworkLogging` (credentials are
  masked), automatic retry of failures that can succeed later, stable `NetworkErrorCode`s, `isRetryable`,
  and new `AppNotFoundException`, `ConsentRequiredException`, `BadRequestException`,
  `TooManyRequestsException` and `BadCertificateException`.
- **Google consent page**: the EU/UK consent page is reported as `ConsentRequiredException`
  (`STORE_CONSENT_REQUIRED`) instead of a version format error.
- The callback typedefs (`UpdatePressedCallback`, `StoreLauncherCallback`, ...) are exported.
- A documentation site with guides, troubleshooting and a migration guide:
  https://playx-flutter.github.io/playx_version_update/
- Over 330 tests (96% line coverage of `lib/`), CI on every pull request, and publishing to pub.dev
  automated from `v*` tags.

### Changed

- When you pass `newVersion`, the Google Play page is no longer requested on Android; on iOS the App Store
  lookup (needed for the store URL) is best-effort. Passing `storeUrls` with `newVersion` skips it.
- Google Play requests send a browser user agent and `Accept-Language`.
- A forced update is no longer flagged automatically when the app is already current (an explicit
  `forceUpdate: true` still applies), and an empty `minVersion` falls back to the source's.
- Store URLs encode the package id, country and language.

### Deprecated

- `PlayxUpdateOptions.newPlatformVersion` and `minPlatformVersion`: use `versionSource: PlayxStaticVersionSource(...)`.
- `PlayxUpdateOptions.androidPackageName` and `iosBundleId`: use `appIds`.

They keep working and will be removed in a future major release.

### Fixed

- The update dialog and page: a forced dialog with its own `onCancel` no longer also exits the app and is no
  longer closed by its dismiss button; the page's dismiss button closes a dismissible page; the page handles
  the back button like the dialog; the iOS dialog no longer pops its route twice; double taps no longer pop an
  unrelated route or launch the store twice; `onShown` is only reported when something is on screen.
- Errors thrown by your callbacks (events, `onUpdate`, `onCancel`, `storeLauncher`) are reported to
  `FlutterError.onError` instead of leaving the update half-handled.
- Android: an immediate update no longer hangs when it is not allowed; an interrupted immediate update resumes
  when the app returns; cancelling the download subscription after the app was paused no longer fails;
  results are completed on the main thread.
- `PlayxUpdateOptions.localVersion` is honored (it was ignored).
- Versions with a `v` prefix or surrounding spaces are parsed (`v2.0.0` was read as `0.0.0`), and
  `Version.hashCode` is consistent with `==`.
- A Google Play page that merely mentions `consent.google.com` is no longer rejected as the consent form.
- The snooze deadline is stored in UTC.
- A malformed download event no longer breaks the in-app update stream.
- Android Gradle Plugin 9 (built-in Kotlin) is supported.

## 1.3.0
- Add `PlayxPlatformVersion` with `newPlatformVersion` and `minPlatformVersion` overrides for Android- and iOS-specific app version checks.
- Keep `newVersion` and `minVersion` as the effective resolved values in `PlayxVersionUpdateInfo` for backward compatibility.
- Enhance minimum-version parsing for store descriptions with bracketed, case-insensitive matching and broader version-style support.
- Improve HTML text formatting utilities and expand automated test coverage across version handling, parsing, results, errors, and datasource utilities.

## 1.1.0
- Update packages

## 1.0.1
- Update package_info_plus, playx_network, url_launcher packages
- Add option to enable network logging


## 1.0.0 - [2025-07-06]
> Note: This release is a major release and may break some of the existing implementations. Please read the documentation carefully.

This major release introduces significant refactoring, enhanced error handling, improved customization options, and updated build infrastructure.

#### ✨ Major Features & API Enhancements

* **Unified Update Options:**
  * Introduced `PlayxUpdateOptions` to consolidate parameters for version checking (e.g., store IDs, local/new versions, country, language).
  * Introduced `PlayxUpdateUIOptions` to consolidate parameters for the visual presentation of update dialogs/pages (e.g., titles, descriptions, button labels, callbacks, show/hide elements).
  * This refactoring simplifies method signatures for `checkVersion`, `showUpdateDialog`, and `showInAppUpdateDialog`, improving organization and extensibility.
* **Comprehensive Error Handling Rework:**
  * **Enhanced Android In-App Update Errors:** Replaced generic `PlayxInAppUpdateFailed` with a detailed `PlayxInstallError` sealed class, directly mapping to Android's `InstallErrorCode` for specific error types (e.g., `ApiNotAvailable`, `AppNotOwned`, `DownloadNotPresent`).
  * **Improved Network Error Clarity:** Introduced `PlayxVersionNetworkError` to wrap `playx_network`'s `NetworkException`, differentiating network issues from other update errors, while providing specific, user-friendly messages for network-related exceptions during app version checks
  * **Error Consolidation:** Merged `PlayxInAppUpdateInfoRequestCanceledError` into `PlayxInAppUpdateCanceledError` for simplified error handling.
  * Updated Dart error classes to mirror native changes and refined messages for clarity.
* **Flexible Version Parsing:**
  * Introduced a new internal `Version` class for robust and flexible parsing/comparison of version strings (supporting SemVer, multi-part numeric versions, and ignoring non-numeric tags) like 2.25.18.80.
  * Improved Google Play Store version parsing reliability using the new `Version` class.
  * Removed the external `version` package dependency.
* **Advanced UI Customization for Flutter:**
  * Added `PlayxUpdateDisplayType` enum to control Flutter-based update prompt presentation (Dialog, Page, or Page on Force Update).
  * Introduced extensive styling options for Flutter-based update dialogs and pages, including text styles (`titleTextStyle`, `descriptionTextStyle`, `releaseNotesTitleTextStyle`, `releaseNotesTextStyle`, button text styles) and button styles.
  * `PlayxUpdateUIOptions.displayType` now defaults to `pageOnForceUpdate`.
  * `UpdateNameInfoCallback` renamed to `UpdateTextInfoCallback`.

#### ✨ Enhancements & Refinements

* **Improved In-App Update Flow:**
  * If a flexible update is already downloaded, `showInAppUpdateDialog` now prompts to complete it.
  * Enhanced documentation for in-app update methods in `PlayxVersionUpdate`, providing clearer descriptions of immediate and flexible flows, detailed error types, and best practice recommendations.
* **Result Access:** Added `updateData` and `updateError` getters to `PlayxVersionUpdateResult` for easier access to success data or error information.
* **Code Quality:** Minor code formatting, logging cleanup, and general documentation improvements across the package.

#### ⚙️ Build System & Example App Updates

* **Android Gradle Plugin & Kotlin Upgrades:**
  * Upgraded Android Gradle Plugin to `8.7.3` and Kotlin to `2.1.0`.
  * Updated compile SDK to `36`.
  * Set Java and Kotlin JVM target to `17`.
  * Updated Gradle wrapper to `8.12`.
* **Android Example Migration:** Migrated the Android example project to use Gradle Kotlin DSL (`.gradle.kts`).
* **Significantly Improved Example App:**
  * Enhanced UI with updated button labels and more visual elements to demonstrate customization.
  * Showcases extensive UI customization using `PlayxUpdateUIOptions` (custom leading widget, text styles, button styles, action callbacks).
  * Clarified behavior for both Android (native) and iOS (custom UI) for flexible and immediate updates, including detailed `iosUiOptions` examples.
  * Demonstrates using `PlayxUpdateOptions` for `checkVersion` and conditional display of `PlayxUpdatePage` (forced) and `PlayxUpdateDialog` (optional) with custom UI.
  * Added a button/option in the example app to start flexible updates specifically on Android.

#### ⬆️ Dependency Updates

* Updated SDK constraints to `>=3.6.0 <4.0.0` and Flutter to `>=3.27.0`.
* Upgraded `playx_network` to `^0.5.1`.

## 0.2.0
> Note : This release is a major release and may break some of the existing implementations. Please read the documentation carefully.

#### PlayxVersionUpdateResult
#### **Breaking Changes**
- `PlayxVersionUpdateResult.when` now returns a value instead of requiring callbacks to handle data.
- `map` and `mapAsync` now directly return transformed results instead of requiring wrapped factory calls.
- Renamed `Success` and `ERROR` classes to `PlayxVersionUpdateSuccessResult` and  `PlayxVersionUpdateErrorResult`.

#### **Updates**
- **New `isSuccess` and `isError` Getters** – Easily check the result type.  
- **More Flexible `when`, `map`, and `mapAsync` Methods** – Now return transformed values instead of requiring extra wrapping.  

### Enhancements
- Update packages.
- Use `playx_network` for network requests for better error handling.
- Dialog with `forceUpdate` can close the app using `SystemNavigator.pop()` if no `onCancel` callback is provided.



## 0.1.0
> Note : This release is a major release and may break some of the existing implementations. Please read the documentation carefully.

- Plugin now requires the following:
    * Flutter >=3.19.0
    * Dart >=3.3.0
    * compileSDK 34 for Android part
    * Java 17 for Android part
    * Gradle 8.4 for Android part
    * minimum Android sdk is 23

- Update packages.
- The plugin now supports wasm for web.
- Add new methods `getAppVersion` and `getAppBuildNumber` in `PlayxVersionUpdate` to get the app version and build number.
- Enhance compatibility with web.
- Update example app to latest android version and added other platforms.

## 0.0.6 - 0.0.7
- Update packages.
- Add `namespace` to build.gradle for the plugin.
- Remove package name for manifest.

## 0.0.5
- Update packages.
- Enhance network requests logging in debug.

## 0.0.4
- Update packages.
- Bump Dart version to 3.2.0 and flutter to 13.16.0
- Add topics

## 0.0.3
- Better support for IOS.
- Add `PlatformNotSupportedError` error when the platform is not supported, for example trying to use Google play in app update on IOS.

## 0.0.2
- Enhancements for force update.

## 0.0.1
- Initial release.

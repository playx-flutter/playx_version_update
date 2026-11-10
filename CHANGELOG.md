# Changelog
## Unreleased
- Add `PlayxUpdateUIOptions.storeLauncher` to open the store yourself, and `PlayxUpdateEvents.onStoreOpenResult` reporting whether the store opened. On the update button: `onUpdate` > `storeLauncher` > default `openStore`. The callback typedefs (`UpdatePressedCallback`, `StoreLauncherCallback`, ...) are now exported.
- Fix the iOS update dialog popping the route twice when dismissible.
- `PlayxVersionUpdate.openStore` now opens the store app directly (`market://` on Android, `itms-apps://` on iOS) before falling back to the web URL; control it with `preferStoreApp` (also on `PlayxUpdateUIOptions`). It launches directly instead of calling `canLaunchUrl`, so no `<queries>` / `LSApplicationQueriesSchemes` are needed, and it now returns an error whenever nothing could be opened (before, `launchUrl` returning `false` gave `success(false)`).
- Add `PlayxStaticVersionSource`: fixed per-platform version, minimum version, release notes and store URL (`PlayxPlatformVersion` / `PlayxPlatformValue`). The deprecated `newPlatformVersion` / `minPlatformVersion` options now point to it.
- Add `PlayxUpdateOptions.storeUrls` (`PlayxPlatformValue<String>`) to set a custom store URL per platform. It wins over a version source's URL and the derived one; on iOS, providing it with `newVersion` skips the App Store lookup.
- Add `PlayxUpdateOptions.appIds` (`PlayxPlatformValue<String>`) to set the app id per platform. `androidPackageName` and `iosBundleId` still work; `appIds` wins when both are set.
- Add `PlayxPlatform` (android, ios, macos, windows, linux) and the generic `PlayxPlatformValue<T>`. `PlayxPlatformVersion` now extends it and gains `macos`, `windows` and `linux` values, so each platform can have its own version or minimum version. `PlayxVersionRequest` exposes `platform` (with `isAndroid` / `isIos` helpers).
- `checkVersion` can run on macOS, Windows and Linux when a custom `versionSource` is provided; the default store source supports Android and iOS only. `showUpdateDialog` still needs Android or iOS (use `checkVersion` with `PlayxUpdatePage` elsewhere).
- **Deprecate** the `PlayxUpdateOptions.newPlatformVersion` and `minPlatformVersion` options in favor of `versionSource`, which receives the platform in its request. They keep working and will be removed in a future major release.
- Add pluggable `PlayxVersionSource` (`PlayxUpdateOptions.versionSource`) with `PlayxStoreVersionSource` (default), `PlayxCallbackVersionSource` (Remote Config / own backend) and `PlayxFallbackVersionSource`. Options values still win over the source.
- Fix `newVersion` / `newPlatformVersion` not skipping the store lookup. On Android the Google Play page is no longer requested when a version is provided; on iOS the App Store lookup (needed for the store URL) is best-effort and its failure no longer fails the check.
- Add `PlayxUpdateEvents` (`PlayxUpdateUIOptions.events`) for analytics: shown, update tapped, dismissed, skipped, suppressed, and Android in-app update started/result.
- Add "Later" snoozing and "Skip this version" through `reminderOptions` on `showUpdateDialog` / `iosReminderOptions` on `showInAppUpdateDialog`, with pluggable `PlayxUpdateStorage` (in-memory by default). `showUpdateDialog` returns `success(false)` when the prompt is suppressed.
- Detect Google's EU consent page and report it as `ConsentRequiredException` (`STORE_CONSENT_REQUIRED`) instead of a version format error.
- Add `PlayxUpdateOptions.networkOptions` (`PlayxNetworkOptions`): retries, timeouts, headers, a custom `Dio` and a `CancelToken`.
- **Breaking:** raise the minimum Dart SDK to 3.10 and Flutter to 3.38.1; update `dio` to ^5.11.1 and `package_info_plus` to ^10.2.2.
- Remove the `playx_network` dependency in favor of a small lightweight built-in `dio` based network client.
- The `NetworkException` types are still exported from this package, so existing error handling keeps working.
- Add stable `NetworkErrorCode` constants, an `errorCode` and original `cause` on every `NetworkException`, and `PlayxVersionNetworkError.statusCode`.
- Add `BadRequestException`, `TooManyRequestsException` and `BadCertificateException`; 502/504 now map to `ServiceUnavailableException`.
- Add `AppNotFoundException` (`STORE_APP_NOT_FOUND`): Google Play 404 and empty App Store lookups are now reported as "app not found" instead of a format error. App Store 403 is treated as throttling.
- `enableNetworkLogging` now logs the full exchange (request method/URL/headers, response status/headers/timing/body preview, errors, retries) through a dedicated `NetworkLogInterceptor`; sensitive headers are masked.
- Add `NetworkException.isRetryable`, and one automatic retry for retryable failures.
- Send a browser user agent and `Accept-Language` to Google Play.
- Fix the example app so network errors are detected through `PlayxVersionNetworkError`.

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

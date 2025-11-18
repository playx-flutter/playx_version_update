# Changelog

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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/platform/playx_version_update_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/version_checker/version_checker.dart';

/// The main entry point for the Playx Version Update package.
///
/// This utility class provides static methods to:
/// - Check for app updates against the Google Play Store and Apple App Store.
/// - Display customizable update dialogs and pages.
/// - Handle native in-app updates on Android.
/// - Open the app's store page.
abstract class PlayxVersionUpdate {
  PlayxVersionUpdate._();

  static final _versionChecker = VersionChecker();

  /// Checks the app's version against the appropriate app store.
  ///
  /// This method fetches the latest version information from the store and compares
  /// it against the app's current version to determine if an update is available.
  ///
  /// The method intelligently handles forced updates: if `forceUpdate` isn't specified
  /// in the options, its value is automatically calculated by checking if the app's version
  /// is less than `minVersion`.
  ///
  /// You can also bypass the store lookup entirely by providing a `newVersion` in the `options`.
  ///
  /// [options]: A [PlayxUpdateOptions] object to configure the version check.
  ///
  /// Returns a [PlayxVersionUpdateResult] which, on success, contains a
  /// [PlayxVersionUpdateInfo] object with details about the local version, store version,
  /// and whether an update is needed. On failure, it returns a [PlayxVersionUpdateError].
  /// @example
  /// ```dart
  /// final result = await PlayxVersionUpdate.checkVersion(
  ///   options: PlayxUpdateOptions(
  ///     googlePlayId: 'com.example.app',
  ///     appStoreId: 'com.example.app',
  ///   ),
  /// );
  /// result.when(
  ///   success: (info) {
  ///     print('Can update: ${info.canUpdate}');
  ///     print('Store version: ${info.newVersion}');
  ///   },
  ///   error: (error) => print('Error checking version: ${error.message}'),
  /// );
  /// ```
  static Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>> checkVersion({
    PlayxUpdateOptions options = const PlayxUpdateOptions(),
  }) async {
    return _versionChecker.checkVersion(
      options: options,
    );
  }

  /// Opens the app's page on the Google Play Store or Apple App Store.
  ///
  /// [storeUrl]: The direct URL to the app's listing.
  /// [launchMode]: The desired mode for launching the URL. Defaults to opening
  /// externally. See [LaunchMode] for more details.
  ///
  /// Returns a [PlayxVersionUpdateResult] with a `bool` indicating whether the
  /// launch was successful.
  static Future<PlayxVersionUpdateResult<bool>> openStore(
      {required String storeUrl,
      LaunchMode launchMode = LaunchMode.externalApplication}) async {
    final Uri url = Uri.parse(storeUrl);
    if (await canLaunchUrl(url)) {
      try {
        final isLaunched = await launchUrl(url, mode: launchMode);
        return PlayxVersionUpdateResult.success(isLaunched);
      } catch (e) {
        return PlayxVersionUpdateResult.error(DefaultFailureError(
            errorMsg: 'Could not launch store. : ${e.toString()}'));
      }
    } else {
      return const PlayxVersionUpdateResult.error(
          DefaultFailureError(errorMsg: 'Could not launch store.'));
    }
  }

  /// Checks for an update and displays a platform-adaptive dialog or page if one is available.
  ///
  /// This is the simplest way to prompt users to update. The function first calls
  /// `checkVersion` using the provided [options]. If an update is available, it presents a UI:
  /// - A `Material` dialog on Android.
  /// - A `Cupertino` dialog on iOS.
  ///
  /// For forced updates, you can configure it to show a full-screen `PlayxUpdatePage`
  /// instead of a dialog by setting `showPageOnForceUpdate` in [uiOptions].
  ///
  /// This method is ideal for a standard, non-intrusive update prompt on any platform.
  ///
  /// ### Parameters:
  /// - [context]: The `BuildContext` required to show the dialog or page.
  /// - [options]: Configuration for the version check itself, like store IDs or providing a manual version to check against.
  /// - [uiOptions]: Configuration for the look and feel of the update UI, including titles, descriptions, and button callbacks.
  ///
  /// ### Returns:
  /// A [PlayxVersionUpdateResult] with a `bool`. On success, the `bool` is `true`,
  /// indicating that the check was successful and the update UI was triggered.
  /// It does **not** wait for the user to interact with the dialog.
  ///
  /// ### Example:
  /// ```dart
  /// await PlayxVersionUpdate.showUpdateDialog(
  ///   context: context,
  ///   options: PlayxUpdateOptions(
  ///     googlePlayId: 'com.example.app',
  ///     appStoreId: 'com.example.app',
  ///   ),
  ///   uiOptions: PlayxUpdateUIOptions(
  ///     title: (info) => 'Update Available!',
  ///     description: (info) => 'A new version ${info.newVersion} is ready. We recommend updating to the latest version to enjoy new features and bug fixes.',
  ///   ),
  /// );
  /// ```
  ///
  /// @see [showInAppUpdateDialog] for handling native Android in-app updates.
  /// @see [PlayxUpdateOptions] and [PlayxUpdateUIOptions] for all available configurations.
  static Future<PlayxVersionUpdateResult<bool>> showUpdateDialog({
    required BuildContext context,
    PlayxUpdateOptions options = const PlayxUpdateOptions(),
    PlayxUpdateUIOptions uiOptions = const PlayxUpdateUIOptions(),
  }) async {
    final result = await checkVersion(options: options);

    return result.map(
      success: (info) {
        if (!info.canUpdate) {
          return PlayxVersionUpdateResult.error(PlayxVersionCantUpdateError(
              currentVersion: info.localVersion, newVersion: info.newVersion));
        }
        _presentUpdateUI(context, info, uiOptions);
        return const PlayxVersionUpdateResult.success(true);
      },
      error: (error) => PlayxVersionUpdateResult.error(error),
    );
  }

  // IN APP UPDATES

  /// Initiates and displays an in-app update flow for both Android and iOS platforms.
  ///
  /// This function intelligently handles platform-specific update mechanisms, providing
  /// a streamlined approach to prompting users for updates.
  ///
  /// ---
  ///
  /// ## On Android:
  ///
  /// If an update is available and the `type` specified is allowed, this function
  /// will start either a **flexible** or **immediate** in-app update as determined by `PlayxAppUpdateType`.
  ///
  /// ### Flexible Updates:
  /// - If you initiate a flexible update, you can monitor its progress by listening to
  ///   `listenToFlexibleDownloadUpdate`.
  /// - When the update reaches the `PlayxDownloadStatus.downloaded` state, you **must**
  ///   restart your app to install it. Unlike immediate updates, Google Play does not
  ///   automatically trigger an app restart for flexible updates.
  /// - It's highly recommended to check if a flexible update is waiting to be installed
  ///   every time your app resumes. Use `isFlexibleUpdateNeedToBeInstalled` to check
  ///   and `completeFlexibleUpdate` to install the update if one is pending.
  ///   This ensures the update data doesn't unnecessarily occupy user device storage.
  ///
  /// ### Immediate Updates:
  /// - Immediate updates will prompt the user to install the update directly.
  ///
  /// - If there's an update that is already downloaded, it will prompt the user to complete the update.
  /// ---
  ///
  /// ## On iOS:
  ///
  /// This function checks your app's version against the one available on the App Store.
  ///
  /// - If an update is required, it will display an update UI:
  ///   - By default, a `PlayxUpdateDialog` (a Cupertino-styled dialog) is shown.
  ///   - For **force updates**, you can choose to show a `PlayxUpdatePage` instead of the dialog
  ///     by setting `iosUiOptions.showPageOnForceUpdate` to `true`.
  /// - Control whether the update dialog/page can be dismissed by setting `iosUiOptions.isDismissible`.
  ///   By default, it is not dismissible for force updates.
  /// - When the user taps the update action, the app typically opens the App Store.
  ///   You can override this default behavior by providing a custom `onIosUpdate` callback
  ///   within `PlayxUpdateOptions`.
  ///
  /// ---
  ///
  /// ### Parameters:
  /// - `context`: The `BuildContext` required for displaying UI elements (especially on iOS).
  /// - `type`: Specifies the desired Android update flow (`PlayxAppUpdateType.flexible` or `PlayxAppUpdateType.immediate`).
  /// - `iosOptions`: (Optional) iOS-specific Configuration for the version check itself, including store IDs or manual version checking, and the `onIosUpdate` callback. Defaults to `const PlayxUpdateOptions()`.
  /// - `iosUiOptions`: (Optional) iOS-specific UI customization options, such as whether to show a page on force update and divisibility. Defaults to `const PlayxUpdateUIOptions()`.
  ///
  /// ### Returns:
  /// A `Future` that resolves to a `PlayxVersionUpdateResult<bool>`.
  /// - On **success**, the `bool` is `true`, indicating the update process was initiated
  ///   or no update was needed. It does **not** wait for the user to interact with the update UI.
  /// - On **error**, it returns a `PlayxVersionUpdateError` with details about any issues encountered.
  ///
  /// ### Example:
  /// ```dart
  /// await PlayxVersionUpdate.showInAppUpdateDialog(
  ///   context: context,
  ///   type: PlayxAppUpdateType.flexible, // Or PlayxAppUpdateType.immediate
  ///   iosOptions: PlayxUpdateOptions(
  ///     googlePlayId: 'com.example.app', // Required for Android version checking
  ///     appStoreId: '123456789', // Required for iOS version checking
  ///   ),
  ///   iosUiOptions: PlayxUpdateUIOptions(
  ///     showPageOnForceUpdate: true, // Show a full-screen page for forced iOS updates
  ///     isDismissible: false, // Make the iOS update UI non-dismissible
  ///     onIosUpdate: (url) {
  ///       // Optional: Override default iOS App Store opening
  ///       // For example, open a custom in-app browser
  ///     },
  ///   ),
  /// );
  /// ```
  ///
  /// @see [startFlexibleUpdate] and [startImmediateUpdate] for more details on Android update outcomes.
  /// @see [listenToFlexibleDownloadUpdate] for monitoring flexible update progress.
  /// @see [isFlexibleUpdateNeedToBeInstalled] and [completeFlexibleUpdate] for handling pending flexible updates.
  /// @see [checkVersion], [PlayxUpdateDialog], and [PlayxUpdatePage] for iOS update UI specifics.
  /// @see [PlayxUpdateOptions] and [PlayxUpdateUIOptions] for all available configurations.
  static Future<PlayxVersionUpdateResult<bool>> showInAppUpdateDialog({
    required BuildContext context,
    required PlayxAppUpdateType type,
    PlayxUpdateOptions iosOptions = const PlayxUpdateOptions(),
    PlayxUpdateUIOptions iosUiOptions = const PlayxUpdateUIOptions(),
  }) async {
    // For Android, delegate to the native in-app update platform channel.
    if (!kIsWeb && Platform.isAndroid) {
      // If a flexible update is already downloaded, prompt to complete it.
      final isUpdatedNeeded = await isFlexibleUpdateNeedToBeInstalled();
      if (isUpdatedNeeded.updateData ?? false) {
        return completeFlexibleUpdate();
      }

      if (type == PlayxAppUpdateType.flexible) {
        return startFlexibleUpdate();
      } else {
        return startImmediateUpdate();
      }
    }

    // For iOS and other platforms, use the standard dialog flow.
    final result = await checkVersion(options: iosOptions);

    return result.map(
      success: (info) {
        if (!info.canUpdate) {
          return PlayxVersionUpdateResult.error(PlayxVersionCantUpdateError(
              currentVersion: info.localVersion, newVersion: info.newVersion));
        }
        _presentUpdateUI(context, info, iosUiOptions);
        return const PlayxVersionUpdateResult.success(true);
      },
      error: (error) => PlayxVersionUpdateResult.error(error),
    );
  }

  /// Presents the update UI based on the update info and UI options.
  static void _presentUpdateUI(
    BuildContext context,
    PlayxVersionUpdateInfo info,
    PlayxUpdateUIOptions uiOptions,
  ) {
    final shouldForceUpdate = info.forceUpdate;
    final isUiDismissible = uiOptions.isDismissible ?? !shouldForceUpdate;
    final displayType = uiOptions.displayType;

    if (shouldForceUpdate &&
            displayType == PlayxUpdateDisplayType.pageOnForceUpdate ||
        displayType == PlayxUpdateDisplayType.page) {
      final page = PlayxUpdatePage(
        versionUpdateInfo: info,
        uiOptions: uiOptions,
      );
      // Pushing a non-dismissible page should remove all previous routes.
      if (isUiDismissible) {
        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => page),
          (route) => false,
        );
      }
    } else {
      showDialog(
        context: context,
        barrierDismissible: isUiDismissible,
        builder: (_) => PlayxUpdateDialog(
          versionUpdateInfo: info,
          uiOptions: uiOptions,
        ),
      );
    }
  }

  /// Checks if an update is available for the app.
  ///
  /// Returns a [PlayxVersionUpdateResult] indicating whether an update is available,
  /// along with its [PlayxAppUpdateAvailability] status on success.
  static Future<PlayxVersionUpdateResult<PlayxAppUpdateAvailability>>
      getUpdateAvailability() async {
    return PlayxVersionUpdatePlatform.instance.getUpdateAvailability();
  }

  /// Retrieves the number of days since an update became available on the Play Store.
  ///
  /// If an update is available or in progress, this method returns the number of days
  /// the Google Play Store app on the user's device has known about it.
  /// Returns `-1` if no update is available or if staleness information cannot be retrieved.
  ///
  /// Returns a [PlayxVersionUpdateResult] with an [int] representing the number of days on success.
  static Future<PlayxVersionUpdateResult<int>> getUpdateStalenessDays() async {
    return PlayxVersionUpdatePlatform.instance.getUpdateStalenessDays();
  }

  /// Retrieves the priority level of an available in-app update.
  ///
  /// The update priority is an integer value between 0 and 5, where 0 is the default
  /// and 5 indicates the highest priority. This value is set in the Google Play
  /// Developer API's `inAppUpdatePriority` field during release rollout and cannot
  /// be changed later. Higher priority suggests a stronger recommendation to the user.
  ///
  /// Returns a [PlayxVersionUpdateResult] with an [int] representing the priority value on success.
  static Future<PlayxVersionUpdateResult<int>> getUpdatePriority() async {
    return PlayxVersionUpdatePlatform.instance.getUpdatePriority();
  }

  /// Checks if the platform currently allows a specific type of in-app update.
  ///
  /// This method evaluates whether an update of the given [type] (e.g., immediate, flexible)
  /// can proceed based on current device and Play Store conditions.
  ///
  /// Returns a [PlayxVersionUpdateResult] with a [bool] indicating if the update is allowed on success.
  static Future<PlayxVersionUpdateResult<bool>> isUpdateAllowed(
      {required PlayxAppUpdateType type}) async {
    return PlayxVersionUpdatePlatform.instance.isUpdateAllowed(type);
  }

  /// Initiates an **immediate** in-app update flow.
  ///
  /// In an immediate update, the user is prompted with a full-screen UI to accept
  /// the update. The application will be forced to update and restart.
  ///
  /// **Important:** Before calling this, it's recommended to check if there's
  /// a pending flexible update via [isFlexibleUpdateNeedToBeInstalled] and
  /// complete it using [completeFlexibleUpdate] if necessary.
  ///
  /// This method returns a [PlayxVersionUpdateResult] which on error contains
  /// one of the following [PlayxVersionUpdateError] types:
  ///
  /// **General Update Flow Errors:**
  /// - [ActivityNotFoundError]: If the update flow was initiated from a state without an active Android Activity (e.g., deeply in the background).
  /// - [AppUpdateMangerNotFoundError]: If the Android App Update Manager service is unavailable or outdated on the device (e.g., missing Google Play Services).
  /// - [PlayxInAppUpdateCanceledError]: The user explicitly denied or canceled the update prompt.
  /// - [PlayxInAppUpdateFailedError]: A general failure occurred during the update process (e.g., user confirmation, download, or initial installation preparation).
  /// - [PlatformNotSupportedError]: If the method is called on a platform that does not support in-app updates (e.g., iOS, web).
  /// - [DefaultFailureError]: A generic fallback for other unspecified errors.
  ///
  /// **Installation-Specific Errors (subclasses of [PlayxInstallError]):**
  /// These errors indicate issues related to the download or preparation for installation. Examples include:
  /// - [InstallApiNotAvailableError]: In-app updates API is not supported on the device.
  /// - [InstallAppNotOwnedError]: The app is not recognized as genuinely owned by a user from Play Store.
  /// - [InstallDownloadNotPresentError]: The update download is not complete.
  /// - [InstallInProgressError]: Another update installation is already active.
  /// - [InstallNotAllowedError]: Download/installation is not allowed due to device state (e.g., low storage, low battery, network restrictions, system policies).
  /// - [InstallUnavailableError]: Update is unavailable for the specific user or device profile.
  /// - [InstallInternalError]: An unexpected internal error within Google Play Store.
  /// - [InstallInvalidRequestError]: The update request sent by the app is malformed.
  /// - [InstallPlayStoreNotFoundError]: Google Play Store app is not found or is not official.
  /// - [InstallUnknownError]: An unknown installation error occurred.
  /// On success, it theoretically returns `true` (indicating user acceptance and update success),
  /// though in practice, your app will have already updated and restarted before this `true` value is received.
  static Future<PlayxVersionUpdateResult<bool>> startImmediateUpdate() async {
    return PlayxVersionUpdatePlatform.instance.startImmediateUpdate();
  }

  /// Initiates a **flexible** in-app update flow.
  ///
  /// In a flexible update, the update downloads in the background while
  /// the user continues to interact with the app. You must then manually
  /// trigger the installation via [completeFlexibleUpdate].
  ///
  /// **Important:** Before calling this, it's recommended to check if there's
  /// a pending flexible update via [isFlexibleUpdateNeedToBeInstalled] and
  /// complete it using [completeFlexibleUpdate] if necessary.
  ///
  /// This method returns a [PlayxVersionUpdateResult] which on error contains
  /// one of the following [PlayxVersionUpdateError] types:
  ///
  /// **General Update Flow Errors:**
  /// - [ActivityNotFoundError]: If the update flow was initiated from a state without an active Android Activity (e.g., deeply in the background).
  /// - [AppUpdateMangerNotFoundError]: If the Android App Update Manager service is unavailable or outdated on the device (e.g., missing Google Play Services).
  /// - [PlayxInAppUpdateCanceledError]: The user explicitly denied or canceled the update prompt.
  /// - [PlayxInAppUpdateFailedError]: A general failure occurred during the update process (e.g., user confirmation, download, or initial installation preparation).
  /// - [PlatformNotSupportedError]: If the method is called on a platform that does not support in-app updates (e.g., iOS, web).
  /// - [DefaultFailureError]: A generic fallback for other unspecified errors.
  ///
  /// **Installation-Specific Errors (subclasses of [PlayxInstallError]):**
  /// These errors indicate issues related to the download or preparation for installation. Examples include:
  /// - [InstallApiNotAvailableError]: In-app updates API is not supported on the device.
  /// - [InstallAppNotOwnedError]: The app is not recognized as genuinely owned by a user from Play Store.
  /// - [InstallDownloadNotPresentError]: The update download is not complete.
  /// - [InstallInProgressError]: Another update installation is already active.
  /// - [InstallNotAllowedError]: Download/installation is not allowed due to device state (e.g., low storage, low battery, network restrictions, system policies).
  /// - [InstallUnavailableError]: Update is unavailable for the specific user or device profile.
  /// - [InstallInternalError]: An unexpected internal error within Google Play Store.
  /// - [InstallInvalidRequestError]: The update request sent by the app is malformed.
  /// - [InstallPlayStoreNotFoundError]: Google Play Store app is not found or is not official.
  /// - [InstallUnknownError]: An unknown installation error occurred.
  ///
  /// On success, it returns `true` indicating the user accepted the request to download the update.
  static Future<PlayxVersionUpdateResult<bool>> startFlexibleUpdate() async {
    return PlayxVersionUpdatePlatform.instance.startFlexibleUpdate();
  }

  /// Monitors the progress and state of a flexible in-app update download.
  ///
  /// This method returns a [Stream] of [PlayxDownloadInfo] that emits updates
  /// on the download's progress and status. You can use this to provide a
  /// progress bar or other UI feedback to the user.
  ///
  /// The stream emits `null` if no flexible update download is in progress.
  ///
  /// Returns a [Stream<PlayxDownloadInfo?>].
  static Stream<PlayxDownloadInfo?> listenToFlexibleDownloadUpdate() {
    return PlayxVersionUpdatePlatform.instance.getDownloadInfo();
  }

  /// Completes and installs a downloaded flexible in-app update.
  ///
  /// You should call this method once you detect the [PlayxDownloadStatus.downloaded] state
  /// (e.g., via [listenToFlexibleDownloadUpdate] or by checking [isFlexibleUpdateNeedToBeInstalled]).
  /// Unlike immediate updates, flexible updates require your app to explicitly trigger the installation.
  ///
  /// **Best Practices:**
  /// - **User Notification:** Provide a clear UI indication (e.g., a notification or dialog)
  ///   to inform the user that the update is ready and request their confirmation before restarting the app.
  /// - **App Resume Check:** It's highly recommended to call [isFlexibleUpdateNeedToBeInstalled]
  ///   when your app resumes to check if an update is waiting to be installed. This prevents
  ///   downloaded update data from unnecessarily occupying device storage.
  ///
  /// **Installation Behavior:**
  /// - If called when your app is in the **foreground**, the platform displays a full-screen UI
  ///   that restarts the app in the background to complete the installation.
  /// - If called when your app is in the **background**, the update is installed silently
  ///   without obscuring the device UI.
  ///
  /// Returns a [PlayxVersionUpdateResult] with `true` on successful completion of the installation process.
  static Future<PlayxVersionUpdateResult<bool>> completeFlexibleUpdate() {
    return PlayxVersionUpdatePlatform.instance.completeFlexibleUpdate();
  }

  /// Checks if a flexible in-app update has been downloaded and is ready for installation.
  ///
  /// This method is crucial to use before calling [completeFlexibleUpdate],
  /// especially when your app resumes, to ensure downloaded updates are installed
  /// and don't unnecessarily occupy device storage.
  ///
  /// Returns a [PlayxVersionUpdateResult] with `true` if a flexible update is downloaded and ready to be installed,
  /// and `false` otherwise, on success.
  static Future<PlayxVersionUpdateResult<bool>>
      isFlexibleUpdateNeedToBeInstalled() {
    return PlayxVersionUpdatePlatform.instance
        .isFlexibleUpdateNeedToBeInstalled();
  }

  /// Refreshes the internal state of the in-app update manager.
  ///
  /// This can be useful to re-initialize the update manager's connection
  /// to the Google Play Store if it enters an unexpected state.
  ///
  /// Returns a [PlayxVersionUpdateResult] with `true` if the refresh was successful, and `false` otherwise.
  static Future<PlayxVersionUpdateResult<bool>> refreshInAppUpdate() {
    return PlayxVersionUpdatePlatform.instance.refreshInAppUpdate();
  }

  /// Retrieves the current version name of the app from its `pubspec.yaml` file.
  ///
  /// This typically corresponds to the `version` field (e.g., "1.0.0").
  static Future<String> getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Retrieves the current build number (or build code) of the app.
  ///
  /// This typically corresponds to the `build` part of the version string in `pubspec.yaml`
  /// (e.g., "1" if the version is "1.0.0+1").
  static Future<String> getAppBuildNumber() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
}

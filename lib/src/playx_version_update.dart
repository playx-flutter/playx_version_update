import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/model/options/playx_update_display_type.dart';
import 'package:playx_version_update/src/core/model/options/playx_update_ui_options.dart';
import 'package:playx_version_update/src/platform/playx_version_update_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/model/options/playx_update_options.dart';
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
  /// - `options`: (Optional) Configuration for the version check itself, including store IDs or manual version checking, and the `onIosUpdate` callback. Defaults to `const PlayxUpdateOptions()`.
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
  ///   options: PlayxUpdateOptions(
  ///     googlePlayId: 'com.example.app', // Required for Android version checking
  ///     appStoreId: '123456789', // Required for iOS version checking
  ///     onIosUpdate: (url) {
  ///       // Optional: Override default iOS App Store opening
  ///       // For example, open a custom in-app browser
  ///     },
  ///   ),
  ///   iosUiOptions: PlayxUpdateUIOptions(
  ///     showPageOnForceUpdate: true, // Show a full-screen page for forced iOS updates
  ///     isDismissible: false, // Make the iOS update UI non-dismissible
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
    PlayxUpdateOptions options = const PlayxUpdateOptions(),
    PlayxUpdateUIOptions iosUiOptions = const PlayxUpdateUIOptions(),
  }) async {
    // For Android, delegate to the native in-app update platform channel.
    if (!kIsWeb && Platform.isAndroid) {
      if (type == PlayxAppUpdateType.flexible) {
        return startFlexibleUpdate();
      } else {
        return startImmediateUpdate();
      }
    }

    // For iOS and other platforms, use the standard dialog flow.
    final result = await checkVersion(options: options);

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

  ///Check for update availability:
  ///checks if there is an update available for your app or not.
  ///returns [PlayxVersionUpdateResult] with [PlayxAppUpdateAvailability] on success.
  static Future<PlayxVersionUpdateResult<PlayxAppUpdateAvailability>>
      getUpdateAvailability() async {
    return PlayxVersionUpdatePlatform.instance.getUpdateAvailability();
  }

  /// Check the number of days since the update became available on the Play Store
  ///If an update is available or in progress, this method returns the number of days
  /// since the Google Play Store app on the user's device has learnt about an available update.
  ///If update is not available, or if staleness information is unavailable, this method returns -1.
  ///returns [PlayxVersionUpdateResult] with [int] number of days on success.
  static Future<PlayxVersionUpdateResult<int>> getUpdateStalenessDays() async {
    return PlayxVersionUpdatePlatform.instance.getUpdateStalenessDays();
  }

  //The Google Play Developer API allows you to set the priority of each update.
  // This allows your app to decide how strongly to recommend an update to the user.
  //To determine priority, Google Play uses an integer value between 0 and 5, with 0 being the default and 5 being the highest priority.
  // To set the priority for an update, use the inAppUpdatePriority field under Edits.tracks.releases in the Google Play Developer API.
  // All newly-added versions in the release are considered to be the same priority as the release.
  // Priority can only be set when rolling out a new release and cannot be changed later.
  ///returns [PlayxVersionUpdateResult] with [int] priority value on success.
  static Future<PlayxVersionUpdateResult<int>> getUpdatePriority() async {
    return PlayxVersionUpdatePlatform.instance.getUpdatePriority();
  }

  // Checks that the platform will allow the specified type of update or not.
  ///returns [PlayxVersionUpdateResult] with [bool] isAllowed value on success.
  static Future<PlayxVersionUpdateResult<bool>> isUpdateAllowed(
      {required PlayxAppUpdateType type}) async {
    return PlayxVersionUpdatePlatform.instance.isUpdateAllowed(type);
  }

  ///Starts immediate update flow.
  ///In the immediate flow, the method returns one of the following values of the [PlayxVersionUpdateResult]:
  /// [bool] : The user accepted and the update succeeded.
  /// (which, in practice, your app never should never receive because it already updated).
  ///[ActivityNotFoundError] : When the user started the update flow from background.
  ///[PlayxInAppUpdateCanceledError] : The user denied or canceled the update.
  ///[PlayxInAppUpdateInfoRequestCanceledError] : Checking update availability was canceled.
  /// [PlayxInAppUpdateFailedError] : The flow failed either during the user confirmation, the download, or the installation.
  /// [DefaultFailureError] : other errors that may occur during the update flow.
  static Future<PlayxVersionUpdateResult<bool>> startImmediateUpdate() async {
    return PlayxVersionUpdatePlatform.instance.startImmediateUpdate();
  }

  ///Starts Flexible update flow.
  ///In the flexible flow, the method returns one of the following values:
  /// [bool] : The user accepted the request to update.
  ///[ActivityNotFoundError] : : When the user started the update flow from background.
  ///[PlayxInAppUpdateCanceledError] : The user denied the request to update.
  ///[PlayxInAppUpdateInfoRequestCanceledError] : Checking update availability was canceled.
  ///[PlayxInAppUpdateFailedError] :: Something failed during the request for user confirmation. For example, the user terminates the app before responding to the request.
  /// [DefaultFailureError] : other errors that may occur during the update flow.
  static Future<PlayxVersionUpdateResult<bool>> startFlexibleUpdate() async {
    return PlayxVersionUpdatePlatform.instance.startFlexibleUpdate();
  }

  ///Monitor the state of an update in progress by registering a listener for install status updates.
  /// You can also provide a progress bar in the app's UI to inform users of the download's progress.
  ///returns stream of [PlayxDownloadInfo] current download progress value on success.
  static Stream<PlayxDownloadInfo?> listenToFlexibleDownloadUpdate() {
    return PlayxVersionUpdatePlatform.instance.getDownloadInfo();
  }

  ///Install a flexible update.
  /// When you detect the [PlayxDownloadStatus.downloaded] state, you need to restart the app to install the update.
  ///Unlike with immediate updates, Google Play does not automatically trigger an app restart for a flexible update.
  ///This is because during a flexible update, the user has an expectation to continue interacting with the app until they decide that they want to install the update.
  ///It is recommended that you provide a notification (or some other UI indication)
  /// to inform the user that the update is ready to install and request confirmation before restarting the app.
  /// You can check if the app needs to be installed from : [isFlexibleUpdateNeedToBeInstalled]
  /// it's also recommended to use this method on App resume to  check whether your app has an update waiting to be installed.
  /// If your app has an update in the DOWNLOADED state, prompt the user to install the update.
  /// Otherwise, the update data continues to occupy the user's device storage.
  /// When you call [completeFlexibleUpdate] in the foreground, the platform displays a full-screen UI that restarts the app in the background.
  /// After the platform installs the update, your app restarts into its main.
  /// If you instead call [completeFlexibleUpdate] when your app is in the background,
  /// the update is installed silently without obscuring the device UI.
  static Future<PlayxVersionUpdateResult<bool>> completeFlexibleUpdate() {
    return PlayxVersionUpdatePlatform.instance.completeFlexibleUpdate();
  }

  ///Whether or not there is any flexible update that need to be installed.
  ///should be used before calling [completeFlexibleUpdate] unless you know that the update is downloaded.
  ///returns [PlayxVersionUpdateResult] with [bool] on success that if true the flexible download is downloaded and ready to be installed.
  static Future<PlayxVersionUpdateResult<bool>>
      isFlexibleUpdateNeedToBeInstalled() {
    return PlayxVersionUpdatePlatform.instance
        .isFlexibleUpdateNeedToBeInstalled();
  }

  ///Refreshes app update manger.
  ///returns [PlayxVersionUpdateResult] with [bool] on success of whether refreshed or not.
  static Future<PlayxVersionUpdateResult<bool>> refreshInAppUpdate() {
    return PlayxVersionUpdatePlatform.instance.refreshInAppUpdate();
  }

  /// Get the current version of the app.
  static Future<String> getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Get the current build number of the app.
  static Future<String> getAppBuildNumber() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
}

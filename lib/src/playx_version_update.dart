import 'dart:io';

import 'package:flutter/material.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/utils/callbacks.dart';
import 'package:playx_version_update/src/platform/playx_version_update_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/version_checker/version_checker.dart';

abstract class PlayxVersionUpdate {
  PlayxVersionUpdate._();

  static final _versionChecker = VersionChecker();

  ///Check the version of the app on Google play store in Android Or App Store in IOS
  ///Takes [localVersion] : which is the current version of the app, If not provided It will get it from the app information.
  ///If [newVersion] is provided it will compare it with the current version. If not it will get it from the store information.
  ///[forceUpdate] whether to force the update or not. If [minVersion] is provided it will compare it with the current version.
  /// If current version is lower than the minimum version it will return [forceUpdate] as true to force the update if forceUpdate is not set.
  ///  [googlePlayId],[appStoreId] the app package or bundle id. If not provided it will get it from the app information.
  /// [country], [language] decides which country and language we will get app information from the store. default is 'us' and 'en'.
  ///returns [PlayxVersionUpdateResult] : which on success returns [PlayxVersionUpdateInfo] which contains information about the current version and the latest version.
  ///and whether the app should update of force update to the latest version.
  ///on Error returns [PlayxVersionUpdateError] which contains information about the error.
  static Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>> checkVersion({
    String? localVersion,
    String? newVersion,
    String? minVersion,
    bool? forceUpdate,
    String? googlePlayId,
    String? appStoreId,
    String country = 'us',
    String language = 'en',
  }) async {
    return _versionChecker.checkVersion(
      localVersion: localVersion,
      newVersion: newVersion,
      minVersion: minVersion,
      forceUpdate: forceUpdate,
      googlePlayId: googlePlayId,
      appStoreId: appStoreId,
      country: country,
      language: language,
    );
  }

  ///Open the Google play store in Android Or App Store in IOS
  ///Takes [String] storeUrl : which is the URL to the Specified store.
  ///[LaunchMode] :Which decide the desired mode to launch the store.
  /// Support for these modes varies by platform. Platforms that do not support
  /// the requested mode may substitute another mode. See [launchUrl] for more details.
  ///returns [PlayxVersionUpdateResult] with [bool] on success.
  ///and  returns [PlayxVersionUpdateError] on error which contains information about the error.
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

  ///Check the version of the app on Google play store in Android Or App Store in IOS.
  ///Then shows [PlayxUpdateDialog] which shows material update dialog for android and Cupertino Dialog for IOS.
  /// If the app needs to force update you can show [PlayxUpdatePage] instead of the dialog by setting [showPageOnForceUpdate] : to true.
  /// Update [isDismissible] to set if the [PlayxUpdateDialog] or [PlayxUpdatePage] are dismissible or not if not provided it will be not dismissible on force update.
  /// check out [checkVersion] and [PlayxUpdateDialog] and [PlayxUpdatePage] to learn more about the parameters used.
  /// When the user clicks on update action the app open the store, If you want to override this behavior you can call [onUpdate].
  ///returns [PlayxVersionUpdateResult] with [bool] on success.
  ///and  returns [PlayxVersionUpdateError] on error which contains information about the error.
  static Future<PlayxVersionUpdateResult<bool>> showUpdateDialog({
    required BuildContext context,
    String? localVersion,
    String? newVersion,
    String? minVersion,
    String? googlePlayId,
    String? appStoreId,
    String country = 'us',
    String language = 'en',
    bool? forceUpdate,
    bool showPageOnForceUpdate = false,
    bool? isDismissible,
    UpdateNameInfoCallback? title,
    UpdateNameInfoCallback? description,
    UpdateNameInfoCallback? releaseNotesTitle,
    bool showReleaseNotes = false,
    bool showDismissButtonOnForceUpdate = true,
    String? updateActionTitle,
    String? dismissActionTitle,
    UpdatePressedCallback? onUpdate,
    UpdateCancelPressedCallback? onCancel,
    LaunchMode launchMode = LaunchMode.externalApplication,
    Widget? leading,
  }) async {
    final result = await checkVersion(
      localVersion: localVersion,
      newVersion: newVersion,
      minVersion: minVersion,
      forceUpdate: forceUpdate,
      googlePlayId: googlePlayId,
      appStoreId: appStoreId,
      country: country,
      language: language,
    );

    return result.map(success: (result) {
      final info = result.data;
      if (!info.canUpdate) {
        return PlayxVersionUpdateResult.error(PlayxVersionCantUpdateError(
            currentVersion: info.localVersion, newVersion: info.newVersion));
      }

      final shouldForceUpdate = info.forceUpdate;
      final isDialogDismissible = isDismissible ?? !shouldForceUpdate;

      if (shouldForceUpdate && showPageOnForceUpdate) {
        final page = PlayxUpdatePage(
          versionUpdateInfo: info,
          title: title,
          description: description,
          releaseNotesTitle: releaseNotesTitle,
          showReleaseNotes: showReleaseNotes,
          updateActionTitle: updateActionTitle,
          dismissActionTitle: dismissActionTitle,
          showDismissButtonOnForceUpdate: showDismissButtonOnForceUpdate,
          launchMode: launchMode,
          onUpdate: onUpdate,
          onCancel: onCancel,
          leading: leading,
        );
        if (isDialogDismissible) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (BuildContext context) => page),
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(builder: (BuildContext context) => page),
            (route) => false,
          );
        }
      } else {
        showDialog(
          context: context,
          barrierDismissible: isDialogDismissible,
          builder: (context) => PlayxUpdateDialog(
            versionUpdateInfo: info,
            title: title,
            description: description,
            releaseNotesTitle: releaseNotesTitle,
            showReleaseNotes: showReleaseNotes,
            updateActionTitle: updateActionTitle,
            dismissActionTitle: dismissActionTitle,
            showDismissButtonOnForceUpdate: showDismissButtonOnForceUpdate,
            launchMode: launchMode,
            onUpdate: onUpdate,
            onCancel: onCancel,
            isDismissible: isDialogDismissible,
          ),
        );
      }
      return const PlayxVersionUpdateResult.success(true);
    }, error: (error) {
      return PlayxVersionUpdateResult.error(error.error);
    });
  }

  // IN APP UPDATES

  ///In Android:
  ///If there is an update available and the update type is allowed.
  /// It starts either flexible update or immediate update specified by [PlayxAppUpdateType].
  /// If you started a flexible update you can listen to update progress from [listenToFlexibleDownloadUpdate]
  /// When you detect the [PlayxDownloadStatus.downloaded] state, you need to restart the app to install the update.
  ///Unlike with immediate updates, Google Play does not automatically trigger an app restart for a flexible update.
  ///So you need to complete the update after it's downloaded.
  /// it's also recommended to check whether your app has an update waiting to be installed on App resume.
  /// If your app has an update in the DOWNLOADED state, prompt the user to install the update.
  /// Otherwise, the update data continues to occupy the user's device storage.
  /// To check if flexible update needs to be completed call [isFlexibleUpdateNeedToBeInstalled] and to complete the update call [completeFlexibleUpdate]
  /// Check out [startFlexibleUpdate] and [startImmediateUpdate] to learn more about the result of each call.
  /// In IOS:
  ///Check the version of the app on the App Store.
  ///Then shows [PlayxUpdateDialog] which shows Cupertino Dialog for IOS.
  /// If the app needs to force update you can show [PlayxUpdatePage] instead of the dialog by setting [showPageOnForceUpdate] : to true.
  /// Update [isDismissible] to set if the [PlayxUpdateDialog] or [PlayxUpdatePage] are dismissible or not if not provided it will be not dismissible on force update.
  /// check out [checkVersion] and [PlayxUpdateDialog] and [PlayxUpdatePage] to learn more about the parameters used.
  /// When the user clicks on update action the app open the app store, If you want to override this behavior you can call [onIosUpdate].
  ///returns [PlayxVersionUpdateResult] with [bool] on success.
  ///and  returns [PlayxVersionUpdateError] on error which contains information about the error.
  static Future<PlayxVersionUpdateResult<bool>> showInAppUpdateDialog({
    required BuildContext context,
    required PlayxAppUpdateType type,
    bool? forceUpdate,
    String? localVersion,
    String? newVersion,
    String? minVersion,
    String? googlePlayId,
    String? appStoreId,
    String country = 'us',
    String language = 'en',
    bool showPageOnForceUpdate = false,
    bool? isDismissible = true,
    UpdateNameInfoCallback? title,
    UpdateNameInfoCallback? description,
    UpdateNameInfoCallback? releaseNotesTitle,
    bool showReleaseNotes = false,
    bool showDismissButtonOnForceUpdate = true,
    String? updateActionTitle,
    String? dismissActionTitle,
    UpdatePressedCallback? onIosUpdate,
    UpdateCancelPressedCallback? onIosCancel,
    LaunchMode launchMode = LaunchMode.externalApplication,
    Widget? leading,
  }) async {
    if (Platform.isAndroid) {
      if (type == PlayxAppUpdateType.flexible) {
        return startFlexibleUpdate();
      } else {
        return startImmediateUpdate();
      }
    } else {
      final result = await checkVersion(
        localVersion: localVersion,
        newVersion: newVersion,
        minVersion: minVersion,
        forceUpdate: forceUpdate,
        googlePlayId: googlePlayId,
        appStoreId: appStoreId,
        country: country,
        language: language,
      );

      return result.map(success: (result) {
        final info = result.data;

        if (!info.canUpdate) {
          return PlayxVersionUpdateResult.error(PlayxVersionCantUpdateError(
              currentVersion: info.localVersion, newVersion: info.newVersion));
        }

        final shouldForceUpdate = info.forceUpdate;
        final isDialogDismissible = isDismissible ?? !shouldForceUpdate;
        if (shouldForceUpdate && showPageOnForceUpdate) {
          final page = PlayxUpdatePage(
            versionUpdateInfo: info,
            title: title,
            description: description,
            releaseNotesTitle: releaseNotesTitle,
            showReleaseNotes: showReleaseNotes,
            updateActionTitle: updateActionTitle,
            dismissActionTitle: dismissActionTitle,
            showDismissButtonOnForceUpdate: showDismissButtonOnForceUpdate,
            launchMode: launchMode,
            onUpdate: onIosUpdate,
            onCancel: onIosCancel,
            leading: leading,
          );
          if (isDialogDismissible) {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (BuildContext context) => page),
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute<void>(builder: (BuildContext context) => page),
              (route) => false,
            );
          }
        } else {
          showDialog(
              context: context,
              barrierDismissible: isDialogDismissible,
              builder: (context) => PlayxUpdateDialog(
                    versionUpdateInfo: info,
                    title: title,
                    description: description,
                    releaseNotesTitle: releaseNotesTitle,
                    showReleaseNotes: showReleaseNotes,
                    updateActionTitle: updateActionTitle,
                    dismissActionTitle: dismissActionTitle,
                    showDismissButtonOnForceUpdate:
                        showDismissButtonOnForceUpdate,
                    launchMode: launchMode,
                    onUpdate: onIosUpdate,
                    onCancel: onIosCancel,
                    isDismissible: isDialogDismissible,
                  ));
        }
        return const PlayxVersionUpdateResult.success(true);
      }, error: (error) {
        return PlayxVersionUpdateResult.error(error.error);
      });
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
}

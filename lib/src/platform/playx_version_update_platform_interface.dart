import 'package:playx_version_update/playx_version_update.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'playx_version_update_method_channel.dart';


abstract class PlayxVersionUpdatePlatform extends PlatformInterface {
  /// Constructs a PlayxVersionUpdatePlatform.
  PlayxVersionUpdatePlatform() : super(token: _token);

  static final Object _token = Object();

  static PlayxVersionUpdatePlatform _instance =
      MethodChannelPlayxVersionUpdate();

  /// The default instance of [PlayxVersionUpdatePlatform] to use.
  /// Defaults to [MethodChannelPlayxVersionUpdate].
  static PlayxVersionUpdatePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PlayxVersionUpdatePlatform] when
  /// they register themselves.
  static set instance(PlayxVersionUpdatePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    // DartPluginRegistrant.ensureInitialized();
    // WidgetsFlutterBinding.ensureInitialized();
    _instance = instance;
  }

  //Check for update availability:
  //checks if there is an update available for your app.
  Future<PlayxVersionUpdateResult<PlayxAppUpdateAvailability>>
      getUpdateAvailability() async {
    return PlayxVersionUpdateResult<PlayxAppUpdateAvailability>.error(PlatformNotSupportedError());
  }

  // check the number of days since the update became available on the Play Store
  //If an update is available or in progress, this method returns the number of days
  // since the Google Play Store app on the user's device has learnt about an available update.
  //If update is not available, or if staleness information is unavailable, this method returns -1.
  Future<PlayxVersionUpdateResult<int>> getUpdateStalenessDays() async {
    return PlayxVersionUpdateResult<int>.error(PlatformNotSupportedError());
  }

  //The Google Play Developer API allows you to set the priority of each update.
  // This allows your app to decide how strongly to recommend an update to the user.
  //To determine priority, Google Play uses an integer value between 0 and 5, with 0 being the default and 5 being the highest priority.
  // To set the priority for an update, use the inAppUpdatePriority field under Edits.tracks.releases in the Google Play Developer API.
  // All newly-added versions in the release are considered to be the same priority as the release.
  // Priority can only be set when rolling out a new release and cannot be changed later.
  // This method returns the current priority value.
  Future<PlayxVersionUpdateResult<int>> getUpdatePriority() async {
    return PlayxVersionUpdateResult<int>.error(PlatformNotSupportedError());
  }

  // Checks that the platform will allow the specified type of update.
  Future<PlayxVersionUpdateResult<bool>> isUpdateAllowed(
      PlayxAppUpdateType type) async {
    return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
  }

  //Starts immediate update flow.
  //In the immediate flow, the method returns one of the following values:
  //Boolean [success]: The user accepted and the update succeeded (which, in practice, your app never should never receive because it already updated).
  //ActivityNotFoundException : When the user started the update flow from background.
  //PlayxRequestCanceledException : The user denied or canceled the update.
  //PlayxInAppUpdateFailed: The flow failed either during the user confirmation, the download, or the installation.
  Future<PlayxVersionUpdateResult<bool>> startImmediateUpdate() async {
    return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
  }

  //Starts Flexible update flow.
  //In the immediate flow, the method returns one of the following values:
  //Boolean [success]: The user accepted the request to update.
  //ActivityNotFoundException : When the user started the update flow from background.
  //PlayxRequestCanceledException : The user denied the request to update.
  //PlayxInAppUpdateFailed: Something failed during the request for user confirmation. For example, the user terminates the app before responding to the request.
  Future<PlayxVersionUpdateResult<bool>> startFlexibleUpdate()async {
    return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
  }

  ///Stream to listen to current status of the in app update.
  ///Only available in Android.
  Stream<PlayxDownloadInfo?> getDownloadInfo() {
   return const Stream.empty();
  }

  //Install a flexible update
  //When you detect the InstallStatus.DOWNLOADED state, you need to restart the app to install the update.
  //
  //Unlike with immediate updates, Google Play does not automatically trigger an app restart for a flexible update.
  // This is because during a flexible update, the user has an expectation to continue interacting with the app until they decide that they want to install the update.
  //
  //It is recommended that you provide a notification (or some other UI indication) to inform the user that the update is ready to install and request confirmation before restarting the app.
  Future<PlayxVersionUpdateResult<bool>> completeFlexibleUpdate()async {
    return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
  }

  //Whether or not the flexible update is ready to install .
  Future<PlayxVersionUpdateResult<bool>> isFlexibleUpdateNeedToBeInstalled()async {
    return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
  }

  // refreshes app update manger
  //Each Update manger instance can be used only in a single call to this method.
  // If you need to call it multiple times - for instance, when retrying to start a flow in case of failure - you need to get a fresh Update manger.
  Future<PlayxVersionUpdateResult<bool>> refreshInAppUpdate()async {
    return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
  }
}

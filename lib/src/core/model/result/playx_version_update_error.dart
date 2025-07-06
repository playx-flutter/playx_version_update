import 'package:playx_network/playx_network.dart' as network;

// Constants for general PlayxVersionUpdate errors
const String _activityNotFoundErrorCode = 'ACTIVITY_NOT_FOUND';
const String _appUpdateMangerNotFoundErrorCode = 'APP_UPDATE_MANGER_NOT_FOUND';
const String _playxInAppUpdateInfoRequestCanceledErrorCode =
    'PLAYX_INFO_REQUEST_CANCELLED'; // Renamed for clarity
const String _playxInAppUpdateCanceledErrorCode = 'PLAYX_UPDATE_CANCELLED';
const String _playxInAppUpdateFailedErrorCode = 'PLAYX_IN_APP_UPDATE_FAILED';
const String defaultFailureErrorCode = 'DEFAULT_FAILURE_ERROR';
const String _platformNotSupportedErrorCode = 'PLATFORM_NOT_SUPPORTED_ERROR';

// Constants for specific PlayxInstallError codes (matching Kotlin)
const String _installApiNotAvailableErrorCode = 'INSTALL_API_NOT_AVAILABLE';
const String _installAppNotOwnedErrorCode = 'INSTALL_APP_NOT_OWNED';
const String _installDownloadNotPresentErrorCode = 'INSTALL_DOWNLOAD_NOT_PRESENT';
const String _installInProgressErrorCode = 'INSTALL_IN_PROGRESS';
const String _installNotAllowedErrorCode = 'INSTALL_NOT_ALLOWED';
const String _installUnavailableErrorCode = 'INSTALL_UNAVAILABLE';
const String _installInternalErrorCode = 'INSTALL_INTERNAL_ERROR';
const String _installInvalidRequestErrorCode = 'INSTALL_INVALID_REQUEST';
const String _installPlayStoreNotFoundErrorCode = 'INSTALL_PLAY_STORE_NOT_FOUND';
const String _installUnknownErrorCode = 'INSTALL_UNKNOWN_ERROR';


/// Sealed class representing all possible errors that can occur during
/// Playx Version Update operations.
sealed class PlayxVersionUpdateError {
  /// A human-readable message describing the error.
  String get message;

  /// A unique string code identifying the type of error.
  String get errorCode;

  const PlayxVersionUpdateError();

  /// Factory constructor to create a [PlayxVersionUpdateError] from a
  /// platform-specific error code and message, typically from Android's in-app update.
  factory PlayxVersionUpdateError.fromInAppUpdateErrorCode(
      String errorCode, String errorMessage) {
    // Check for specific PlayxInstallError codes first
    if (errorCode.startsWith('INSTALL_')) {
      return PlayxInstallError.fromKotlinErrorCode(errorCode, errorMessage);
    }

    // Handle other general in-app update errors
    return switch (errorCode) {
      _activityNotFoundErrorCode => ActivityNotFoundError(),
      _appUpdateMangerNotFoundErrorCode => AppUpdateMangerNotFoundError(),
      _playxInAppUpdateInfoRequestCanceledErrorCode =>
          PlayxInAppUpdateInfoRequestCanceledError(),
      _playxInAppUpdateCanceledErrorCode => PlayxInAppUpdateCanceledError(),
      _playxInAppUpdateFailedErrorCode => PlayxInAppUpdateFailedError(),
      _platformNotSupportedErrorCode => PlatformNotSupportedError(),
      defaultFailureErrorCode => DefaultFailureError(errorMsg: errorMessage),
      _ => DefaultFailureError(errorMsg: errorMessage)
    };
  }

  /// Factory constructor to create a [PlayxVersionUpdateError] from a
  /// network-related exception, typically from version checking.
  factory PlayxVersionUpdateError.fromNetworkException(
      network.NetworkException exception) {
    return switch (exception) {
      network.NotFoundException _ => const NotFoundError(),
      network.SendTimeoutException _ => const SendTimeoutException(),
      network.NoInternetConnectionException _ =>
      const NoInternetConnectionException(),
      network.InternalServerErrorException _ =>
      const InternalServerErrorException(),
      network.ServiceUnavailableException _ =>
      const ServiceUnavailableException(),
      network.RequestTimeoutException _ => const RequestTimeoutException(),
      network.ApiException() =>
          DefaultFailureError(errorMsg: exception.message),
      network.RequestCanceledException() => PlayxNetworkRequestCanceledError(),
      network.InvalidFormatException() =>
          DefaultFailureError(errorMsg: exception.message),
      network.UnexpectedErrorException() =>
          DefaultFailureError(errorMsg: exception.message),
    };
  }
}

/// Sealed class representing specific errors that can occur during the
/// installation phase of an in-app update on Android.
///
/// These errors directly correspond to the [PlayxInstallError] hierarchy
/// defined in the native (Kotlin) module.
sealed class PlayxInstallError extends PlayxVersionUpdateError {
  final String _code;
  final String _msg;

  /// Private constructor for [PlayxInstallError] subclasses.
  const PlayxInstallError._(this._code, this._msg);

  @override
  String get message => _msg;

  @override
  String get errorCode => _code;

  /// Factory constructor to create a [PlayxInstallError] instance from
  /// a Kotlin-provided error code and message.
  factory PlayxInstallError.fromKotlinErrorCode(String errorCode, String errorMessage) {
    switch (errorCode) {
      case _installApiNotAvailableErrorCode: return const InstallApiNotAvailableError();
      case _installAppNotOwnedErrorCode: return const InstallAppNotOwnedError();
      case _installDownloadNotPresentErrorCode: return const InstallDownloadNotPresentError();
      case _installInProgressErrorCode: return const InstallInProgressError();
      case _installNotAllowedErrorCode: return const InstallNotAllowedError();
      case _installUnavailableErrorCode: return const InstallUnavailableError();
      case _installInternalErrorCode: return const InstallInternalError();
      case _installInvalidRequestErrorCode: return const InstallInvalidRequestError();
      case _installPlayStoreNotFoundErrorCode: return const InstallPlayStoreNotFoundError();
      case _installUnknownErrorCode: return InstallUnknownError(errorCode: _installUnknownErrorCode, errorMessage: errorMessage);
      default:
        return InstallUnknownError(errorCode: errorCode, errorMessage: errorMessage);
    }
  }
}

/// The Play In-App Update API is not available on this device.
/// This might happen if the device doesn't support the feature or has an outdated Play Store.
class InstallApiNotAvailableError extends PlayxInstallError {
  const InstallApiNotAvailableError() : super._(_installApiNotAvailableErrorCode,
      "In-app updates are not supported on this device. Please ensure your Google Play Store is up to date.");
}

/// The app is not genuinely owned by any user on this device.
/// This typically occurs if the app was installed from an unofficial source (side-loaded APK).
class InstallAppNotOwnedError extends PlayxInstallError {
  const InstallAppNotOwnedError() : super._(_installAppNotOwnedErrorCode,
      "The app is not genuinely owned by a user on this device. In-app updates require the app to be installed from the Google Play Store.");
}

/// The in-app update has not been fully downloaded yet.
/// For flexible updates, ensure the download is complete before attempting to install.
class InstallDownloadNotPresentError extends PlayxInstallError {
  const InstallDownloadNotPresentError() : super._(_installDownloadNotPresentErrorCode,
      "The update download is not complete. Please wait for the download to finish before trying to install.");
}

/// An in-app update installation is already in progress.
/// Please wait for the current update to complete or restart the app.
class InstallInProgressError extends PlayxInstallError {
  const InstallInProgressError() : super._(_installInProgressErrorCode,
      "An update installation is already running. Please wait for it to finish or restart the app if it's stuck.");
}

/// The in-app update download or installation isn't allowed right now.
/// This could be due to issues like **low storage**, **low battery**, **device overheating**,
/// **network restrictions**, or **system security policies**.
///
/// **Important for Testing:** This error often occurs if the app wasn't
/// **installed directly from the Google Play Store** (e.g., you side-loaded an APK).
/// In-app updates only work for Play Store-installed apps.
/// Ensure your app came from a Play Store test track (like Internal Testing or Internal App Sharing).
class InstallNotAllowedError extends PlayxInstallError {
  const InstallNotAllowedError() : super._(_installNotAllowedErrorCode,
      "The update cannot be installed at this moment. This might be due to low device storage, "
          "low battery, device overheating, network restrictions, or system security policies. "
          "Additionally, if the app was installed via a side-loaded APK, the Play Store won't recognize it as eligible"
          " for in-app updates, leading to this error. Please ensure the app was installed directly from the Google Play Store.");
}

/// The in-app update is unavailable for this specific user or device.
/// This might happen for restricted profiles or secondary users.
class InstallUnavailableError extends PlayxInstallError {
  const InstallUnavailableError() : super._(_installUnavailableErrorCode,
      "The update is unavailable for this user profile or device configuration. Please try with a primary user account if applicable.");
}

/// An unexpected internal error occurred within the Google Play Store during installation.
/// Please try again later.
class InstallInternalError extends PlayxInstallError {
  const InstallInternalError() : super._(_installInternalErrorCode,
      "An unexpected error occurred within the Google Play Store during installation. Please try again later.");
}

/// The update request sent by the app is malformed or invalid.
/// This indicates an issue with how the app requested the update.
class InstallInvalidRequestError extends PlayxInstallError {
  const InstallInvalidRequestError() : super._(_installInvalidRequestErrorCode,
      "The update request was invalid. This may be an issue with the app. Please report this if it persists.");
}

/// The Google Play Store app is either not installed or is not the official version.
 class InstallPlayStoreNotFoundError extends PlayxInstallError {
  const InstallPlayStoreNotFoundError() : super._(_installPlayStoreNotFoundErrorCode,
      "The Google Play Store app is not found or is not the official version on this device. In-app updates cannot proceed without it.");
}


/// Represents an unhandled or unexpected InstallErrorCode from Kotlin.
/// This captures any future error codes or those not explicitly mapped.
class InstallUnknownError extends PlayxInstallError {
  const InstallUnknownError({required String errorCode, required String errorMessage})
      : super._(errorCode, errorMessage);
}


/// Error indicating the current platform (e.g., iOS, Web) does not support the requested operation.
class PlatformNotSupportedError extends PlayxVersionUpdateError {
  @override
  String get message => "This platform does not support in-app updates. Please check for updates through your device's app store.";

  @override
  String get errorCode => _platformNotSupportedErrorCode;
}

/// Error indicating the Android Activity required for the update is not available.
/// This typically happens if the app is in the background.
class ActivityNotFoundError extends PlayxVersionUpdateError {
  @override
  String get message =>
      "The app needs to be in the foreground to perform this action. Please bring the app to the front and try again.";

  @override
  String get errorCode => _activityNotFoundErrorCode;
}

/// Error indicating the Android App Update Manager service is not available on the device.
/// This can happen on devices without Google Play Services or an outdated Play Store.
class AppUpdateMangerNotFoundError extends PlayxVersionUpdateError {
  @override
  String get message => "The in-app update service is not available on this device. Ensure Google Play Services are up to date.";

  @override
  String get errorCode => _appUpdateMangerNotFoundErrorCode;
}

/// Error indicating the request to check for update availability was cancelled.
/// This might happen if the user navigated away quickly or the app closed.
class PlayxInAppUpdateInfoRequestCanceledError extends PlayxVersionUpdateError {
  @override
  String get message =>
      "The check for update availability was cancelled. Please try again.";

  @override
  String get errorCode => _playxInAppUpdateInfoRequestCanceledErrorCode;
}

/// Error indicating the in-app update process was explicitly cancelled by the user.
/// The user likely chose not to proceed with the update.
class PlayxInAppUpdateCanceledError extends PlayxVersionUpdateError {
  @override
  String get message => "The in-app update was cancelled by the user.";

  @override
  String get errorCode => _playxInAppUpdateCanceledErrorCode;
}

/// Error indicating an in-app update failed for a general, unspecified reason.
/// For more specific installation issues, check the `PlayxInstallError` types.
class PlayxInAppUpdateFailedError extends PlayxVersionUpdateError {
  @override
  String get message => "The in-app update process failed unexpectedly.";

  @override
  String get errorCode => _playxInAppUpdateFailedErrorCode;
}

/// A generic fallback error when a more specific error message is not available.
class DefaultFailureError extends PlayxVersionUpdateError {
  final String? errorMsg;

  const DefaultFailureError({this.errorMsg});

  @override
  String get errorCode => defaultFailureErrorCode;

  @override
  String get message => errorMsg ?? 'An unknown error occurred. Please try again.';
}

// Version Check errors (network related)

/// Error indicating the application could not be found on the store.
/// Ensure the app is correctly listed and available in the store.
class NotFoundError extends PlayxVersionUpdateError {
  const NotFoundError();

  @override
  String get message =>
      "The application could not be found on the store. Please verify the app's availability.";

  @override
  String get errorCode => 'NOT_FOUND_ERROR';
}

/// Error indicating the network request to get update information was cancelled.
/// This might occur if the user navigated away or connectivity was lost.
class PlayxNetworkRequestCanceledError extends PlayxVersionUpdateError {
  @override
  String get message =>
      "The request for update information was cancelled due to network issues or user action.";

  @override
  String get errorCode => 'PLAYX_NETWORK_REQUEST_CANCELLED_ERROR';
}

/// Error indicating a send timeout occurred during the network request.
/// This means the app took too long to send data.
class SendTimeoutException extends PlayxVersionUpdateError {
  const SendTimeoutException();

  @override
  String get message => 'Network request timed out while sending data. Please check your internet connection.';

  @override
  String get errorCode => 'SEND_TIMEOUT_ERROR';
}

/// Error indicating there is no active internet connection.
class NoInternetConnectionException extends PlayxVersionUpdateError {
  const NoInternetConnectionException();

  @override
  String get message => 'No internet connection. Please connect to the internet and try again.';

  @override
  String get errorCode => 'NO_INTERNET_CONNECTION_ERROR';
}

/// Error indicating an internal server error occurred during the version check request.
/// The server encountered an unexpected condition.
class InternalServerErrorException extends PlayxVersionUpdateError {
  const InternalServerErrorException();

  @override
  String get message => 'An internal server error occurred. Please try again later.';

  @override
  String get errorCode => 'INTERNAL_SERVER_ERROR';
}

/// Error indicating the service is temporarily unavailable.
/// This might be due to maintenance or high traffic.
class ServiceUnavailableException extends PlayxVersionUpdateError {
  const ServiceUnavailableException();

  @override
  String get message => 'The update service is temporarily unavailable. Please try again in a few moments.';

  @override
  String get errorCode => 'SERVICE_UNAVAILABLE_ERROR';
}

/// Error indicating the network request timed out.
/// This means the server did not respond in time.
class RequestTimeoutException extends PlayxVersionUpdateError {
  const RequestTimeoutException();

  @override
  String get message => 'The request to the server timed out. Please check your internet connection and try again.';

  @override
  String get errorCode => 'REQUEST_TIMEOUT_ERROR';
}

/// Error indicating the version check encountered an unsupported version.
class NotSupportedException extends PlayxVersionUpdateError {
  const NotSupportedException();

  @override
  String get message => 'The requested operation is not supported. Please ensure your app is up to date.';

  @override
  String get errorCode => 'NOT_SUPPORTED_ERROR_CODE';
}

/// Error indicating the app cannot be updated because the new version is not higher than the current one.
class PlayxVersionCantUpdateError extends PlayxVersionUpdateError {
  final String currentVersion;
  final String newVersion;

  const PlayxVersionCantUpdateError(
      {required this.currentVersion, required this.newVersion});

  @override
  String get message =>
      "Cannot update the app because the current version ($currentVersion) is already the same or newer than the available version ($newVersion).";

  @override
  String get errorCode => 'PLAYX_VERSION_CANT_UPDATE_ERROR_CODE';
}

/// Error indicating the version string was not formatted correctly.
class VersionFormatException extends PlayxVersionUpdateError {
  const VersionFormatException();

  @override
  String get message => "The version information received could not be understood. Please try again later.";

  @override
  String get errorCode => 'VERSION_FORMAT_ERROR';
}
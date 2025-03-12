import 'package:playx_network/playx_network.dart' as network;

const String _activityNotFoundErrorCode = 'ACTIVITY_NOT_FOUND';
const String _appUpdateMangerNotFoundErrorCode = 'APP_UPDATE_MANGER_NOT_FOUND';
const String _playxInAppUpdateInfoRequestCanceledErrorCode =
    'PLAYX_REQUEST_CANCELLED';
const String _playxInAppUpdateCanceledErrorCode = 'PLAYX_UPDATE_CANCELLED';

const String _playxUpdateNotAvailableErrorCode = 'PLAYX_UPDATE_NOT_AVAILABLE';
const String _playxUpdateNotAllowedErrorCode = 'PLAYX_UPDATE_NOT_ALLOWED';
const String _playxUnknownUpdateTypeError = 'PLAYX_UNKNOWN_UPDATE_TYPE';
const String _playxInAppUpdateFailedErrorCode = 'PLAYX_IN_APP_UPDATE_FAILED';
const String defaultFailureErrorCode = 'DEFAULT_FAILURE_ERROR';
const String _platformNotSupportedErrorCode = 'PLATFORM_NOT_SUPPORTED_ERROR';

sealed class PlayxVersionUpdateError {
  String get message;

  String get errorCode;

  const PlayxVersionUpdateError();

  factory PlayxVersionUpdateError.fromInAppUpdateErrorCode(
      String errorCode, String errorMessage) {
    return switch (errorCode) {
      _activityNotFoundErrorCode => ActivityNotFoundError(),
      _appUpdateMangerNotFoundErrorCode => AppUpdateMangerNotFoundError(),
      _playxInAppUpdateInfoRequestCanceledErrorCode =>
        PlayxInAppUpdateInfoRequestCanceledError(),
      _playxInAppUpdateCanceledErrorCode => PlayxInAppUpdateCanceledError(),
      _playxUpdateNotAvailableErrorCode => PlayxUpdateNotAvailableError(),
      _playxUpdateNotAllowedErrorCode => PlayxUpdateNotAllowedError(),
      _playxUnknownUpdateTypeError => PlayxUnknownUpdateTypeError(),
      _playxInAppUpdateFailedErrorCode => PlayxInAppUpdateFailedError(),
      defaultFailureErrorCode => DefaultFailureError(errorMsg: errorMessage),
      _platformNotSupportedErrorCode => PlatformNotSupportedError(),
      _ => DefaultFailureError(errorMsg: errorMessage)
    };
  }

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

/// Error happens when the current platform doesn't support the operation.
class PlatformNotSupportedError extends PlayxVersionUpdateError {
  @override
  String get message => "This Platform is not supported.";

  @override
  String get errorCode => _platformNotSupportedErrorCode;
}

/// Error happens when the current activity is not available like when the app is in the background.
class ActivityNotFoundError extends PlayxVersionUpdateError {
  @override
  String get message =>
      "Activity is not available. The app must be in Foreground.";

  @override
  String get errorCode => _activityNotFoundErrorCode;
}

/// Error happens when the App update manger is not available.
class AppUpdateMangerNotFoundError extends PlayxVersionUpdateError {
  @override
  String get message => "App update manger is not available.";

  @override
  String get errorCode => _appUpdateMangerNotFoundErrorCode;
}

/// Error happens when the request to check if update is available is canceled .
class PlayxInAppUpdateInfoRequestCanceledError extends PlayxVersionUpdateError {
  @override
  String get message =>
      "In app update info request was cancelled when checking update availability.";

  @override
  String get errorCode => _playxInAppUpdateInfoRequestCanceledErrorCode;
}

/// Error happens when the in app update was canceled .
class PlayxInAppUpdateCanceledError extends PlayxVersionUpdateError {
  @override
  String get message => "In app update was cancelled.";

  @override
  String get errorCode => _playxInAppUpdateCanceledErrorCode;
}

/// Error happens when in app update is not available .
class PlayxUpdateNotAvailableError extends PlayxVersionUpdateError {
  @override
  String get message => "In app update is not available.";

  @override
  String get errorCode => _playxUpdateNotAvailableErrorCode;
}

/// Error happens when in app update is not allowed .
class PlayxUpdateNotAllowedError extends PlayxVersionUpdateError {
  @override
  String get message => "Update is not allowed.";

  @override
  String get errorCode => _playxUpdateNotAllowedErrorCode;
}

/// Error happens when in passing an unknown update type.
class PlayxUnknownUpdateTypeError extends PlayxVersionUpdateError {
  @override
  String get message => "Unknown update type.";

  @override
  String get errorCode => _playxUnknownUpdateTypeError;
}

/// Error happens when in app update was failed due to other error .
class PlayxInAppUpdateFailedError extends PlayxVersionUpdateError {
  @override
  String get message => "In app update failed.";

  @override
  String get errorCode => _playxInAppUpdateFailedErrorCode;
}

/// Default failure error.
class DefaultFailureError extends PlayxVersionUpdateError {
  final String? errorMsg;

  const DefaultFailureError({this.errorMsg});

  @override
  String get errorCode => defaultFailureErrorCode;

  @override
  String get message => errorMsg ?? 'unknown error';
}

//Version Check errors

/// Error happens when the package can't find the application on the store.
class NotFoundError extends PlayxVersionUpdateError {
  const NotFoundError();

  @override
  String get message =>
      "couldn't find the application. Make sure the app is available on the store.";

  @override
  String get errorCode => 'NOT_FOUND_ERROR';
}

/// Error happens when the version check network request was canceled.
class PlayxNetworkRequestCanceledError extends PlayxVersionUpdateError {
  @override
  String get message =>
      "Getting update info request from network was cancelled.";

  @override
  String get errorCode => 'PLAYX_NETWORK_REQUEST_CANCELLED_ERROR';
}

/// Error happens when the version check network request had timeout.
class SendTimeoutException extends PlayxVersionUpdateError {
  const SendTimeoutException();

  @override
  String get message => 'send timeout';

  @override
  String get errorCode => 'SEND_TIMEOUT_ERROR';
}

/// Error happens when there's no internet connection.
class NoInternetConnectionException extends PlayxVersionUpdateError {
  const NoInternetConnectionException();

  @override
  String get message => 'No Internet Connection';

  @override
  String get errorCode => 'NO_INTERNET_CONNECTION_ERROR';
}

/// Error happens when the version check network request received internal server error.
class InternalServerErrorException extends PlayxVersionUpdateError {
  const InternalServerErrorException();

  @override
  String get message => 'Internal Server Error';

  @override
  String get errorCode => 'INTERNAL_SERVER_ERROR';
}

/// Error happens when the version check network request received unavailable service error.
class ServiceUnavailableException extends PlayxVersionUpdateError {
  const ServiceUnavailableException();

  @override
  String get message => 'Service unavailable';

  @override
  String get errorCode => 'SERVICE_UNAVAILABLE_ERROR';
}

/// Error happens when the version check network request received request timeout error.
class RequestTimeoutException extends PlayxVersionUpdateError {
  const RequestTimeoutException();

  @override
  String get message => 'Request timeout';

  @override
  String get errorCode => 'REQUEST_TIMEOUT_ERROR';
}

/// Error happens when the version check has unsupported version.
class NotSupportedException extends PlayxVersionUpdateError {
  const NotSupportedException();

  @override
  String get message => 'not supported';

  @override
  String get errorCode => 'NOT_SUPPORTED_ERROR_CODE';
}

/// Error happens when the version check the app can't update because new version is below or the same as current one.
class PlayxVersionCantUpdateError extends PlayxVersionUpdateError {
  final String currentVersion;
  final String newVersion;

  const PlayxVersionCantUpdateError(
      {required this.currentVersion, required this.newVersion});

  @override
  String get message =>
      "Can't update version as the current version is $currentVersion and the new version is $newVersion";

  @override
  String get errorCode => 'PLAYX_VERSION_CANT_UPDATE_ERROR_CODE';
}

/// Error happens when the version was not formatted correctly.
class VersionFormatException extends PlayxVersionUpdateError {
  const VersionFormatException();

  @override
  String get message => "couldn't format version";

  @override
  String get errorCode => 'VERSION_FORMAT_ERROR';
}

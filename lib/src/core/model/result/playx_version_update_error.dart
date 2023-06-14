const String _activityNotFoundErrorCode = 'ACTIVITY_NOT_FOUND';
const String _appUpdateMangerNotFoundErrorCode = 'APP_UPDATE_MANGER_NOT_FOUND';
const String _playxRequestCanceledErrorCode = 'PLAYX_REQUEST_CANCELLED';
const String _playxUpdateNotAvailableErrorCode = 'PLAYX_UPDATE_NOT_AVAILABLE';
const String _playxUpdateNotAllowedErrorCode = 'PLAYX_UPDATE_NOT_ALLOWED';
const String _playxUnknownUpdateTypeError = 'PLAYX_UNKNOWN_UPDATE_TYPE';
const String _playxInAppUpdateFailedErrorCode = 'PLAYX_IN_APP_UPDATE_FAILED';
const String defaultFailureErrorCode = 'DEFAULT_FAILURE_ERROR';

sealed class PlayxVersionUpdateError {
  String get message;

  String get errorCode;

  const PlayxVersionUpdateError();

  factory PlayxVersionUpdateError.fromInAppUpdateErrorCode(
      String errorCode, String errorMessage) {
    return switch (errorCode) {
      _activityNotFoundErrorCode => ActivityNotFoundError(),
      _appUpdateMangerNotFoundErrorCode => AppUpdateMangerNotFoundError(),
      _playxRequestCanceledErrorCode => PlayxRequestCanceledError(),
      _playxUpdateNotAvailableErrorCode => PlayxUpdateNotAvailableError(),
      _playxUpdateNotAllowedErrorCode => PlayxUpdateNotAllowedError(),
      _playxUnknownUpdateTypeError => PlayxUnknownUpdateTypeError(),
      _playxInAppUpdateFailedErrorCode => PlayxInAppUpdateFailedError(),
      defaultFailureErrorCode => DefaultFailureError(errorMsg: errorMessage),
      _ => DefaultFailureError(errorMsg: errorMessage)
    };
  }
}

class ActivityNotFoundError extends PlayxVersionUpdateError {
  @override
  String get message =>
      "Activity is not available. The app must be in Foreground.";

  @override
  String get errorCode => _activityNotFoundErrorCode;
}

class AppUpdateMangerNotFoundError extends PlayxVersionUpdateError {
  @override
  String get message => "App update manger is not available.";

  @override
  String get errorCode => _appUpdateMangerNotFoundErrorCode;
}

class PlayxRequestCanceledError extends PlayxVersionUpdateError {
  @override
  String get message => "Getting update info request was cancelled.";

  @override
  String get errorCode => _playxRequestCanceledErrorCode;
}

class PlayxUpdateNotAvailableError extends PlayxVersionUpdateError {
  @override
  String get message => "Update is not available.";

  @override
  String get errorCode => _playxUpdateNotAvailableErrorCode;
}

class PlayxUpdateNotAllowedError extends PlayxVersionUpdateError {
  @override
  String get message => "Update is not allowed.";

  @override
  String get errorCode => _playxUpdateNotAllowedErrorCode;
}

class PlayxUnknownUpdateTypeError extends PlayxVersionUpdateError {
  @override
  String get message => "Unknown update type.";

  @override
  String get errorCode => _playxUnknownUpdateTypeError;
}

class PlayxInAppUpdateFailedError extends PlayxVersionUpdateError {
  @override
  String get message => "In app update failed.";

  @override
  String get errorCode => _playxInAppUpdateFailedErrorCode;
}

class DefaultFailureError extends PlayxVersionUpdateError {
  final String? errorMsg;

  const DefaultFailureError({this.errorMsg});

  @override
  String get errorCode => defaultFailureErrorCode;

  @override
  String get message => errorMsg ?? 'unknown error';
}

//Version Check errors
class NotFoundError extends PlayxVersionUpdateError {
  const NotFoundError();

  @override
  String get message => "couldn't find the application";

  @override
  String get errorCode => 'NOT_FOUND_ERROR';
}

class SendTimeoutException extends PlayxVersionUpdateError {
  const SendTimeoutException();

  @override
  String get message => 'send timeout';

  @override
  String get errorCode => 'SEND_TIMEOUT_ERROR';
}

class NoInternetConnectionException extends PlayxVersionUpdateError {
  const NoInternetConnectionException();

  @override
  String get message => 'No Internet Connection';

  @override
  String get errorCode => 'NO_INTERNET_CONNECTION_ERROR';
}

class InternalServerErrorException extends PlayxVersionUpdateError {
  const InternalServerErrorException();

  @override
  String get message => 'Internal Server Error';

  @override
  String get errorCode => 'INTERNAL_SERVER_ERROR';
}

class ServiceUnavailableException extends PlayxVersionUpdateError {
  const ServiceUnavailableException();

  @override
  String get message => 'Service unavailable';

  @override
  String get errorCode => 'SERVICE_UNAVAILABLE_ERROR';
}

class RequestTimeoutException extends PlayxVersionUpdateError {
  const RequestTimeoutException();

  @override
  String get message => 'Request timeout';

  @override
  String get errorCode => 'REQUEST_TIMEOUT_ERROR';
}

class NotSupportedException extends PlayxVersionUpdateError {
  const NotSupportedException();

  @override
  String get message => 'not supported';

  @override
  String get errorCode => 'NOT_SUPPORTED_ERROR_CODE';
}

class VersionFormatException extends PlayxVersionUpdateError {
  const VersionFormatException();

  @override
  String get message => "couldn't format version";

  @override
  String get errorCode => 'VERSION_FORMAT_ERROR';
}

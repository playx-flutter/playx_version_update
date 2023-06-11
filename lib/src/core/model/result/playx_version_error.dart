sealed class PlayxVersionError {
  String get message;

  const PlayxVersionError();
}

class NotFoundError extends PlayxVersionError {
  const NotFoundError();

  @override
  String get message => "couldn't find the application";
}

class UnknownError extends PlayxVersionError {
  const UnknownError();

  @override
  String get message => 'unknown error';
}

class SendTimeoutException extends PlayxVersionError {
  const SendTimeoutException();

  @override
  String get message => 'send timeout';
}

class RequestCanceledException extends PlayxVersionError {
  const RequestCanceledException();

  @override
  String get message => 'The request was canceled';
}

class NoInternetConnectionException extends PlayxVersionError {
  const NoInternetConnectionException();

  @override
  String get message => 'No Internet Connection';
}

class InternalServerErrorException extends PlayxVersionError {
  const InternalServerErrorException();

  @override
  String get message => 'Internal Server Error';
}

class ServiceUnavailableException extends PlayxVersionError {
  const ServiceUnavailableException();

  @override
  String get message => 'Service unavailable';
}

class RequestTimeoutException extends PlayxVersionError {
  const RequestTimeoutException();

  @override
  String get message => 'Request timeout';
}

class NotSupportedException extends PlayxVersionError {
  const NotSupportedException();

  @override
  String get message => 'not supported';
}

class VersionFormatException extends PlayxVersionError {
  const VersionFormatException();

  @override
  String get message => "couldn't format version";
}

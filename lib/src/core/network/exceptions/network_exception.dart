import 'network_error_code.dart';
import 'network_messages.dart';

/// Base class for network errors that can occur while fetching version
/// information from the App Store or Google Play.
sealed class NetworkException implements Exception {
  /// General, user-facing error message.
  final String errorMessage;

  /// Stable code identifying this error, see [NetworkErrorCode].
  final String errorCode;

  /// The underlying error (for example a `DioException`) that caused this
  /// exception, if any. Useful for logging and debugging.
  final Object? cause;

  const NetworkException({
    required this.errorMessage,
    required this.errorCode,
    this.cause,
  });

  /// The message describing the error.
  String get message => errorMessage;

  /// Whether retrying the same request later may succeed
  /// (timeouts, connectivity problems, throttling, temporary server errors).
  bool get isRetryable => false;

  @override
  String toString() => '$runtimeType($errorCode): $message';
}

/// Exception for HTTP responses with an error status code.
class ApiException extends NetworkException {
  /// HTTP status code, or `-1` if it is unknown.
  final int statusCode;

  const ApiException({
    this.statusCode = 400,
    super.errorMessage = NetworkMessages.defaultError,
    super.errorCode = NetworkErrorCode.defaultApiError,
    super.cause,
  });

  /// Creates the [ApiException] matching the given HTTP [statusCode].
  factory ApiException.fromStatusCode(int statusCode, {Object? cause}) {
    switch (statusCode) {
      case 400:
        return BadRequestException(cause: cause);
      case 401:
      case 403:
        return UnauthorizedRequestException(
            statusCode: statusCode, cause: cause);
      case 404:
        return NotFoundException(cause: cause);
      case 408:
        return RequestTimeoutException(cause: cause);
      case 409:
        return ConflictException(cause: cause);
      case 422:
        return UnableToProcessException(cause: cause);
      case 429:
        return TooManyRequestsException(cause: cause);
      case 500:
        return InternalServerErrorException(cause: cause);
      case 502:
      case 503:
      case 504:
        return ServiceUnavailableException(
            statusCode: statusCode, cause: cause);
      default:
        return DefaultApiException(statusCode: statusCode, cause: cause);
    }
  }

  @override
  String toString() =>
      '$runtimeType($errorCode, status: $statusCode): $message';
}

/// Exception for bad requests (400).
class BadRequestException extends ApiException {
  const BadRequestException({super.cause})
      : super(
            statusCode: 400,
            errorMessage: NetworkMessages.badRequest,
            errorCode: NetworkErrorCode.badRequest);
}

/// Exception for unauthorized requests (401, 403).
class UnauthorizedRequestException extends ApiException {
  const UnauthorizedRequestException({super.statusCode = 401, super.cause})
      : super(
            errorMessage: NetworkMessages.unauthorized,
            errorCode: NetworkErrorCode.unauthorized);
}

/// Exception for "Not Found" errors (404).
class NotFoundException extends ApiException {
  const NotFoundException({super.cause})
      : super(
            statusCode: 404,
            errorMessage: NetworkMessages.notFound,
            errorCode: NetworkErrorCode.notFound);
}

/// Exception for an app that does not exist on the store.
///
/// Thrown when Google Play answers 404, or when the App Store lookup returns
/// no results for the bundle id.
class AppNotFoundException extends ApiException {
  const AppNotFoundException({super.cause})
      : super(
            statusCode: 404,
            errorMessage: NetworkMessages.appNotFound,
            errorCode: NetworkErrorCode.appNotFound);
}

/// Google Play showed its cookie-consent page instead of the app page.
///
/// This happens for users in regions such as the EU/UK, where the store page
/// cannot be read without accepting the consent form. Retrying will not help;
/// provide `PlayxUpdateOptions.newVersion` from your own backend, or send the
/// user to the store page.
class ConsentRequiredException extends NetworkException {
  const ConsentRequiredException({super.cause})
      : super(
            errorMessage: NetworkMessages.consentRequired,
            errorCode: NetworkErrorCode.consentRequired);
}

/// Exception for conflicts (409).
class ConflictException extends ApiException {
  const ConflictException({super.cause})
      : super(
            statusCode: 409,
            errorMessage: NetworkMessages.conflict,
            errorCode: NetworkErrorCode.conflict);
}

/// Exception for request timeouts (408, or a connection/receive timeout).
class RequestTimeoutException extends ApiException {
  const RequestTimeoutException({super.statusCode = 408, super.cause})
      : super(
            errorMessage: NetworkMessages.requestTimeout,
            errorCode: NetworkErrorCode.requestTimeout);

  @override
  bool get isRetryable => true;
}

/// Exception for unprocessable entity (422).
class UnableToProcessException extends ApiException {
  const UnableToProcessException({super.cause})
      : super(
            statusCode: 422,
            errorMessage: NetworkMessages.unableToProcess,
            errorCode: NetworkErrorCode.unableToProcess);
}

/// Exception for rate limiting (429).
class TooManyRequestsException extends ApiException {
  const TooManyRequestsException({super.cause})
      : super(
            statusCode: 429,
            errorMessage: NetworkMessages.tooManyRequests,
            errorCode: NetworkErrorCode.tooManyRequests);

  @override
  bool get isRetryable => true;
}

/// Exception for internal server errors (500).
class InternalServerErrorException extends ApiException {
  const InternalServerErrorException({super.cause})
      : super(
            statusCode: 500,
            errorMessage: NetworkMessages.internalServerError,
            errorCode: NetworkErrorCode.internalServerError);
}

/// Exception for service unavailable (502, 503, 504).
class ServiceUnavailableException extends ApiException {
  const ServiceUnavailableException({super.statusCode = 503, super.cause})
      : super(
            errorMessage: NetworkMessages.serviceUnavailable,
            errorCode: NetworkErrorCode.serviceUnavailable);

  @override
  bool get isRetryable => true;
}

/// Exception for empty responses.
class EmptyResponseException extends ApiException {
  const EmptyResponseException({super.cause})
      : super(
            statusCode: 204,
            errorMessage: NetworkMessages.emptyResponse,
            errorCode: NetworkErrorCode.emptyResponse);
}

/// Default API exception (for unhandled status codes).
class DefaultApiException extends ApiException {
  const DefaultApiException({super.statusCode = 400, super.cause})
      : super(
            errorMessage: NetworkMessages.defaultError,
            errorCode: NetworkErrorCode.defaultApiError);
}

/// Exception for request send timeout.
class SendTimeoutException extends NetworkException {
  const SendTimeoutException({super.cause})
      : super(
            errorMessage: NetworkMessages.sendTimeout,
            errorCode: NetworkErrorCode.sendTimeout);

  @override
  bool get isRetryable => true;
}

/// Exception for request cancellation.
class RequestCanceledException extends NetworkException {
  const RequestCanceledException({super.cause})
      : super(
            errorMessage: NetworkMessages.requestCanceled,
            errorCode: NetworkErrorCode.requestCanceled);
}

/// Exception for no internet connection.
class NoInternetConnectionException extends NetworkException {
  const NoInternetConnectionException({super.cause})
      : super(
            errorMessage: NetworkMessages.noInternetConnection,
            errorCode: NetworkErrorCode.noInternetConnection);

  @override
  bool get isRetryable => true;
}

/// Exception for invalid response format.
class InvalidFormatException extends NetworkException {
  const InvalidFormatException({super.cause})
      : super(
            errorMessage: NetworkMessages.invalidFormat,
            errorCode: NetworkErrorCode.invalidFormat);
}

/// Exception for TLS/certificate failures.
class BadCertificateException extends NetworkException {
  const BadCertificateException({super.cause})
      : super(
            errorMessage: NetworkMessages.badCertificate,
            errorCode: NetworkErrorCode.badCertificate);
}

/// Exception for unexpected errors.
class UnexpectedErrorException extends NetworkException {
  const UnexpectedErrorException({super.cause})
      : super(
            errorMessage: NetworkMessages.unexpected,
            errorCode: NetworkErrorCode.unexpected);
}

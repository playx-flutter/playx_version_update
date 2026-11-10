/// Stable string codes identifying every [NetworkException] type.
///
/// Use them to branch on failures without depending on message text:
///
/// ```dart
/// if (error is PlayxVersionNetworkError &&
///     error.error.errorCode == NetworkErrorCode.noInternetConnection) {
///   // show an offline banner
/// }
/// ```
abstract final class NetworkErrorCode {
  static const String badRequest = 'NETWORK_BAD_REQUEST';
  static const String unauthorized = 'NETWORK_UNAUTHORIZED';
  static const String notFound = 'NETWORK_NOT_FOUND';

  /// The store answered, but has no app for the given package / bundle id.
  static const String appNotFound = 'STORE_APP_NOT_FOUND';
  static const String requestTimeout = 'NETWORK_REQUEST_TIMEOUT';
  static const String conflict = 'NETWORK_CONFLICT';
  static const String unableToProcess = 'NETWORK_UNABLE_TO_PROCESS';
  static const String tooManyRequests = 'NETWORK_TOO_MANY_REQUESTS';
  static const String internalServerError = 'NETWORK_INTERNAL_SERVER_ERROR';
  static const String serviceUnavailable = 'NETWORK_SERVICE_UNAVAILABLE';
  static const String emptyResponse = 'NETWORK_EMPTY_RESPONSE';
  static const String defaultApiError = 'NETWORK_API_ERROR';
  static const String sendTimeout = 'NETWORK_SEND_TIMEOUT';
  static const String requestCanceled = 'NETWORK_REQUEST_CANCELED';
  static const String noInternetConnection = 'NETWORK_NO_INTERNET_CONNECTION';
  static const String invalidFormat = 'NETWORK_INVALID_FORMAT';
  static const String badCertificate = 'NETWORK_BAD_CERTIFICATE';
  static const String unexpected = 'NETWORK_UNEXPECTED_ERROR';
}

import 'dart:io';

import 'package:dio/dio.dart';

import 'exceptions/network_exception.dart';

/// Converts any error thrown while performing a request into a
/// [NetworkException], so callers never have to deal with `DioException`.
abstract final class NetworkExceptionMapper {
  static NetworkException map(Object error) {
    if (error is NetworkException) return error;
    if (error is DioException) return _fromDio(error);
    return _fromGeneric(error);
  }

  static NetworkException _fromDio(DioException e) {
    return switch (e.type) {
      DioExceptionType.cancel => RequestCanceledException(cause: e),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        RequestTimeoutException(statusCode: -1, cause: e),
      DioExceptionType.sendTimeout => SendTimeoutException(cause: e),
      DioExceptionType.connectionError =>
        NoInternetConnectionException(cause: e),
      DioExceptionType.badCertificate => BadCertificateException(cause: e),
      DioExceptionType.badResponse =>
        ApiException.fromStatusCode(e.response?.statusCode ?? -1, cause: e),
      DioExceptionType.unknown => _fromGeneric(e.error ?? e, fallback: e),
    };
  }

  static NetworkException _fromGeneric(Object error, {Object? fallback}) {
    final cause = fallback ?? error;
    return switch (error) {
      SocketException() => NoInternetConnectionException(cause: cause),
      HandshakeException() ||
      TlsException() =>
        BadCertificateException(cause: cause),
      FormatException() => InvalidFormatException(cause: cause),
      _ => UnexpectedErrorException(cause: cause),
    };
  }
}

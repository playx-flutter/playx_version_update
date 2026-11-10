import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'exceptions/network_exception.dart';
import 'network_exception_mapper.dart';
import 'network_log_interceptor.dart';

/// A minimal [Dio] based client used to fetch store information.
///
/// Every failure is reported by throwing a [NetworkException]. Failures that
/// are [NetworkException.isRetryable] are retried up to [maxRetries] times.
class NetworkClient {
  final Dio _dio;

  /// How many times a retryable failure is retried.
  final int maxRetries;

  /// Base delay between retries; grows linearly with each attempt.
  final Duration retryDelay;

  NetworkClient({
    Dio? dio,
    this.maxRetries = 1,
    this.retryDelay = const Duration(seconds: 1),
    NetworkLogInterceptor? logInterceptor,
  }) : _dio = (dio ?? _createDefaultDio())
          ..interceptors.add(logInterceptor ?? NetworkLogInterceptor());

  static Dio _createDefaultDio() => Dio(
        BaseOptions(
          followRedirects: true,
          connectTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          // The stores return HTML (Google Play) or JSON text (App Store),
          // both are parsed from the raw string.
          responseType: ResponseType.plain,
        ),
      );

  /// Performs a GET request and returns the response body as a string.
  ///
  /// Throws a [NetworkException] if the request fails or the body is empty.
  Future<String> get(
    String url, {
    Map<String, String>? headers,
    bool enableLog = false,
  }) async {
    for (var attempt = 0;; attempt++) {
      try {
        return await _send(url, headers, enableLog);
      } on NetworkException catch (e) {
        if (!e.isRetryable || attempt >= maxRetries) rethrow;
        _log(enableLog,
            '↻ Retrying (${attempt + 1}/$maxRetries) in ${(retryDelay * (attempt + 1)).inMilliseconds}ms after: $e');
        await Future<void>.delayed(retryDelay * (attempt + 1));
      }
    }
  }

  Future<String> _send(
      String url, Map<String, String>? headers, bool enableLog) async {
    try {
      final response = await _dio.get<String>(url,
          options: NetworkLogInterceptor.logOptions(
              enabled: enableLog, headers: headers));

      final body = response.data;
      if (body == null || body.isEmpty) {
        throw const EmptyResponseException();
      }
      return body;
    } catch (e) {
      final exception = NetworkExceptionMapper.map(e);
      _log(enableLog, '✖ mapped to $exception');
      throw exception;
    }
  }

  void _log(bool enabled, String message) {
    if (enabled) debugPrint('[PlayxVersionUpdate] $message');
  }
}

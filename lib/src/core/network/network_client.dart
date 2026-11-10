import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:playx_version_update/src/core/model/options/playx_network_options.dart';

import 'exceptions/network_exception.dart';
import 'network_exception_mapper.dart';
import 'network_log_interceptor.dart';
import 'network_response.dart';

/// A minimal [Dio] based client used to fetch store information.
///
/// Every failure is reported by throwing a [NetworkException]. Failures that
/// are [NetworkException.isRetryable] are retried up to
/// [PlayxNetworkOptions.maxRetries] times.
class NetworkClient {
  final Dio _dio;

  /// Retry settings used when a request does not pass [PlayxNetworkOptions].
  final int maxRetries;
  final Duration retryDelay;

  NetworkClient({
    Dio? dio,
    this.maxRetries = 1,
    this.retryDelay = const Duration(seconds: 1),
    NetworkLogInterceptor? logInterceptor,
  }) : _dio = _prepare(dio ?? _createDefaultDio(), logInterceptor);

  static Dio _prepare(Dio dio, NetworkLogInterceptor? interceptor) {
    // A Dio instance can be shared (or supplied by the app): attach the
    // logger only once.
    if (interceptor != null ||
        !dio.interceptors.any((i) => i is NetworkLogInterceptor)) {
      dio.interceptors.add(interceptor ?? NetworkLogInterceptor());
    }
    return dio;
  }

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

  /// Performs a GET request.
  ///
  /// [headers] are merged with [PlayxNetworkOptions.headers], which win.
  /// Throws a [NetworkException] if the request fails or the body is empty.
  Future<NetworkResponse> get(
    String url, {
    Map<String, String>? headers,
    bool enableLog = false,
    PlayxNetworkOptions? options,
  }) async {
    final retries = options?.maxRetries ?? maxRetries;
    final delay = options?.retryDelay ?? retryDelay;
    final mergedHeaders = {...?headers, ...?options?.headers};

    for (var attempt = 0;; attempt++) {
      try {
        return await _send(url, mergedHeaders, enableLog, options);
      } on NetworkException catch (e) {
        if (!e.isRetryable || attempt >= retries) rethrow;
        _log(
          enableLog,
          '↻ Retrying (${attempt + 1}/$retries) in ${(delay * (attempt + 1)).inMilliseconds}ms after: $e',
        );
        await Future<void>.delayed(delay * (attempt + 1));
      }
    }
  }

  Future<NetworkResponse> _send(
    String url,
    Map<String, String> headers,
    bool enableLog,
    PlayxNetworkOptions? options,
  ) async {
    try {
      final requestOptions =
          NetworkLogInterceptor.logOptions(enabled: enableLog, headers: headers)
              .copyWith(
                method: 'GET',
                sendTimeout: options?.sendTimeout,
                receiveTimeout: options?.receiveTimeout,
              )
              .compose(_dio.options, url, cancelToken: options?.cancelToken);
      // `Options` has no connect timeout, it is a request-level setting.
      if (options?.connectTimeout != null) {
        requestOptions.connectTimeout = options!.connectTimeout;
      }

      final response = await _dio.fetch<String>(requestOptions);

      final body = response.data;
      if (body == null || body.isEmpty) {
        throw const EmptyResponseException();
      }
      return NetworkResponse(
        body: body,
        statusCode: response.statusCode,
        finalUri: response.realUri,
      );
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

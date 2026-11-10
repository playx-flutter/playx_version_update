import 'package:dio/dio.dart';

/// Settings for the network requests made while checking the store version.
///
/// All values are optional; the defaults are suitable for most apps.
///
/// ```dart
/// PlayxUpdateOptions(
///   networkOptions: PlayxNetworkOptions(
///     maxRetries: 2,
///     connectTimeout: Duration(seconds: 10),
///     headers: {'X-App': 'my-app'},
///   ),
/// )
/// ```
class PlayxNetworkOptions {
  /// How many times a retryable failure (timeouts, no connection, throttling,
  /// temporary server errors) is retried. Use `0` to disable retries.
  /// Defaults to `1`.
  final int maxRetries;

  /// Base delay between retries; it grows linearly with every attempt.
  /// Defaults to one second.
  final Duration retryDelay;

  /// Maximum time to establish the connection. Defaults to 30 seconds.
  final Duration? connectTimeout;

  /// Maximum time to send the request. Defaults to 20 seconds.
  final Duration? sendTimeout;

  /// Maximum time to receive the response. Defaults to 30 seconds.
  final Duration? receiveTimeout;

  /// Extra headers sent with the request. They override the package defaults
  /// (for example `User-Agent` or `Accept-Language` for Google Play).
  final Map<String, String>? headers;

  /// A custom [Dio] instance, for example one configured with a proxy,
  /// certificate pinning or your own interceptors.
  ///
  /// The package only adds its own logging interceptor to it. When provided,
  /// the timeouts of that instance are used unless [connectTimeout],
  /// [sendTimeout] or [receiveTimeout] are set here.
  final Dio? dio;

  /// Lets you cancel the version check. A cancelled check fails with a
  /// `RequestCanceledException`.
  final CancelToken? cancelToken;

  const PlayxNetworkOptions({
    this.maxRetries = 1,
    this.retryDelay = const Duration(seconds: 1),
    this.connectTimeout,
    this.sendTimeout,
    this.receiveTimeout,
    this.headers,
    this.dio,
    this.cancelToken,
  });
}

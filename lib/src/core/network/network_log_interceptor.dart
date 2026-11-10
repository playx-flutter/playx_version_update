import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs requests, responses and errors of the [Dio] instance it is attached to.
///
/// Logging is switched on per request with [NetworkLogInterceptor.logOptions],
/// so the shared client stays silent unless the caller enabled
/// `enableNetworkLogging`.
class NetworkLogInterceptor extends Interceptor {
  static const _enabledKey = 'playx_log_enabled';
  static const _startKey = 'playx_log_start';
  static const _tag = '[PlayxVersionUpdate]';

  /// A header whose name contains one of these is never printed: standard
  /// credentials and the usual names of custom API keys and tokens.
  static const _sensitiveNameParts = [
    'auth',
    'cookie',
    'token',
    'secret',
    'password',
    'key',
  ];

  static bool _isSensitive(String name) {
    final lower = name.toLowerCase();
    return _sensitiveNameParts.any(lower.contains);
  }

  /// Maximum number of response body characters printed.
  final int maxBodyLength;

  /// Where log lines are written. Defaults to [debugPrint].
  final void Function(String message) printer;

  NetworkLogInterceptor({
    this.maxBodyLength = 500,
    void Function(String message)? printer,
  }) : printer = printer ?? ((m) => debugPrint(m));

  /// Request [Options] that enable or disable logging for a single request.
  static Options logOptions(
          {required bool enabled, Map<String, String>? headers}) =>
      Options(headers: headers, extra: {_enabledKey: enabled});

  bool _isEnabled(RequestOptions o) => o.extra[_enabledKey] == true;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isEnabled(options)) {
      options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
      printer([
        '$_tag ──▶ ${options.method} ${options.uri}',
        '  headers: ${_headers(options.headers)}',
        if (options.queryParameters.isNotEmpty)
          '  query: ${options.queryParameters}',
        '  timeouts: connect=${options.connectTimeout?.inSeconds}s '
            'receive=${options.receiveTimeout?.inSeconds}s',
      ].join('\n'));
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    if (_isEnabled(o)) {
      final body = response.data?.toString() ?? '';
      printer([
        '$_tag ◀── ${response.statusCode} ${response.statusMessage ?? ''} '
            '${o.method} ${o.uri} (${_elapsed(o)})',
        '  headers: ${_headers(response.headers.map)}',
        if (response.isRedirect) '  redirected: ${response.realUri}',
        '  body: ${body.length} chars'
            '${body.isEmpty ? '' : ' • ${_preview(body)}'}',
      ].join('\n'));
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    if (_isEnabled(o)) {
      final response = err.response;
      printer([
        '$_tag ✖ ${o.method} ${o.uri} (${_elapsed(o)})',
        '  type: ${err.type.name}',
        if (response != null) '  status: ${response.statusCode}',
        if (err.error != null) '  error: ${err.error}',
        if (err.message != null) '  message: ${err.message}',
        if (response?.data != null)
          '  body: ${_preview(response!.data.toString())}',
      ].join('\n'));
    }
    handler.next(err);
  }

  String _elapsed(RequestOptions o) {
    final start = o.extra[_startKey];
    if (start is! int) return '?';
    return '${DateTime.now().millisecondsSinceEpoch - start}ms';
  }

  String _preview(String body) {
    final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= maxBodyLength
        ? flat
        : '${flat.substring(0, maxBodyLength)}…';
  }

  Map<String, Object?> _headers(Map<String, dynamic> headers) => {
        for (final e in headers.entries)
          e.key:
              _isSensitive(e.key) ? '***' : e.value,
      };
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/network/network_client.dart';
import 'package:playx_version_update/src/core/network/network_exception_mapper.dart';
import 'package:playx_version_update/src/core/network/network_log_interceptor.dart';

class _FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function() handler;
  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<List<int>>? requestStream, Future<void>? cancelFuture) =>
      handler();

  @override
  void close({bool force = false}) {}
}

NetworkClient _client(Future<ResponseBody> Function() handler) {
  final dio = Dio(BaseOptions(responseType: ResponseType.plain))
    ..httpClientAdapter = _FakeAdapter(handler);
  return NetworkClient(dio: dio);
}

DioException _dio(DioExceptionType type, {int? status, Object? error}) =>
    DioException(
      requestOptions: RequestOptions(path: '/'),
      type: type,
      error: error,
      response: status == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: '/'), statusCode: status),
    );

void main() {
  loggingTests();
  group('NetworkExceptionMapper', () {
    test('maps dio exception types', () {
      final cases = <DioException, Type>{
        _dio(DioExceptionType.cancel): RequestCanceledException,
        _dio(DioExceptionType.connectionTimeout): RequestTimeoutException,
        _dio(DioExceptionType.receiveTimeout): RequestTimeoutException,
        _dio(DioExceptionType.sendTimeout): SendTimeoutException,
        _dio(DioExceptionType.connectionError): NoInternetConnectionException,
        _dio(DioExceptionType.badCertificate): BadCertificateException,
        _dio(DioExceptionType.unknown, error: const SocketException('x')):
            NoInternetConnectionException,
        _dio(DioExceptionType.unknown, error: const FormatException('x')):
            InvalidFormatException,
        _dio(DioExceptionType.unknown, error: StateError('x')):
            UnexpectedErrorException,
      };
      cases.forEach((e, type) {
        expect(NetworkExceptionMapper.map(e).runtimeType, type,
            reason: e.type.name);
      });
    });

    test('maps status codes with codes and cause', () {
      final expected = {
        400: NetworkErrorCode.badRequest,
        401: NetworkErrorCode.unauthorized,
        403: NetworkErrorCode.unauthorized,
        404: NetworkErrorCode.notFound,
        408: NetworkErrorCode.requestTimeout,
        409: NetworkErrorCode.conflict,
        422: NetworkErrorCode.unableToProcess,
        429: NetworkErrorCode.tooManyRequests,
        500: NetworkErrorCode.internalServerError,
        502: NetworkErrorCode.serviceUnavailable,
        503: NetworkErrorCode.serviceUnavailable,
        504: NetworkErrorCode.serviceUnavailable,
        418: NetworkErrorCode.defaultApiError,
      };
      expected.forEach((status, code) {
        final dioError = _dio(DioExceptionType.badResponse, status: status);
        final e = NetworkExceptionMapper.map(dioError) as ApiException;
        expect(e.errorCode, code, reason: '$status');
        expect(e.statusCode, status);
        expect(e.cause, dioError);
      });
    });

    test('passes through NetworkException and handles unknown objects', () {
      const e = NotFoundException();
      expect(NetworkExceptionMapper.map(e), same(e));
      expect(NetworkExceptionMapper.map(Object()),
          isA<UnexpectedErrorException>());
    });
  });

  group('NetworkClient.get', () {
    test('returns the body', () async {
      final response =
          await _client(() async => ResponseBody.fromString('hi', 200))
              .get('https://x.test');
      expect(response.body, 'hi');
      expect(response.statusCode, 200);
      expect(response.finalUri.host, 'x.test');
    });

    test('throws ApiException on error status', () async {
      final client = _client(() async => ResponseBody.fromString('nope', 404));
      await expectLater(
          client.get('https://x.test'),
          throwsA(isA<NotFoundException>()
              .having((e) => e.errorCode, 'code', NetworkErrorCode.notFound)));
    });

    test('throws EmptyResponseException on empty body', () async {
      final client = _client(() async => ResponseBody.fromString('', 200));
      await expectLater(
          client.get('https://x.test'), throwsA(isA<EmptyResponseException>()));
    });

    test('maps socket failures to NoInternetConnectionException', () async {
      final client = _client(() async => throw _dio(DioExceptionType.unknown,
          error: const SocketException('offline')));
      await expectLater(client.get('https://x.test'),
          throwsA(isA<NoInternetConnectionException>()));
    });
  });
}

class _Adapter implements HttpClientAdapter {
  final int status;
  _Adapter(this.status);
  @override
  Future<ResponseBody> fetch(
          RequestOptions o, Stream<List<int>>? r, Future<void>? c) async =>
      ResponseBody.fromString('payload', status, headers: {
        'content-type': ['text/plain']
      });
  @override
  void close({bool force = false}) {}
}

void loggingTests() {
  group('NetworkLogInterceptor', () {
    NetworkClient make(int status, List<String> logs) => NetworkClient(
          dio: Dio(BaseOptions(responseType: ResponseType.plain))
            ..httpClientAdapter = _Adapter(status),
          maxRetries: 0,
          logInterceptor: NetworkLogInterceptor(printer: logs.add),
        );

    test('logs request and response when enabled', () async {
      final logs = <String>[];
      await make(200, logs).get('https://x.test/a?b=1',
          headers: {'Authorization': 'secret', 'Accept-Language': 'en'},
          enableLog: true);
      final out = logs.join('\n');
      expect(out, contains('GET https://x.test/a?b=1'));
      expect(out, contains('200'));
      expect(out, contains('payload'));
      expect(out, contains('ms)'));
      expect(out, contains('Accept-Language'));
      expect(out, isNot(contains('secret')));
    });

    test('logs errors when enabled', () async {
      final logs = <String>[];
      await expectLater(make(404, logs).get('https://x.test', enableLog: true),
          throwsA(isA<ApiException>()));
      final out = logs.join('\n');
      expect(out, contains('badResponse'));
      expect(out, contains('status: 404'));
    });

    test('is silent when disabled', () async {
      final logs = <String>[];
      await make(200, logs).get('https://x.test');
      expect(logs, isEmpty);
    });
  });
}

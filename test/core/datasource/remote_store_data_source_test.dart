import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/datasource/remote_store_data_source.dart';
import 'package:playx_version_update/src/core/datasource/store_response_validator.dart';
import 'package:playx_version_update/src/core/network/network_client.dart';
import 'package:playx_version_update/src/core/network/network_log_interceptor.dart';
import 'package:playx_version_update/src/core/network/network_response.dart';

class _FakeAdapter implements HttpClientAdapter {
  final List<ResponseBody Function(RequestOptions)> responses;
  final List<RequestOptions> requests = [];
  _FakeAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final i = requests.length - 1;
    return responses[i < responses.length ? i : responses.length - 1](options);
  }

  @override
  void close({bool force = false}) {}
}

(RemoteStoreDataSource, _FakeAdapter) _source(
  List<ResponseBody Function(RequestOptions)> responses, {
  int maxRetries = 0,
}) {
  final adapter = _FakeAdapter(responses);
  final dio = Dio(BaseOptions(responseType: ResponseType.plain))
    ..httpClientAdapter = adapter;
  final client = NetworkClient(
    dio: dio,
    maxRetries: maxRetries,
    retryDelay: Duration.zero,
  );
  return (RemoteStoreDataSource.withClient(client), adapter);
}

PlayxVersionNetworkError _error(PlayxVersionUpdateResult r) =>
    r.updateError as PlayxVersionNetworkError;

const _appStoreJson =
    '{"resultCount":1,"results":[{"version":"2.0.0","trackViewUrl":"https://apps.apple.com/x"}]}';

void main() {
  Future<PlayxVersionUpdateResult> play(RemoteStoreDataSource s) =>
      s.getPlayStoreInfo(packageId: 'a.b', country: 'us', language: 'en');
  Future<PlayxVersionUpdateResult> apple(RemoteStoreDataSource s) =>
      s.getAppStoreInfo(packageId: 'a.b', country: 'us', language: 'en');

  test('app store success', () async {
    final (s, _) = _source([
      (_) => ResponseBody.fromString(_appStoreJson, 200),
    ]);
    final r = await apple(s);
    expect((r.updateData as dynamic).version, '2.0.0');
  });

  test('app store empty results -> AppNotFoundException', () async {
    final (s, _) = _source([
      (_) => ResponseBody.fromString('{"resultCount":0,"results":[]}', 200),
    ]);
    final e = _error(await apple(s));
    expect(e.error, isA<AppNotFoundException>());
    expect(e.errorCode, NetworkErrorCode.appNotFound);
  });

  test('app store invalid json -> InvalidFormatException', () async {
    final (s, _) = _source([(_) => ResponseBody.fromString('<html>', 200)]);
    expect(_error(await apple(s)).error, isA<InvalidFormatException>());
  });

  test('app store 403 -> TooManyRequestsException', () async {
    final (s, _) = _source([(_) => ResponseBody.fromString('', 403)]);
    expect(_error(await apple(s)).error, isA<TooManyRequestsException>());
  });

  test('google play 404 -> AppNotFoundException', () async {
    final (s, _) = _source([(_) => ResponseBody.fromString('', 404)]);
    expect(_error(await play(s)).error, isA<AppNotFoundException>());
  });

  test('google play sends browser headers', () async {
    final (s, adapter) = _source([
      (_) => ResponseBody.fromString(
        '<span itemprop="softwareVersion">1.2.3<',
        200,
      ),
    ]);
    await play(s);
    final h = adapter.requests.single.headers;
    expect(h['Accept-Language'], 'en');
    expect(h['User-Agent'], contains('Mozilla'));
  });

  test('retries retryable failures', () async {
    final (s, adapter) = _source([
      (_) => ResponseBody.fromString('', 503),
      (_) => ResponseBody.fromString(_appStoreJson, 200),
    ], maxRetries: 1);
    final r = await apple(s);
    expect(r.isSuccess, isTrue);
    expect(adapter.requests, hasLength(2));
  });

  test('does not retry non-retryable failures', () async {
    final (s, adapter) = _source([
      (_) => ResponseBody.fromString('', 404),
    ], maxRetries: 3);
    await apple(s);
    expect(adapter.requests, hasLength(1));
  });

  test('gives up after maxRetries', () async {
    final (s, adapter) = _source([
      (_) => ResponseBody.fromString('', 503),
    ], maxRetries: 2);
    final e = _error(await apple(s));
    expect(e.error, isA<ServiceUnavailableException>());
    expect(e.error.isRetryable, isTrue);
    expect(adapter.requests, hasLength(3));
  });

  group('network options', () {
    Future<PlayxVersionUpdateResult> playWith(
      RemoteStoreDataSource s,
      PlayxNetworkOptions o,
    ) => s.getPlayStoreInfo(
      packageId: 'a.b',
      country: 'us',
      language: 'en',
      networkOptions: o,
    );

    const okPlay = '<span itemprop="softwareVersion">1.2.3<';

    test('custom headers override the defaults', () async {
      final (s, adapter) = _source([
        (_) => ResponseBody.fromString(okPlay, 200),
      ]);
      await playWith(
        s,
        const PlayxNetworkOptions(
          headers: {'User-Agent': 'custom', 'X-App': 'me'},
        ),
      );
      final h = adapter.requests.single.headers;
      expect(h['User-Agent'], 'custom');
      expect(h['X-App'], 'me');
      expect(h['Accept-Language'], 'en');
    });

    test('timeouts are applied to the request', () async {
      final (s, adapter) = _source([
        (_) => ResponseBody.fromString(okPlay, 200),
      ]);
      await playWith(
        s,
        const PlayxNetworkOptions(
          connectTimeout: Duration(seconds: 3),
          sendTimeout: Duration(seconds: 4),
          receiveTimeout: Duration(seconds: 5),
        ),
      );
      final r = adapter.requests.single;
      expect(r.connectTimeout, const Duration(seconds: 3));
      expect(r.sendTimeout, const Duration(seconds: 4));
      expect(r.receiveTimeout, const Duration(seconds: 5));
    });

    test('maxRetries is taken from the options', () async {
      final (s, adapter) = _source([
        (_) => ResponseBody.fromString('', 503),
      ], maxRetries: 3);
      await playWith(s, const PlayxNetworkOptions(maxRetries: 0));
      expect(adapter.requests, hasLength(1));

      final (s2, adapter2) = _source([(_) => ResponseBody.fromString('', 503)]);
      await playWith(
        s2,
        const PlayxNetworkOptions(maxRetries: 2, retryDelay: Duration.zero),
      );
      expect(adapter2.requests, hasLength(3));
    });

    test('uses a custom Dio and attaches the logger only once', () async {
      final (s, defaultAdapter) = _source([]);
      final custom = _FakeAdapter([
        (_) => ResponseBody.fromString(okPlay, 200),
      ]);
      final dio = Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = custom;

      final options = PlayxNetworkOptions(dio: dio);
      expect((await playWith(s, options)).isSuccess, isTrue);
      await playWith(s, options);

      expect(defaultAdapter.requests, isEmpty);
      expect(custom.requests, hasLength(2));
      expect(dio.interceptors.whereType<NetworkLogInterceptor>(), hasLength(1));
    });

    test('a cancelled token fails with RequestCanceledException', () async {
      final (s, adapter) = _source([
        (_) => ResponseBody.fromString(okPlay, 200),
      ]);
      final token = CancelToken()..cancel();
      final e = _error(
        await playWith(s, PlayxNetworkOptions(cancelToken: token)),
      );
      expect(e.error, isA<RequestCanceledException>());
      expect(e.errorCode, NetworkErrorCode.requestCanceled);
      expect(adapter.requests, isEmpty);
    });
  });

  group('google consent page', () {
    test('consent redirect body -> ConsentRequiredException', () async {
      final (s, adapter) = _source([
        (_) => ResponseBody.fromString(
          '<form action="https://consent.google.com/save">',
          200,
        ),
      ], maxRetries: 2);
      final e = _error(await play(s));
      expect(e.error, isA<ConsentRequiredException>());
      expect(e.errorCode, NetworkErrorCode.consentRequired);
      expect(e.error.isRetryable, isFalse);
      expect(adapter.requests, hasLength(1));
    });

    test('a page with only a modern version marker that mentions consent '
        'is still parsed', () async {
      final (s, _) = _source([
        (_) => ResponseBody.fromString(
          'var a="https://consent.google.com/x"; [[["3.4.5"]]',
          200,
        ),
      ]);
      final result = await play(s);
      expect(result.isSuccess, isTrue, reason: result.updateError?.message);
    });

    test('a normal page that mentions consent is still parsed', () async {
      final (s, _) = _source([
        (_) => ResponseBody.fromString(
          'consent.google.com <span itemprop="softwareVersion">1.2.3<',
          200,
        ),
      ]);
      expect((await play(s)).isSuccess, isTrue);
    });

    test('detects the consent host after redirects', () {
      NetworkResponse r(String url, String body) =>
          NetworkResponse(body: body, finalUri: Uri.parse(url));
      expect(
        StoreResponseValidator.isGoogleConsentPage(
          r('https://consent.google.com/m?continue=x', '<html>'),
          versionFound: false,
        ),
        isTrue,
      );
      // The redirect is conclusive, even if something looked like a version.
      expect(
        StoreResponseValidator.isGoogleConsentPage(
          r('https://consent.google.com/m?continue=x', '<html>'),
          versionFound: true,
        ),
        isTrue,
      );
      expect(
        StoreResponseValidator.isGoogleConsentPage(
          r('https://play.google.com/store/apps/details', '<html>'),
          versionFound: false,
        ),
        isFalse,
      );
      // An inline form is only recognized when no version could be read.
      expect(
        StoreResponseValidator.isGoogleConsentPage(
          r('https://play.google.com/x', 'consent.google.com'),
          versionFound: false,
        ),
        isTrue,
      );
      expect(
        StoreResponseValidator.isGoogleConsentPage(
          r('https://play.google.com/x', 'consent.google.com'),
          versionFound: true,
        ),
        isFalse,
      );
    });

    test('the app store is never treated as consent', () async {
      final (s, _) = _source([
        (_) => ResponseBody.fromString('consent.google.com', 200),
      ]);
      expect(_error(await apple(s)).error, isA<InvalidFormatException>());
    });
  });
}

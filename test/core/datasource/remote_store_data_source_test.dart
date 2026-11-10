import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/datasource/remote_store_data_source.dart';
import 'package:playx_version_update/src/core/network/network_client.dart';

class _FakeAdapter implements HttpClientAdapter {
  final List<ResponseBody Function(RequestOptions)> responses;
  final List<RequestOptions> requests = [];
  _FakeAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final i = requests.length - 1;
    return responses[i < responses.length ? i : responses.length - 1](options);
  }

  @override
  void close({bool force = false}) {}
}

(RemoteStoreDataSource, _FakeAdapter) _source(
    List<ResponseBody Function(RequestOptions)> responses,
    {int maxRetries = 0}) {
  final adapter = _FakeAdapter(responses);
  final dio = Dio(BaseOptions(responseType: ResponseType.plain))
    ..httpClientAdapter = adapter;
  final client = NetworkClient(
      dio: dio, maxRetries: maxRetries, retryDelay: Duration.zero);
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
    final (s, _) =
        _source([(_) => ResponseBody.fromString(_appStoreJson, 200)]);
    final r = await apple(s);
    expect((r.updateData as dynamic).version, '2.0.0');
  });

  test('app store empty results -> AppNotFoundException', () async {
    final (s, _) = _source([
      (_) => ResponseBody.fromString('{"resultCount":0,"results":[]}', 200)
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
          '<span itemprop="softwareVersion">1.2.3<', 200)
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
    final (s, adapter) =
        _source([(_) => ResponseBody.fromString('', 404)], maxRetries: 3);
    await apple(s);
    expect(adapter.requests, hasLength(1));
  });

  test('gives up after maxRetries', () async {
    final (s, adapter) =
        _source([(_) => ResponseBody.fromString('', 503)], maxRetries: 2);
    final e = _error(await apple(s));
    expect(e.error, isA<ServiceUnavailableException>());
    expect(e.error.isRetryable, isTrue);
    expect(adapter.requests, hasLength(3));
  });
}

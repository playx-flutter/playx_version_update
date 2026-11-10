import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/datasource/remote_store_data_source.dart';
import 'package:playx_version_update/src/core/network/network_client.dart';

class _CountingAdapter implements HttpClientAdapter {
  final ResponseBody Function() response;
  int count = 0;
  _CountingAdapter(this.response);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    count++;
    return response();
  }

  @override
  void close({bool force = false}) {}
}

const _request = PlayxVersionRequest(
  isAndroid: true,
  packageId: 'a.b',
  country: 'us',
  language: 'en',
);

PlayxVersionSource _ok(String version) => PlayxCallbackVersionSource(
  (_) async => PlayxRemoteVersionInfo(version: version),
);

PlayxVersionSource _fail(PlayxVersionUpdateError Function() error) =>
    _FailingSource(error);

class _FailingSource implements PlayxVersionSource {
  final PlayxVersionUpdateError Function() error;
  int calls = 0;
  _FailingSource(this.error);

  @override
  Future<PlayxVersionUpdateResult<PlayxRemoteVersionInfo>> fetch(
    PlayxVersionRequest request,
  ) async {
    calls++;
    return PlayxVersionUpdateResult.error(error());
  }
}

void main() {
  group('PlayxCallbackVersionSource', () {
    test('returns the callback value and passes the request', () async {
      PlayxVersionRequest? seen;
      final source = PlayxCallbackVersionSource((request) async {
        seen = request;
        return const PlayxRemoteVersionInfo(version: '2.0.0');
      });

      final result = await source.fetch(_request);
      expect(result.updateData!.version, '2.0.0');
      expect(seen!.packageId, 'a.b');
    });

    test('maps a NetworkException to PlayxVersionNetworkError', () async {
      final source = PlayxCallbackVersionSource(
        (_) async => throw const NoInternetConnectionException(),
      );
      final error = (await source.fetch(_request)).updateError;
      expect(error, isA<PlayxVersionNetworkError>());
      expect(error!.errorCode, NetworkErrorCode.noInternetConnection);
    });

    test('maps any other error to DefaultFailureError', () async {
      final source = PlayxCallbackVersionSource(
        (_) async => throw StateError('x'),
      );
      final error = (await source.fetch(_request)).updateError;
      expect(error, isA<DefaultFailureError>());
      expect(error!.message, contains('x'));
    });
  });

  group('PlayxFallbackVersionSource', () {
    test('uses the first success and stops', () async {
      final first = _FailingSource(() => const DefaultFailureError());
      final source = PlayxFallbackVersionSource([
        first,
        _ok('2.0.0'),
        _ok('3.0.0'),
      ]);

      expect((await source.fetch(_request)).updateData!.version, '2.0.0');
      expect(first.calls, 1);
    });

    test('returns the last error when every source fails', () async {
      final source = PlayxFallbackVersionSource([
        _fail(() => const DefaultFailureError(errorMsg: 'first')),
        _fail(() => const DefaultFailureError(errorMsg: 'last')),
      ]);
      expect((await source.fetch(_request)).updateError!.message, 'last');
    });

    test('fails clearly with no sources', () async {
      const source = PlayxFallbackVersionSource([]);
      expect((await source.fetch(_request)).isError, isTrue);
    });
  });

  group('PlayxStoreVersionSource', () {
    (PlayxStoreVersionSource, _CountingAdapter) make(
      ResponseBody Function() r,
    ) {
      final adapter = _CountingAdapter(r);
      final dio = Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter;
      return (
        PlayxStoreVersionSource(
          RemoteStoreDataSource.withClient(
            NetworkClient(dio: dio, maxRetries: 0),
          ),
        ),
        adapter,
      );
    }

    test('android with a provided version makes no request', () async {
      final (source, adapter) = make(() => ResponseBody.fromString('', 500));
      final info = (await source.fetch(
        const PlayxVersionRequest(
          isAndroid: true,
          packageId: 'a.b',
          country: 'us',
          language: 'en',
          providedVersion: '2.0.0',
        ),
      )).updateData!;

      expect(adapter.count, 0);
      expect(info.version, '2.0.0');
      expect(
        info.storeUrl,
        contains('play.google.com/store/apps/details?id=a.b'),
      );
    });

    test('android reads the Play page and carries the Play url', () async {
      final (source, adapter) = make(
        () => ResponseBody.fromString(
          '<span itemprop="softwareVersion">1.2.3<',
          200,
        ),
      );
      final info = (await source.fetch(_request)).updateData!;

      expect(adapter.count, 1);
      expect(info.version, '1.2.3');
      expect(info.storeUrl, contains('play.google.com'));
    });

    test('ios always looks up the App Store', () async {
      final (source, adapter) = make(
        () => ResponseBody.fromString(
          '{"results":[{"version":"9.0.0","trackViewUrl":"https://apps.apple.com/x"}]}',
          200,
        ),
      );
      final info = (await source.fetch(
        const PlayxVersionRequest(
          isAndroid: false,
          packageId: 'a.b',
          country: 'us',
          language: 'en',
          providedVersion: '2.0.0',
        ),
      )).updateData!;

      expect(adapter.count, 1);
      expect(info.version, '9.0.0');
      expect(info.storeUrl, 'https://apps.apple.com/x');
    });

    test('store errors are returned as errors', () async {
      final (source, _) = make(() => ResponseBody.fromString('', 404));
      expect(
        (await source.fetch(_request)).updateError,
        isA<PlayxVersionNetworkError>(),
      );
    });
  });
}

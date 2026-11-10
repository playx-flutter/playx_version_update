import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/src/core/datasource/remote_store_data_source.dart';
import 'package:playx_version_update/src/core/network/network_client.dart';
import 'package:playx_version_update/src/core/source/playx_callback_version_source.dart';
import 'package:playx_version_update/src/core/source/playx_remote_version_info.dart';
import 'package:playx_version_update/src/core/source/playx_version_source.dart';
import 'package:playx_version_update/src/core/model/playx_platform_version.dart';
import 'package:playx_version_update/src/core/model/playx_version_update_info.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/version_checker/version_checker.dart';

void main() {
  final checker = VersionChecker();

  group('resolvePlatformVersionForCurrentPlatform', () {
    test('prefers current platform-specific value over the generic version',
        () {
      const platformVersion = PlayxPlatformVersion(
        android: '2.0.0',
        ios: '3.0.0',
      );

      expect(
        resolvePlatformVersionForCurrentPlatform(
          isAndroid: true,
          genericVersion: '1.0.0',
          platformVersion: platformVersion,
        ),
        '2.0.0',
      );
      expect(
        resolvePlatformVersionForCurrentPlatform(
          isAndroid: false,
          genericVersion: '1.0.0',
          platformVersion: platformVersion,
        ),
        '3.0.0',
      );
    });

    test(
        'falls back to the generic version when current platform value is missing',
        () {
      expect(
        resolvePlatformVersionForCurrentPlatform(
          isAndroid: true,
          genericVersion: '1.0.0',
          platformVersion: const PlayxPlatformVersion(ios: '3.0.0'),
        ),
        '1.0.0',
      );
      expect(
        resolvePlatformVersionForCurrentPlatform(
          isAndroid: false,
          genericVersion: '1.0.0',
          platformVersion: const PlayxPlatformVersion(android: '2.0.0'),
        ),
        '1.0.0',
      );
    });

    test('returns the generic version when no platform object is provided', () {
      expect(
        resolvePlatformVersionForCurrentPlatform(
          isAndroid: true,
          genericVersion: '1.0.0',
          platformVersion: null,
        ),
        '1.0.0',
      );
    });
  });

  group('VersionChecker.getMinVersionVersion', () {
    test('returns null for missing minimum version', () async {
      expect(
        await checker.getMinVersionVersion(
          minVersion: null,
          storeVersion: '1.2.3',
        ),
        isNull,
      );
      expect(
        await checker.getMinVersionVersion(
          minVersion: '',
          storeVersion: '1.2.3',
        ),
        isNull,
      );
    });

    test('uses the parser behavior for permissive minimum version strings',
        () async {
      expect(
        await checker.getMinVersionVersion(
          minVersion: 'not-a-version',
          storeVersion: '1.2.3',
        ),
        '0.0.0-a-version',
      );
      expect(
        await checker.getMinVersionVersion(
          minVersion: '1.2.3+build?1',
          storeVersion: null,
        ),
        '1.2.0',
      );
    });

    test('normalizes parsed minimum version', () async {
      expect(
        await checker.getMinVersionVersion(
          minVersion: '1.2',
          storeVersion: null,
        ),
        '1.2.0',
      );
      expect(
        await checker.getMinVersionVersion(
          minVersion: '3.122.764106578.release',
          storeVersion: null,
        ),
        '3.122.764106578',
      );
    });

    test('clamps minimum version to store version when needed', () async {
      expect(
        await checker.getMinVersionVersion(
          minVersion: '2.0.0',
          storeVersion: '1.5.0',
        ),
        '1.5.0',
      );
      expect(
        await checker.getMinVersionVersion(
          minVersion: '1.2.3.9',
          storeVersion: '1.2.3.4',
        ),
        '1.2.3.4',
      );
      expect(
        await checker.getMinVersionVersion(
          minVersion: '9.0.0',
          storeVersion: '2.0.0',
        ),
        '2.0.0',
      );
    });

    test('keeps the minimum version when it is below the store version',
        () async {
      expect(
        await checker.getMinVersionVersion(
          minVersion: '1.2.3-alpha.1',
          storeVersion: '1.2.3',
        ),
        '1.2.3-alpha.1',
      );
    });
  });

  group('VersionChecker.shouldForceUpdate', () {
    test('respects explicit override first', () async {
      expect(
        await checker.shouldForceUpdate(
          version: '1.0.0',
          minVersion: '9.0.0',
          playxForceUpdate: false,
        ),
        isFalse,
      );
      expect(
        await checker.shouldForceUpdate(
          version: '9.0.0',
          minVersion: null,
          playxForceUpdate: true,
        ),
        isTrue,
      );
    });

    test('returns false when minimum version is missing or truly invalid',
        () async {
      expect(
        await checker.shouldForceUpdate(
          version: '1.0.0',
          minVersion: null,
          playxForceUpdate: null,
        ),
        isFalse,
      );
      expect(
        await checker.shouldForceUpdate(
          version: '1.0.0',
          minVersion: '1.2.3-alpha..1',
          playxForceUpdate: null,
        ),
        isFalse,
      );
    });

    test('forces update when local version is equal to or below minimum',
        () async {
      expect(
        await checker.shouldForceUpdate(
          version: '1.2.2',
          minVersion: '1.2.3',
          playxForceUpdate: null,
        ),
        isTrue,
      );
      expect(
        await checker.shouldForceUpdate(
          version: '1.2.3',
          minVersion: '1.2.3',
          playxForceUpdate: null,
        ),
        isTrue,
      );
      expect(
        await checker.shouldForceUpdate(
          version: '1.2.3-alpha.1',
          minVersion: '1.2.3',
          playxForceUpdate: null,
        ),
        isTrue,
      );
    });

    test('does not force update when local version is above minimum', () async {
      expect(
        await checker.shouldForceUpdate(
          version: '1.2.4',
          minVersion: '1.2.3',
          playxForceUpdate: null,
        ),
        isFalse,
      );
      expect(
        await checker.shouldForceUpdate(
          version: '1.2.3.5',
          minVersion: '1.2.3.4',
          playxForceUpdate: null,
        ),
        isFalse,
      );
    });
  });

  group('VersionChecker.shouldUpdate', () {
    test('returns success true only when current version is newer', () async {
      final newer = await checker.shouldUpdate(
        version: '1.2.3',
        currentVersion: '1.2.4',
      );
      final equal = await checker.shouldUpdate(
        version: '1.2.3',
        currentVersion: '1.2.3',
      );
      final older = await checker.shouldUpdate(
        version: '1.2.4',
        currentVersion: '1.2.3',
      );

      expect(newer.isSuccess, isTrue);
      expect(newer.updateData, isTrue);
      expect(equal.updateData, isFalse);
      expect(older.updateData, isFalse);
    });

    test('handles additional segments and pre-release precedence', () async {
      final additional = await checker.shouldUpdate(
        version: '1.2.3.4',
        currentVersion: '1.2.3.5',
      );
      final preRelease = await checker.shouldUpdate(
        version: '1.2.3-alpha.1',
        currentVersion: '1.2.3',
      );

      expect(additional.updateData, isTrue);
      expect(preRelease.updateData, isTrue);
    });

    test('returns VersionFormatException for empty current version', () async {
      final result = await checker.shouldUpdate(
        version: '1.2.3',
        currentVersion: '',
      );

      expect(result.isError, isTrue);
      expect(result.updateError, isA<VersionFormatException>());
    });

    test('returns VersionFormatException for truly malformed current version',
        () async {
      final result = await checker.shouldUpdate(
        version: '1.2.3',
        currentVersion: '1.2.3-alpha..1',
      );

      expect(result.isError, isTrue);
      expect(result.updateError, isA<VersionFormatException>());
    });
  });

  group('provided new version', () {
    const appStoreJson =
        '{"resultCount":1,"results":[{"version":"9.0.0","trackViewUrl":"https://apps.apple.com/x","description":"[Minimum Version: 2.0.0]"}]}';

    (VersionChecker, _CountingAdapter) make(
        ResponseBody Function() response) {
      final adapter = _CountingAdapter(response);
      final dio = Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter;
      final client =
          NetworkClient(dio: dio, maxRetries: 0, retryDelay: Duration.zero);
      return (
        VersionChecker.withDataSource(RemoteStoreDataSource.withClient(client)),
        adapter,
      );
    }

    Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>> android(
      VersionChecker c, {
      String? newVersion,
      String? minVersion,
      PlayxPlatformVersion? platform,
      PlayxVersionSource? source,
    }) =>
        c.checkVersionFor(
          isAndroid: true,
          localVersion: '1.0.0',
          packageId: 'a.b',
          country: 'us',
          language: 'en',
          newVersion: newVersion,
          newPlatformVersion: platform,
          minVersion: minVersion,
          minPlatformVersion: null,
          forceUpdate: null,
          source: source,
        );

    Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>> ios(
      VersionChecker c, {
      String? newVersion,
      PlayxVersionSource? source,
    }) =>
        c.checkVersionFor(
          isAndroid: false,
          localVersion: '1.0.0',
          packageId: 'a.b',
          country: 'us',
          language: 'en',
          newVersion: newVersion,
          newPlatformVersion: null,
          minVersion: null,
          minPlatformVersion: null,
          forceUpdate: null,
          source: source,
        );

    test('android does not request the store', () async {
      final (c, adapter) = make(() => ResponseBody.fromString('', 500));
      final result = await android(c, newVersion: '2.0.0');

      expect(adapter.count, 0);
      final info = result.updateData!;
      expect(info.newVersion, '2.0.0');
      expect(info.canUpdate, isTrue);
      expect(info.storeUrl, contains('play.google.com'));
    });

    test('android platform override also skips the store', () async {
      final (c, adapter) = make(() => ResponseBody.fromString('', 500));
      final result = await android(c,
          platform: const PlayxPlatformVersion(android: '3.0.0'));

      expect(adapter.count, 0);
      expect(result.updateData!.newVersion, '3.0.0');
    });

    test('android still requests the store without a provided version',
        () async {
      final (c, adapter) = make(() => ResponseBody.fromString('', 500));
      final result = await android(c);

      expect(adapter.count, 1);
      expect(result.isError, isTrue);
    });

    test('an empty provided version falls back to the store', () async {
      final (c, adapter) = make(() => ResponseBody.fromString('', 500));
      await android(c, newVersion: '');
      expect(adapter.count, 1);
    });

    test('ios uses the provided version when the lookup fails', () async {
      final (c, adapter) = make(() => ResponseBody.fromString('', 503));
      final result = await ios(c, newVersion: '2.0.0');

      expect(adapter.count, 1);
      final info = result.updateData!;
      expect(info.newVersion, '2.0.0');
      expect(info.storeUrl, '');
    });

    test('ios keeps the store url and extras when the lookup works',
        () async {
      final (c, _) = make(() => ResponseBody.fromString(appStoreJson, 200));
      final info = (await ios(c, newVersion: '2.0.0')).updateData!;

      expect(info.newVersion, '2.0.0');
      expect(info.storeUrl, 'https://apps.apple.com/x');
      expect(info.minVersion, '2.0.0');
    });

    test('ios without a provided version still fails when the lookup fails',
        () async {
      final (c, _) = make(() => ResponseBody.fromString('', 503));
      expect((await ios(c)).isError, isTrue);
    });
  });

  group('custom version source', () {
    PlayxVersionSource source(PlayxRemoteVersionInfo info) =>
        PlayxCallbackVersionSource((_) async => info);

    final failing = PlayxCallbackVersionSource((_) async => throw 'boom');

    (VersionChecker, _CountingAdapter) make() {
      final adapter = _CountingAdapter(() => ResponseBody.fromString('', 500));
      final dio = Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter;
      return (
        VersionChecker.withDataSource(RemoteStoreDataSource.withClient(
            NetworkClient(dio: dio, maxRetries: 0))),
        adapter,
      );
    }

    Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>> ios(
      VersionChecker c,
      PlayxVersionSource source, {
      String? newVersion,
      String? minVersion,
    }) =>
        c.checkVersionFor(
          isAndroid: false,
          localVersion: '1.0.0',
          packageId: 'a.b',
          country: 'us',
          language: 'en',
          newVersion: newVersion,
          newPlatformVersion: null,
          minVersion: minVersion,
          minPlatformVersion: null,
          forceUpdate: null,
          source: source,
        );

    Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>> android(
      VersionChecker c,
      PlayxVersionSource source,
    ) =>
        c.checkVersionFor(
          isAndroid: true,
          localVersion: '1.0.0',
          packageId: 'a.b',
          country: 'us',
          language: 'en',
          newVersion: null,
          newPlatformVersion: null,
          minVersion: null,
          minPlatformVersion: null,
          forceUpdate: null,
          source: source,
        );

    test('uses every value of the source and never touches the store',
        () async {
      final (c, adapter) = make();
      final info = (await ios(
        c,
        source(const PlayxRemoteVersionInfo(
          version: '3.0.0',
          minVersion: '2.0.0',
          releaseNotes: 'Notes',
          storeUrl: 'https://my.store/app',
        )),
      ))
          .updateData!;

      expect(adapter.count, 0);
      expect(info.newVersion, '3.0.0');
      expect(info.minVersion, '2.0.0');
      // The local version 1.0.0 is not above the minimum 2.0.0.
      expect(info.forceUpdate, isTrue);
      expect(info.releaseNotes, 'Notes');
      expect(info.storeUrl, 'https://my.store/app');
    });

    test('a source minVersion above the local version forces the update',
        () async {
      final (c, _) = make();
      final info = (await ios(
        c,
        source(const PlayxRemoteVersionInfo(version: '3.0.0', minVersion: '1.0.0')),
      ))
          .updateData!;
      expect(info.forceUpdate, isTrue);
    });

    test('options newVersion and minVersion win over the source', () async {
      final (c, _) = make();
      final info = (await ios(
        c,
        source(const PlayxRemoteVersionInfo(version: '3.0.0', minVersion: '1.0.0')),
        newVersion: '4.0.0',
        minVersion: '0.5.0',
      ))
          .updateData!;

      expect(info.newVersion, '4.0.0');
      expect(info.minVersion, '0.5.0');
    });

    test('android falls back to the Google Play url', () async {
      final (c, _) = make();
      final info = (await android(
              c, source(const PlayxRemoteVersionInfo(version: '3.0.0'))))
          .updateData!;
      expect(info.storeUrl, contains('play.google.com'));
    });

    test('ios without a source url has an empty store url', () async {
      final (c, _) = make();
      final info =
          (await ios(c, source(const PlayxRemoteVersionInfo(version: '3.0.0'))))
              .updateData!;
      expect(info.storeUrl, '');
    });

    test('a failing source fails the check', () async {
      final (c, _) = make();
      final result = await ios(c, failing);
      expect(result.updateError, isA<DefaultFailureError>());
    });

    test('a failing source is ignored when a version is provided', () async {
      final (c, _) = make();
      final info = (await ios(c, failing, newVersion: '2.0.0')).updateData!;
      expect(info.newVersion, '2.0.0');
    });
  });
}

class _CountingAdapter implements HttpClientAdapter {
  final ResponseBody Function() response;
  int count = 0;
  _CountingAdapter(this.response);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    count++;
    return response();
  }

  @override
  void close({bool force = false}) {}
}

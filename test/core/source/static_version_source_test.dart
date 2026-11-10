import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/version_checker/version_checker.dart';

PlayxVersionRequest _request(PlayxPlatform platform) => PlayxVersionRequest(
  platform: platform,
  packageId: 'a.b',
  country: 'us',
  language: 'en',
);

const _source = PlayxStaticVersionSource(
  version: PlayxPlatformVersion(android: '2.0.0', ios: '3.0.0'),
  minVersion: PlayxPlatformVersion(android: '1.0.0', ios: '2.0.0'),
  releaseNotes: PlayxPlatformValue(ios: 'iOS notes'),
  storeUrls: PlayxPlatformValue(ios: 'https://my.link/ios'),
);

void main() {
  test('picks the values of the requested platform', () async {
    final android = (await _source.fetch(
      _request(PlayxPlatform.android),
    )).updateData!;
    expect(android.version, '2.0.0');
    expect(android.minVersion, '1.0.0');
    expect(android.releaseNotes, isNull);
    expect(android.storeUrl, isNull);

    final ios = (await _source.fetch(_request(PlayxPlatform.ios))).updateData!;
    expect(ios.version, '3.0.0');
    expect(ios.minVersion, '2.0.0');
    expect(ios.releaseNotes, 'iOS notes');
    expect(ios.storeUrl, 'https://my.link/ios');
  });

  test('fails when the platform has no version', () async {
    final result = await _source.fetch(_request(PlayxPlatform.macos));
    expect(result.updateError, isA<DefaultFailureError>());
    expect(result.updateError!.message, contains('macos'));
  });

  test('an empty version counts as missing', () async {
    const source = PlayxStaticVersionSource(
      version: PlayxPlatformVersion(android: ''),
    );
    expect(
      (await source.fetch(_request(PlayxPlatform.android))).isError,
      isTrue,
    );
  });

  test('works inside a fallback source', () async {
    const fallback = PlayxFallbackVersionSource([
      _source,
      PlayxStaticVersionSource(version: PlayxPlatformVersion(macos: '9.0.0')),
    ]);
    final result = await fallback.fetch(_request(PlayxPlatform.macos));
    expect(result.updateData!.version, '9.0.0');
  });

  test(
    'a different minimum version per platform forces different updates',
    () async {
      final checker = VersionChecker();

      Future<PlayxVersionUpdateInfo> check(PlayxPlatform platform) async {
        final result = await checker.checkVersionFor(
          platform: platform,
          localVersion: '1.5.0',
          packageId: 'a.b',
          country: 'us',
          language: 'en',
          newVersion: null,
          newPlatformVersion: null,
          minVersion: null,
          minPlatformVersion: null,
          forceUpdate: null,
          source: _source,
        );
        return result.updateData!;
      }

      // 1.5.0 is above the Android minimum (1.0.0) but below the iOS one (2.0.0).
      expect((await check(PlayxPlatform.android)).forceUpdate, isFalse);
      expect((await check(PlayxPlatform.ios)).forceUpdate, isTrue);
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/store/playx_store_links.dart';
import 'package:playx_version_update/src/core/store/playx_store_opener.dart';

const _play =
    'https://play.google.com/store/apps/details?id=com.example.app&hl=en&gl=us';
const _appStore = 'https://apps.apple.com/us/app/example/id123456789?mt=8';

void main() {
  group('PlayxStoreLinks.deepLinkFor', () {
    test('android turns a Google Play page into market://', () {
      final link = PlayxStoreLinks.deepLinkFor(
        _play,
        platform: PlayxPlatform.android,
      );
      expect(link.toString(), 'market://details?id=com.example.app');
    });

    test('android has no deep link for other urls', () {
      for (final url in [
        'https://example.com/app',
        'market://details?id=a.b',
        'https://play.google.com/store/apps/details',
        'https://play.google.com/store/search?q=x',
        '',
      ]) {
        expect(
          PlayxStoreLinks.deepLinkFor(url, platform: PlayxPlatform.android),
          isNull,
          reason: url,
        );
      }
    });

    test('ios swaps the scheme of App Store urls', () {
      expect(
        PlayxStoreLinks.deepLinkFor(
          _appStore,
          platform: PlayxPlatform.ios,
        ).toString(),
        'itms-apps://apps.apple.com/us/app/example/id123456789?mt=8',
      );
      expect(
        PlayxStoreLinks.deepLinkFor(
          'https://itunes.apple.com/app/id1',
          platform: PlayxPlatform.ios,
        ).toString(),
        'itms-apps://itunes.apple.com/app/id1',
      );
    });

    test('ios has no deep link for other urls', () {
      for (final url in [
        'https://example.com/app',
        'itms-apps://apps.apple.com/app/id1',
        'myscheme://store',
      ]) {
        expect(
          PlayxStoreLinks.deepLinkFor(url, platform: PlayxPlatform.ios),
          isNull,
          reason: url,
        );
      }
    });

    test('other platforms have no deep link', () {
      expect(
        PlayxStoreLinks.deepLinkFor(_play, platform: PlayxPlatform.macos),
        isNull,
      );
      expect(
        PlayxStoreLinks.deepLinkFor(_play, platform: PlayxPlatform.windows),
        isNull,
      );
    });

    test('a url for the wrong platform is not converted', () {
      expect(
        PlayxStoreLinks.deepLinkFor(_appStore, platform: PlayxPlatform.android),
        isNull,
      );
      expect(
        PlayxStoreLinks.deepLinkFor(_play, platform: PlayxPlatform.ios),
        isNull,
      );
    });
  });

  group('PlayxStoreLinks.candidates', () {
    test('deep link first, web url last', () {
      final urls = PlayxStoreLinks.candidates(
        _play,
        platform: PlayxPlatform.android,
      );
      expect(urls.map((u) => u.toString()), [
        'market://details?id=com.example.app',
        _play,
      ]);
    });

    test('preferStoreApp: false opens the web url only', () {
      final urls = PlayxStoreLinks.candidates(
        _play,
        preferStoreApp: false,
        platform: PlayxPlatform.android,
      );
      expect(urls.map((u) => u.toString()), [_play]);
    });

    test('urls without a deep link are opened as they are', () {
      final urls = PlayxStoreLinks.candidates(
        'market://details?id=a.b',
        platform: PlayxPlatform.android,
      );
      expect(urls.map((u) => u.toString()), ['market://details?id=a.b']);
    });

    test('an empty url has no candidates', () {
      expect(PlayxStoreLinks.candidates(''), isEmpty);
    });
  });

  group('openStoreUrl', () {
    late List<String> tried;

    Future<PlayxVersionUpdateResult<bool>> open(
      Future<bool> Function(Uri uri) launch, {
      String url = _play,
      bool preferStoreApp = true,
    }) {
      tried = [];
      return openStoreUrl(
        url,
        platform: PlayxPlatform.android,
        preferStoreApp: preferStoreApp,
        launch: (uri, mode) {
          tried.add(uri.toString());
          return launch(uri);
        },
      );
    }

    test('stops at the deep link when it opens', () async {
      final result = await open((_) async => true);
      expect(result.updateData, isTrue);
      expect(tried, ['market://details?id=com.example.app']);
    });

    test('falls back to the web url when the deep link cannot open', () async {
      final result = await open((uri) async => uri.scheme == 'https');
      expect(result.updateData, isTrue);
      expect(tried, ['market://details?id=com.example.app', _play]);
    });

    test('falls back to the web url when the deep link throws', () async {
      final result = await open((uri) async {
        if (uri.scheme == 'market') throw StateError('no activity');
        return true;
      });
      expect(result.updateData, isTrue);
      expect(tried, hasLength(2));
    });

    test('fails when nothing opens', () async {
      final result = await open((_) async => false);
      expect(result.updateError, isA<DefaultFailureError>());
      expect(result.updateError!.message, 'Could not launch store.');
    });

    test('reports the last error when every attempt throws', () async {
      final result = await open((_) async => throw StateError('boom'));
      expect(result.updateError!.message, contains('boom'));
    });

    test('preferStoreApp: false skips the deep link', () async {
      await open((_) async => true, preferStoreApp: false);
      expect(tried, [_play]);
    });

    test('an empty url fails without launching', () async {
      final result = await open((_) async => true, url: '');
      expect(result.isError, isTrue);
      expect(tried, isEmpty);
    });
  });
}

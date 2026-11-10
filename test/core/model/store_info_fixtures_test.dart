import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/model/store_info.dart';
import 'package:playx_version_update/src/core/datasource/store_response_validator.dart';
import 'package:playx_version_update/src/core/network/network_response.dart';

/// Parses captured responses of the real stores, so a change in the pages or
/// the API shows up here.
String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  group('Google Play page', () {
    final page = _fixture('google_play_excerpt.html');

    test('is read through the last-resort version pattern', () {
      final info = StoreInfo.fromGooglePlay(page);

      expect(info.version, matches(RegExp(r'^\d+(\.\d+)+$')));
      expect(info.releaseNotes, isNotNull);
      expect(info.releaseNotes, isNotEmpty);
    });

    test('is not mistaken for the consent page', () {
      final response = NetworkResponse(
        body: page,
        finalUri: Uri.parse('https://play.google.com/store/apps/details'),
      );
      expect(StoreResponseValidator.isGoogleConsentPage(response), isFalse);
    });

    test('an unrelated page has no version', () {
      expect(StoreInfo.fromGooglePlay('<html><body>hello</body></html>').version,
          isEmpty);
    });

    test('the current-version label and the itemprop are preferred', () {
      expect(
        StoreInfo.fromGooglePlay(
          '<div>Current Version</div><span class="a"><div class="b"><span class="c">7.8.9</span>',
        ).version,
        '7.8.9',
      );
      expect(
        StoreInfo.fromGooglePlay(
          '<span class="x" itemprop="softwareVersion">4.5.6</span>',
        ).version,
        '4.5.6',
      );
    });
  });

  group('App Store lookup', () {
    test('reads an iOS app', () {
      final info = StoreInfo.fromAppStore(_fixture('app_store_shortcuts.json'));

      expect(info.version, matches(RegExp(r'^\d+(\.\d+)+$')));
      expect(info.storeUrl, startsWith('https://apps.apple.com/'));
      expect(info.releaseNotes, isNotNull);
    });

    test('reads a Mac app', () {
      final info = StoreInfo.fromAppStore(_fixture('mac_app_store_xcode.json'));

      expect(info.version, matches(RegExp(r'^\d+(\.\d+)+$')));
      expect(info.storeUrl, contains('mt=12'));
    });

    test('an empty result means the app is not on the store', () {
      expect(
        () => StoreInfo.fromAppStore(_fixture('app_store_empty.json')),
        throwsA(isA<AppNotFoundException>()),
      );
    });

    test('a body that is not JSON is an invalid format', () {
      expect(
        () => StoreInfo.fromAppStore('<html>nope</html>'),
        throwsA(isA<InvalidFormatException>()),
      );
    });

    test('a result without a version has an empty version', () {
      final info = StoreInfo.fromAppStore('{"results":[{"trackName":"x"}]}');
      expect(info.version, isEmpty);
    });
  });

  group('StoreInfo', () {
    test('supports equality, hashCode and toString', () {
      final a = StoreInfo(version: '1.0.0', minVersion: '0.5.0');
      final b = StoreInfo(version: '1.0.0', minVersion: '0.5.0');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(StoreInfo(version: '2.0.0')));
      expect(a.toString(), contains('version: 1.0.0'));
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/src/core/model/store_info.dart';

void main() {
  group('StoreInfo.extractMinVersion', () {
    test('parses the original bracketed format case-insensitively', () {
      expect(
        StoreInfo.extractMinVersion('[Minimum Version :1.2.0]'),
        '1.2.0',
      );
      expect(
        StoreInfo.extractMinVersion('[minimum version :1.2.0]'),
        '1.2.0',
      );
    });

    test('supports common separator and spacing variants', () {
      expect(
        StoreInfo.extractMinVersion('[Minimum Version: 1.2.0]'),
        '1.2.0',
      );
      expect(
        StoreInfo.extractMinVersion('[Minimum Version = 1.2.0]'),
        '1.2.0',
      );
      expect(
        StoreInfo.extractMinVersion('[minimum_version:1.2.0-beta.1+45]'),
        '1.2.0-beta.1+45',
      );
      expect(
        StoreInfo.extractMinVersion('[minimum-version: 2.0]'),
        '2.0',
      );
    });

    test('supports version styles accepted by Version.parse', () {
      expect(
        StoreInfo.extractMinVersion('[Minimum Version: 519.0.0.44.92]'),
        '519.0.0.44.92',
      );
      expect(
        StoreInfo.extractMinVersion(
          '[Minimum Version: 3.122.764106578.release]',
        ),
        '3.122.764106578.release',
      );
      expect(
        StoreInfo.extractMinVersion(
          '[Minimum Version: 1.2.3-alpha.1+build.456]',
        ),
        '1.2.3-alpha.1+build.456',
      );
    });

    test('ignores unbracketed text to avoid accidental matches', () {
      expect(
        StoreInfo.extractMinVersion('Minimum Version = 1.2.0'),
        isNull,
      );
      expect(
        StoreInfo.extractMinVersion('Some note minimum_version:1.2.0'),
        isNull,
      );
    });

    test('ignores invalid versions even when bracketed', () {
      expect(
        StoreInfo.extractMinVersion('[Minimum Version: not-a-version]'),
        isNull,
      );
    });

    test('returns null when the tag is not present', () {
      expect(
        StoreInfo.extractMinVersion('No minimum version tag here'),
        isNull,
      );
    });
  });

  group('StoreInfo.fromAppStore', () {
    test('extracts minimum version from iOS description', () {
      final body = json.encode({
        'results': [
          {
            'version': '1.3.0',
            'trackViewUrl': 'https://apps.apple.com/app/id123',
            'releaseNotes': 'Bug fixes',
            'description': 'Features...\n[Minimum Version :1.3.0]',
          }
        ]
      });

      final info = StoreInfo.fromAppStore(body);

      expect(info.version, '1.3.0');
      expect(info.minVersion, '1.3.0');
      expect(info.storeUrl, 'https://apps.apple.com/app/id123');
    });
  });

  group('StoreInfo.fromGooglePlay', () {
    test('extracts minimum version from Google Play description', () {
      const body = '''
Current Version</div><span><div><span>1.4.0</span>
[[null,"Features and fixes [Minimum Version = 1.2.0-beta.1]"]]
''';

      final info = StoreInfo.fromGooglePlay(body);

      expect(info.version, '1.4.0');
      expect(info.minVersion, '1.2.0-beta.1');
    });
  });
}

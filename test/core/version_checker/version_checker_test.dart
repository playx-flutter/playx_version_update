import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/version_checker/version_checker.dart';

void main() {
  final checker = VersionChecker();

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
}

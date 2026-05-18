import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/src/core/model/playx_platform_version.dart';

void main() {
  group('PlayxPlatformVersion', () {
    const version = PlayxPlatformVersion(
      android: '2.0.0',
      ios: '3.0.0',
    );

    test('returns the correct value for the current platform', () {
      expect(version.forCurrentPlatform(isAndroid: true), '2.0.0');
      expect(version.forCurrentPlatform(isAndroid: false), '3.0.0');
    });

    test('supports equality, hashCode, and toString', () {
      const same = PlayxPlatformVersion(
        android: '2.0.0',
        ios: '3.0.0',
      );

      expect(version, same);
      expect(version.hashCode, same.hashCode);
      expect(version.toString(), contains('android: 2.0.0'));
      expect(version.toString(), contains('ios: 3.0.0'));
    });
  });
}

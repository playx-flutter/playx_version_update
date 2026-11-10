import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';

void main() {
  group('PlayxPlatform.fromOperatingSystem', () {
    test('maps every supported operating system', () {
      expect(
        PlayxPlatform.fromOperatingSystem('android'),
        PlayxPlatform.android,
      );
      expect(PlayxPlatform.fromOperatingSystem('ios'), PlayxPlatform.ios);
      expect(PlayxPlatform.fromOperatingSystem('macos'), PlayxPlatform.macos);
      expect(
        PlayxPlatform.fromOperatingSystem('windows'),
        PlayxPlatform.windows,
      );
      expect(PlayxPlatform.fromOperatingSystem('linux'), PlayxPlatform.linux);
    });

    test('returns null for unsupported operating systems', () {
      expect(PlayxPlatform.fromOperatingSystem('fuchsia'), isNull);
      expect(PlayxPlatform.fromOperatingSystem(''), isNull);
    });
  });

  group('PlayxPlatformValue', () {
    const value = PlayxPlatformValue<String>(
      android: 'a',
      ios: 'i',
      macos: 'm',
      windows: 'w',
    );

    test('picks the value of each platform', () {
      expect(value.forPlatform(PlayxPlatform.android), 'a');
      expect(value.forPlatform(PlayxPlatform.ios), 'i');
      expect(value.forPlatform(PlayxPlatform.macos), 'm');
      expect(value.forPlatform(PlayxPlatform.windows), 'w');
      expect(value.forPlatform(PlayxPlatform.linux), isNull);
    });

    test('supports equality, hashCode and toString', () {
      const same = PlayxPlatformValue<String>(
        android: 'a',
        ios: 'i',
        macos: 'm',
        windows: 'w',
      );
      expect(value, same);
      expect(value.hashCode, same.hashCode);
      expect(value, isNot(const PlayxPlatformValue<String>(android: 'a')));
      expect(value.toString(), contains('windows: w'));
    });
  });

  group('PlayxPlatformVersion', () {
    test('supports every platform', () {
      const v = PlayxPlatformVersion(
        android: '1.0.0',
        ios: '2.0.0',
        macos: '3.0.0',
        windows: '4.0.0',
        linux: '5.0.0',
      );
      expect(v.forPlatform(PlayxPlatform.macos), '3.0.0');
      expect(v.forPlatform(PlayxPlatform.linux), '5.0.0');
    });

    test('is not equal to a plain PlayxPlatformValue with the same data', () {
      expect(
        const PlayxPlatformVersion(android: '1.0.0'),
        isNot(const PlayxPlatformValue<String>(android: '1.0.0')),
      );
    });

    test('can hold a different minimum version per platform', () {
      const min = PlayxPlatformVersion(android: '1.0.0', ios: '2.0.0');
      expect(min.forPlatform(PlayxPlatform.android), '1.0.0');
      expect(min.forPlatform(PlayxPlatform.ios), '2.0.0');
    });
  });
}

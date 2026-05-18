import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/src/core/version_checker/version.dart';

void main() {
  group('Version.parse', () {
    test('parses standard semver with pre-release and build metadata', () {
      final version = Version.parse('1.2.3-alpha.1+build.456');

      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.additionalComponents, isEmpty);
      expect(version.preRelease, 'alpha.1');
      expect(version.build, 'build.456');
      expect(version.toString(), '1.2.3-alpha.1+build.456');
    });

    test('normalizes missing numeric parts to zero', () {
      expect(Version.parse('1').toString(), '1.0.0');
      expect(Version.parse('1.2').toString(), '1.2.0');
    });

    test('supports additional numeric components', () {
      final version = Version.parse('519.0.0.44.92');

      expect(version.major, 519);
      expect(version.minor, 0);
      expect(version.patch, 0);
      expect(version.additionalComponents, [44, 92]);
      expect(version.toString(), '519.0.0.44.92');
    });

    test('ignores non-numeric core tags after numeric segments', () {
      final version = Version.parse('3.122.764106578.release');

      expect(version.major, 3);
      expect(version.minor, 122);
      expect(version.patch, 764106578);
      expect(version.additionalComponents, isEmpty);
      expect(version.preRelease, isEmpty);
      expect(version.build, isEmpty);
      expect(version.toString(), '3.122.764106578');
    });

    test('trims nothing and throws on empty input', () {
      expect(() => Version.parse(''), throwsFormatException);
      expect(() => Version.parse('   '), throwsFormatException);
    });

    test('rejects malformed pre-release metadata', () {
      expect(() => Version.parse('1.2.3-alpha..1'), throwsArgumentError);
    });

    test('remains permissive for non-numeric suffix noise in the core string',
        () {
      expect(Version.parse('1.2.3+build?1').toString(), '1.2.0');
      expect(Version.parse('not-a-version').toString(), '0.0.0-a-version');
    });
  });

  group('Version.tryParse', () {
    test('returns null only for inputs the parser truly rejects', () {
      expect(Version.tryParse(''), isNull);
      expect(Version.tryParse('1.2.3-alpha..1'), isNull);
    });

    test('keeps permissive parsing behavior for noisy inputs', () {
      expect(Version.tryParse('1.2.3+build?1')?.toString(), '1.2.0');
      expect(Version.tryParse('not-a-version')?.toString(), '0.0.0-a-version');
    });
  });

  group('Version comparison', () {
    test('compares additional numeric components', () {
      expect(Version.parse('1.2.3.4') > Version.parse('1.2.3'), isTrue);
      expect(Version.parse('1.2.3.4') < Version.parse('1.2.3.5'), isTrue);
      expect(Version.parse('1.2.3.0'), Version.parse('1.2.3'));
    });

    test('follows pre-release precedence rules implemented by the parser', () {
      expect(Version.parse('1.2.3-alpha') < Version.parse('1.2.3'), isTrue);
      expect(Version.parse('1.2.3-alpha.1') < Version.parse('1.2.3-alpha.beta'),
          isTrue);
      expect(Version.parse('1.2.3-alpha.2') > Version.parse('1.2.3-alpha.1'),
          isTrue);
      expect(Version.parse('1.2.3-alpha.beta') > Version.parse('1.2.3-alpha.1'),
          isTrue);
    });

    test('ignores build metadata when comparing precedence', () {
      expect(Version.parse('1.2.3+1'), Version.parse('1.2.3+2'));
      expect(Version.parse('1.2.3-alpha+1'), Version.parse('1.2.3-alpha+99'));
    });
  });

  group('Version increment helpers', () {
    test('increment major, minor, and patch reset lower-order parts', () {
      expect(
        Version.parse('1.2.3.4-alpha+9').incrementMajor().toString(),
        '2.0.0',
      );
      expect(
        Version.parse('1.2.3.4-alpha+9').incrementMinor().toString(),
        '1.3.0',
      );
      expect(
        Version.parse('1.2.3.4-alpha+9').incrementPatch().toString(),
        '1.2.4',
      );
    });

    test('incrementPreRelease updates the right-most numeric segment', () {
      expect(
        Version.parse('1.2.3-alpha.1').incrementPreRelease().toString(),
        '1.2.3-alpha.2',
      );
      expect(
        Version.parse('1.2.3-alpha').incrementPreRelease().toString(),
        '1.2.3-alpha.1',
      );
    });

    test('incrementPreRelease rejects stable versions', () {
      expect(
        () => Version.parse('1.2.3').incrementPreRelease(),
        throwsArgumentError,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/platform/playx_version_update_method_channel.dart';
import 'package:playx_version_update/src/platform/playx_version_update_platform_interface.dart';

/// Uses every default implementation of the interface.
class _Bare extends PlayxVersionUpdatePlatform {}

/// Implements the interface without extending it: not allowed.
class _Impostor implements PlayxVersionUpdatePlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('the default instance uses the method channel', () {
    expect(PlayxVersionUpdatePlatform.instance,
        isA<MethodChannelPlayxVersionUpdate>());
  });

  test('every default implementation is not supported', () async {
    final platform = _Bare();
    final results = [
      await platform.getUpdateAvailability(),
      await platform.getUpdateStalenessDays(),
      await platform.getUpdatePriority(),
      await platform.isUpdateAllowed(PlayxAppUpdateType.immediate),
      await platform.startImmediateUpdate(),
      await platform.startFlexibleUpdate(),
      await platform.completeFlexibleUpdate(),
      await platform.isFlexibleUpdateNeedToBeInstalled(),
      await platform.refreshInAppUpdate(),
    ];

    for (final result in results) {
      expect(result.updateError, isA<PlatformNotSupportedError>());
    }
    expect(await platform.getDownloadInfo().toList(), isEmpty);
  });

  group('instance', () {
    late PlayxVersionUpdatePlatform original;

    setUp(() => original = PlayxVersionUpdatePlatform.instance);
    tearDown(() => PlayxVersionUpdatePlatform.instance = original);

    test('can be replaced by a subclass', () {
      final fake = _Bare();
      PlayxVersionUpdatePlatform.instance = fake;
      expect(PlayxVersionUpdatePlatform.instance, same(fake));
    });

    test('rejects an implementation that does not extend the interface', () {
      expect(
        () => PlayxVersionUpdatePlatform.instance = _Impostor(),
        throwsA(anything),
      );
    });
  });
}

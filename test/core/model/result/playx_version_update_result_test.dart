import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/src/core/model/playx_platform_version.dart';
import 'package:playx_version_update/src/core/model/playx_version_update_info.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';

void main() {
  group('PlayxVersionUpdateResult success', () {
    const result = PlayxVersionUpdateResult<int>.success(42);

    test('exposes success state and updateData', () {
      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
      expect(result.updateData, 42);
      expect(result.updateError, isNull);
    });

    test('when invokes success callback', () {
      final message = result.when(
        success: (data) => 'ok:$data',
        error: (error) => 'error:${error.errorCode}',
      );

      expect(message, 'ok:42');
    });

    test('map transforms success values', () {
      final mapped = result.map<String>(
        success: (data) => PlayxVersionUpdateResult.success('value:$data'),
        error: PlayxVersionUpdateResult.error,
      );

      expect(mapped.isSuccess, isTrue);
      expect(mapped.updateData, 'value:42');
    });

    test('mapAsync transforms success values', () async {
      final mapped = await result.mapAsync<String>(
        success: (data) async =>
            PlayxVersionUpdateResult.success('value:$data'),
        error: (error) async => PlayxVersionUpdateResult.error(error),
      );

      expect(mapped.isSuccess, isTrue);
      expect(mapped.updateData, 'value:42');
    });
  });

  group('PlayxVersionUpdateResult error', () {
    final result = PlayxVersionUpdateResult<int>.error(
      const DefaultFailureError(errorMsg: 'failed'),
    );

    test('exposes error state and updateError', () {
      expect(result.isSuccess, isFalse);
      expect(result.isError, isTrue);
      expect(result.updateData, isNull);
      expect(result.updateError, isA<DefaultFailureError>());
      expect(result.updateError?.message, 'failed');
    });

    test('when invokes error callback', () {
      final message = result.when(
        success: (data) => 'ok:$data',
        error: (error) => 'error:${error.errorCode}',
      );

      expect(message, 'error:DEFAULT_FAILURE_ERROR');
    });

    test('map preserves error values', () {
      final mapped = result.map<String>(
        success: (data) => PlayxVersionUpdateResult.success('value:$data'),
        error: PlayxVersionUpdateResult.error,
      );

      expect(mapped.isError, isTrue);
      expect(mapped.updateError, isA<DefaultFailureError>());
    });

    test('mapAsync preserves error values', () async {
      final mapped = await result.mapAsync<String>(
        success: (data) async =>
            PlayxVersionUpdateResult.success('value:$data'),
        error: (error) async => PlayxVersionUpdateResult.error(error),
      );

      expect(mapped.isError, isTrue);
      expect(mapped.updateError, isA<DefaultFailureError>());
    });
  });

  group('PlayxVersionUpdateInfo with platform versions', () {
    test(
        'preserves raw platform versions while keeping effective generic fields',
        () {
      const newPlatformVersion = PlayxPlatformVersion(
        android: '2.0.0',
        ios: '3.0.0',
      );
      const minPlatformVersion = PlayxPlatformVersion(
        android: '1.5.0',
        ios: '2.5.0',
      );

      const info = PlayxVersionUpdateInfo(
        localVersion: '1.0.0',
        newVersion: '2.0.0',
        canUpdate: true,
        forceUpdate: true,
        storeUrl: 'https://example.com',
        minVersion: '1.5.0',
        newPlatformVersion: newPlatformVersion,
        minPlatformVersion: minPlatformVersion,
      );

      expect(info.newVersion, '2.0.0');
      expect(info.minVersion, '1.5.0');
      expect(info.newPlatformVersion, newPlatformVersion);
      expect(info.minPlatformVersion, minPlatformVersion);
      expect(
        info.toString(),
        contains('newPlatformVersion: $newPlatformVersion'),
      );
      expect(
        info.toString(),
        contains('minPlatformVersion: $minPlatformVersion'),
      );
    });
  });
}

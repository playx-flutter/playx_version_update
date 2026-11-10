import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';

PlayxVersionUpdateInfo _info({String newVersion = '2.0.0'}) =>
    PlayxVersionUpdateInfo(
      localVersion: '1.0.0',
      newVersion: newVersion,
      canUpdate: true,
      forceUpdate: false,
      storeUrl: 'https://store',
      country: 'us',
      releaseNotes: 'notes',
      minVersion: '1.0.0',
    );

void main() {
  group('PlayxVersionUpdateInfo', () {
    test('supports equality, hashCode and toString', () {
      expect(_info(), _info());
      expect(_info().hashCode, _info().hashCode);
      expect(_info(), isNot(_info(newVersion: '3.0.0')));
      expect(_info().toString(), contains('newVersion: 2.0.0'));
      expect(_info().toString(), contains('storeUrl: https://store'));
    });

    test('compares the per-platform values', () {
      const a = PlayxPlatformVersion(android: '1.0.0');
      final withValues = PlayxVersionUpdateInfo(
        localVersion: '1.0.0',
        newVersion: '2.0.0',
        canUpdate: true,
        forceUpdate: false,
        storeUrl: 'https://store',
        newPlatformVersion: a,
      );
      final same = PlayxVersionUpdateInfo(
        localVersion: '1.0.0',
        newVersion: '2.0.0',
        canUpdate: true,
        forceUpdate: false,
        storeUrl: 'https://store',
        newPlatformVersion: a,
      );

      expect(withValues, same);
      expect(withValues, isNot(_info()));
    });
  });

  group('PlayxRemoteVersionInfo', () {
    test('keeps its values and prints them', () {
      const info = PlayxRemoteVersionInfo(
        version: '1.0.0',
        minVersion: '0.9.0',
        releaseNotes: 'notes',
        storeUrl: 'https://store',
      );
      expect(info.version, '1.0.0');
      expect(info.toString(), contains('minVersion: 0.9.0'));
      expect(info.toString(), contains('storeUrl: https://store'));
    });
  });

  group('PlayxVersionRequest', () {
    test('tells the platform', () {
      PlayxVersionRequest request(PlayxPlatform platform) => PlayxVersionRequest(
            platform: platform,
            packageId: 'a.b',
            country: 'us',
            language: 'en',
          );

      expect(request(PlayxPlatform.android).isAndroid, isTrue);
      expect(request(PlayxPlatform.android).isIos, isFalse);
      expect(request(PlayxPlatform.ios).isIos, isTrue);
      expect(request(PlayxPlatform.macos).isAndroid, isFalse);
      expect(request(PlayxPlatform.macos).isIos, isFalse);
    });
  });

  group('PlayxVersionUpdateResult', () {
    test('success and error report their state', () {
      const ok = PlayxVersionUpdateResult<int>.success(1);
      final failed =
          PlayxVersionUpdateResult<int>.error(DefaultFailureError());

      expect(ok.isSuccess, isTrue);
      expect(ok.isError, isFalse);
      expect(ok.updateData, 1);
      expect(ok.updateError, isNull);
      expect(failed.isError, isTrue);
      expect(failed.updateData, isNull);
      expect(failed.updateError, isA<DefaultFailureError>());
    });

    test('when, map and mapAsync pick the right branch', () async {
      const ok = PlayxVersionUpdateResult<int>.success(2);
      const failed = PlayxVersionUpdateResult<int>.error(NotSupportedException());

      expect(ok.when(success: (v) => 'ok$v', error: (e) => 'error'), 'ok2');
      expect(failed.when(success: (v) => 'ok', error: (e) => e.errorCode),
          'NOT_SUPPORTED_ERROR_CODE');

      expect(
        ok.map<String>(
          success: (v) => PlayxVersionUpdateResult.success('$v!'),
          error: PlayxVersionUpdateResult.error,
        ).updateData,
        '2!',
      );
      expect(
        failed.map<String>(
          success: (v) => PlayxVersionUpdateResult.success('$v!'),
          error: PlayxVersionUpdateResult.error,
        ).updateError,
        isA<NotSupportedException>(),
      );
      expect(
        (await ok.mapAsync<String>(
          success: (v) async => PlayxVersionUpdateResult.success('$v?'),
          error: (e) async => PlayxVersionUpdateResult.error(e),
        )).updateData,
        '2?',
      );
      expect(
        (await failed.mapAsync<String>(
          success: (v) async => PlayxVersionUpdateResult.success('$v?'),
          error: (e) async => PlayxVersionUpdateResult.error(e),
        )).updateError,
        isA<NotSupportedException>(),
      );
    });

    test('copyWith replaces the data or the error', () {
      const ok = PlayxVersionUpdateSuccessResult<int>(1);
      expect(ok.copyWith(data: 5).data, 5);
      expect(ok.copyWith().data, 1);

      final failed = PlayxVersionUpdateErrorResult<int>(DefaultFailureError());
      expect(failed.copyWith(error: const NotSupportedException()).error,
          isA<NotSupportedException>());
      expect(failed.copyWith().error, isA<DefaultFailureError>());
    });
  });

  group('errors', () {
    test('every error has a message and a stable code', () {
      final errors = <PlayxVersionUpdateError>[
        PlatformNotSupportedError(),
        ActivityNotFoundError(),
        AppUpdateMangerNotFoundError(),
        PlayxInAppUpdateCanceledError(),
        PlayxInAppUpdateFailedError(),
        const DefaultFailureError(),
        const NotSupportedException(),
        const VersionFormatException(),
        const PlayxVersionCantUpdateError(
            currentVersion: '2.0.0', newVersion: '1.0.0'),
        const InstallApiNotAvailableError(),
        const InstallAppNotOwnedError(),
        const InstallDownloadNotPresentError(),
        const InstallInProgressError(),
        const InstallNotAllowedError(),
        const InstallUnavailableError(),
        const InstallInternalError(),
        const InstallInvalidRequestError(),
        const InstallPlayStoreNotFoundError(),
        const PlayxVersionNetworkError(NoInternetConnectionException()),
      ];

      for (final error in errors) {
        expect(error.message, isNotEmpty, reason: '${error.runtimeType}');
        expect(error.errorCode, isNotEmpty, reason: '${error.runtimeType}');
      }
      expect(errors.map((e) => e.errorCode).toSet().length, errors.length,
          reason: 'codes are unique');
    });

    test('install codes map to their error', () {
      const codes = {
        'INSTALL_API_NOT_AVAILABLE': InstallApiNotAvailableError,
        'INSTALL_APP_NOT_OWNED': InstallAppNotOwnedError,
        'INSTALL_DOWNLOAD_NOT_PRESENT': InstallDownloadNotPresentError,
        'INSTALL_IN_PROGRESS': InstallInProgressError,
        'INSTALL_NOT_ALLOWED': InstallNotAllowedError,
        'INSTALL_UNAVAILABLE': InstallUnavailableError,
        'INSTALL_INTERNAL_ERROR': InstallInternalError,
        'INSTALL_INVALID_REQUEST': InstallInvalidRequestError,
        'INSTALL_PLAY_STORE_NOT_FOUND': InstallPlayStoreNotFoundError,
      };

      codes.forEach((code, type) {
        final error = PlayxVersionUpdateError.fromInAppUpdateErrorCode(code, 'm');
        expect(error.runtimeType, type, reason: code);
        expect(error.errorCode, code);
      });
    });

    test('unknown install codes keep their code and message', () {
      final known = PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'INSTALL_UNKNOWN_ERROR', 'something');
      expect(known, isA<InstallUnknownError>());
      expect(known.message, 'something');

      final other = PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'INSTALL_FUTURE_CODE', 'new');
      expect(other, isA<InstallUnknownError>());
      expect(other.errorCode, 'INSTALL_FUTURE_CODE');
    });

    test('general codes map to their error', () {
      PlayxVersionUpdateError map(String code) =>
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(code, 'm');

      expect(map('ACTIVITY_NOT_FOUND'), isA<ActivityNotFoundError>());
      expect(map('APP_UPDATE_MANGER_NOT_FOUND'),
          isA<AppUpdateMangerNotFoundError>());
      expect(map('PLAYX_UPDATE_CANCELLED'), isA<PlayxInAppUpdateCanceledError>());
      expect(map('PLAYX_INFO_REQUEST_CANCELLED'),
          isA<PlayxInAppUpdateCanceledError>());
      expect(map('PLAYX_IN_APP_UPDATE_FAILED'), isA<PlayxInAppUpdateFailedError>());
      expect(map('PLATFORM_NOT_SUPPORTED_ERROR'), isA<PlatformNotSupportedError>());
      expect(map('DEFAULT_FAILURE_ERROR').message, 'm');
      expect(map('SOMETHING_ELSE').message, 'm');
    });

    test('the network error exposes the code and the status', () {
      const notFound = PlayxVersionNetworkError(NotFoundException());
      expect(notFound.errorCode, 'NETWORK_NOT_FOUND');
      expect(notFound.statusCode, 404);
      expect(notFound.message, isNotEmpty);

      const offline = PlayxVersionNetworkError(NoInternetConnectionException());
      expect(offline.statusCode, isNull);
    });

    test('the cannot-update error mentions both versions', () {
      const error = PlayxVersionCantUpdateError(
          currentVersion: '2.0.0', newVersion: '1.0.0');
      expect(error.message, contains('2.0.0'));
      expect(error.message, contains('1.0.0'));
    });
  });

  group('storage', () {
    test('the in-memory storage reads, writes and removes values', () async {
      final storage = PlayxInMemoryUpdateStorage();

      expect(await storage.read('k'), isNull);
      await storage.write('k', 'v');
      expect(await storage.read('k'), 'v');
      await storage.remove('k');
      expect(await storage.read('k'), isNull);
    });

    test('the shared storage is one instance', () {
      expect(PlayxInMemoryUpdateStorage.shared,
          same(PlayxInMemoryUpdateStorage.shared));
    });
  });

  group('options defaults', () {
    test('the update options use the documented defaults', () {
      const options = PlayxUpdateOptions();
      expect(options.country, 'us');
      expect(options.language, 'en');
      expect(options.enableNetworkLogging, isFalse);
      expect(options.versionSource, isNull);
      expect(options.networkOptions.maxRetries, 1);
    });

    test('the UI options use the documented defaults', () {
      const options = PlayxUpdateUIOptions();
      expect(options.updateButtonText, 'Update');
      expect(options.showReleaseNotes, isFalse);
      expect(options.preferStoreApp, isTrue);
      expect(options.showDismissButtonOnForceUpdate, isTrue);
      expect(options.displayType, PlayxUpdateDisplayType.pageOnForceUpdate);
      expect(options.isDismissible, isNull);
    });

    test('the network options use the documented defaults', () {
      const options = PlayxNetworkOptions();
      expect(options.maxRetries, 1);
      expect(options.retryDelay, const Duration(seconds: 1));
      expect(options.dio, isNull);
      expect(options.cancelToken, isNull);
    });
  });
}

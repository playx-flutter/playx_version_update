import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';

void main() {
  group('PlayxVersionUpdateError.fromInAppUpdateErrorCode', () {
    test('maps general known error codes', () {
      expect(
        PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'ACTIVITY_NOT_FOUND',
          'ignored',
        ),
        isA<ActivityNotFoundError>(),
      );
      expect(
        PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'APP_UPDATE_MANGER_NOT_FOUND',
          'ignored',
        ),
        isA<AppUpdateMangerNotFoundError>(),
      );
      expect(
        PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'PLAYX_INFO_REQUEST_CANCELLED',
          'ignored',
        ),
        isA<PlayxInAppUpdateCanceledError>(),
      );
      expect(
        PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'PLAYX_UPDATE_CANCELLED',
          'ignored',
        ),
        isA<PlayxInAppUpdateCanceledError>(),
      );
      expect(
        PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'PLAYX_IN_APP_UPDATE_FAILED',
          'ignored',
        ),
        isA<PlayxInAppUpdateFailedError>(),
      );
      expect(
        PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'PLATFORM_NOT_SUPPORTED_ERROR',
          'ignored',
        ),
        isA<PlatformNotSupportedError>(),
      );
    });

    test('maps install-prefixed codes to install errors', () {
      expect(
        PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'INSTALL_API_NOT_AVAILABLE',
          'ignored',
        ),
        isA<InstallApiNotAvailableError>(),
      );
      expect(
        PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'INSTALL_DOWNLOAD_NOT_PRESENT',
          'ignored',
        ),
        isA<InstallDownloadNotPresentError>(),
      );
      expect(
        PlayxVersionUpdateError.fromInAppUpdateErrorCode(
          'INSTALL_UNKNOWN_ERROR',
          'custom message',
        ),
        isA<InstallUnknownError>(),
      );
    });

    test('falls back to default failure for unknown non-install codes', () {
      final error = PlayxVersionUpdateError.fromInAppUpdateErrorCode(
        'SOMETHING_NEW',
        'custom message',
      );

      expect(error, isA<DefaultFailureError>());
      expect(error.errorCode, 'DEFAULT_FAILURE_ERROR');
      expect(error.message, 'custom message');
    });
  });

  group('DefaultFailureError', () {
    test('uses fallback message when no message is provided', () {
      const error = DefaultFailureError();

      expect(error.errorCode, 'DEFAULT_FAILURE_ERROR');
      expect(error.message, 'An unknown error occurred. Please try again.');
    });
  });

  group('PlayxVersionCantUpdateError', () {
    test('includes both versions in the message', () {
      const error = PlayxVersionCantUpdateError(
        currentVersion: '2.0.0',
        newVersion: '1.0.0',
      );

      expect(error.errorCode, 'PLAYX_VERSION_CANT_UPDATE_ERROR_CODE');
      expect(error.message, contains('2.0.0'));
      expect(error.message, contains('1.0.0'));
    });
  });
}

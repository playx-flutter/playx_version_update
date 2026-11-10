import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';

void main() {
  group('PlayxDownloadInfo.fromJson', () {
    test('reads every field', () {
      final info = PlayxDownloadInfo.fromJson(
        '{"status":2,"bytesDownloaded":10,"totalBytesToDownload":100,'
        '"installErrorCode":-3}',
      );

      expect(info.status, PlayxDownloadStatus.downloading);
      expect(info.bytesDownloaded, 10);
      expect(info.totalBytesToDownload, 100);
      expect(info.installErrorCode, -3);
      expect(info.toString(), contains('totalBytesToDownload :100'));
    });

    test('reads missing and null numbers as 0', () {
      final info = PlayxDownloadInfo.fromJson('{"status":1,"bytesDownloaded":null}');
      expect(info.bytesDownloaded, 0);
      expect(info.totalBytesToDownload, 0);
      expect(info.installErrorCode, 0);
    });

    test('accepts numbers sent as doubles', () {
      final info = PlayxDownloadInfo.fromJson(
          '{"status":2.0,"bytesDownloaded":5.0,"totalBytesToDownload":9.0}');
      expect(info.status, PlayxDownloadStatus.downloading);
      expect(info.bytesDownloaded, 5);
    });

    test('rejects text that is not a JSON object', () {
      expect(() => PlayxDownloadInfo.fromJson('nope'), throwsFormatException);
    });
  });

  group('PlayxDownloadStatus.from', () {
    test('maps every index and falls back to unknown', () {
      for (final status in PlayxDownloadStatus.values) {
        expect(PlayxDownloadStatus.from(status.index), status);
      }
      expect(PlayxDownloadStatus.from(null), PlayxDownloadStatus.unknown);
      expect(PlayxDownloadStatus.from(100), PlayxDownloadStatus.unknown);
    });
  });

  group('PlayxAppUpdateAvailability.fromUpdateAvailability', () {
    test('maps every index and falls back to unknown', () {
      for (final value in PlayxAppUpdateAvailability.values) {
        expect(PlayxAppUpdateAvailability.fromUpdateAvailability(value.index),
            value);
      }
      expect(PlayxAppUpdateAvailability.fromUpdateAvailability(null),
          PlayxAppUpdateAvailability.unknown);
      expect(PlayxAppUpdateAvailability.fromUpdateAvailability(100),
          PlayxAppUpdateAvailability.unknown);
    });
  });
}

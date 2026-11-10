import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/platform/playx_version_update_method_channel.dart';

const _channel = MethodChannel('PLAYX_METHOD_CHANNEL_NAME');
const _events = EventChannel('DOWNLOAD_EVENT_CHANNEL_NAME');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final platform = MethodChannelPlayxVersionUpdate();
  late List<MethodCall> calls;

  void handle(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(_channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls = [];
    PlayxPlatform.debugSetCurrent(PlayxPlatform.android);
  });

  tearDown(() {
    PlayxPlatform.debugResetCurrent();
    messenger.setMockMethodCallHandler(_channel, null);
    messenger.setMockStreamHandler(_events, null);
  });

  group('on platforms without the native side', () {
    for (final target in [
      PlayxPlatform.ios,
      PlayxPlatform.macos,
      PlayxPlatform.windows,
      null,
    ]) {
      test('every call is not supported on ${target?.name ?? 'web'}', () async {
        PlayxPlatform.debugSetCurrent(target);
        handle((_) async => true);

        final results = [
          await platform.getUpdateAvailability(),
          await platform.getUpdateStalenessDays(),
          await platform.getUpdatePriority(),
          await platform.isUpdateAllowed(PlayxAppUpdateType.flexible),
          await platform.startImmediateUpdate(),
          await platform.startFlexibleUpdate(),
          await platform.completeFlexibleUpdate(),
          await platform.isFlexibleUpdateNeedToBeInstalled(),
          await platform.refreshInAppUpdate(),
        ];

        for (final result in results) {
          expect(result.updateError, isA<PlatformNotSupportedError>());
        }
        expect(calls, isEmpty, reason: 'the native side is never called');
        expect(await platform.getDownloadInfo().toList(), isEmpty);
      });
    }
  });

  group('on Android', () {
    test('getUpdateAvailability maps the native index', () async {
      handle((_) async => 2);
      expect((await platform.getUpdateAvailability()).updateData,
          PlayxAppUpdateAvailability.available);
      expect(calls.single.method, 'GET_UPDATE_AVAILABILITY');
    });

    test('getUpdateAvailability is unknown for null or unknown indexes',
        () async {
      handle((_) async => null);
      expect((await platform.getUpdateAvailability()).updateData,
          PlayxAppUpdateAvailability.unknown);

      handle((_) async => 99);
      expect((await platform.getUpdateAvailability()).updateData,
          PlayxAppUpdateAvailability.unknown);
    });

    test('staleness days and priority default to -1', () async {
      handle((_) async => null);
      expect((await platform.getUpdateStalenessDays()).updateData, -1);
      expect((await platform.getUpdatePriority()).updateData, -1);

      handle((_) async => 7);
      expect((await platform.getUpdateStalenessDays()).updateData, 7);
      expect((await platform.getUpdatePriority()).updateData, 7);
    });

    test('isUpdateAllowed sends the update type', () async {
      handle((_) async => true);

      expect((await platform.isUpdateAllowed(PlayxAppUpdateType.immediate))
          .updateData, isTrue);
      expect(calls.single.method, 'IS_UPDATE_ALLOWED');
      expect(calls.single.arguments,
          {'IS_UPDATE_ALLOWED_TYPE_KEY': PlayxAppUpdateType.immediate.index});
    });

    test('boolean calls return the native value and default to false',
        () async {
      final calls = <String, Future<PlayxVersionUpdateResult<bool>> Function()>{
        'START_IMMEDIATE_UPDATE': platform.startImmediateUpdate,
        'START_FLEXIBLE_UPDATE': platform.startFlexibleUpdate,
        'COMPLETE_FLEXIBLE_UPDATE': platform.completeFlexibleUpdate,
        'IS_FLEXIBLE_UPDATE_NEED_TO_BE_INSTALLED':
            platform.isFlexibleUpdateNeedToBeInstalled,
        'REFRESH_PLAYX_UPDATE': platform.refreshInAppUpdate,
      };

      for (final entry in calls.entries) {
        handle((call) async => call.method == entry.key ? true : null);
        expect((await entry.value()).updateData, isTrue, reason: entry.key);

        handle((_) async => null);
        expect((await entry.value()).updateData, isFalse, reason: entry.key);
      }
    });

    test('platform errors are mapped to update errors', () async {
      handle((_) async => throw PlatformException(code: 'ACTIVITY_NOT_FOUND'));
      expect((await platform.startImmediateUpdate()).updateError,
          isA<ActivityNotFoundError>());

      handle((_) async =>
          throw PlatformException(code: 'PLAYX_UPDATE_CANCELLED'));
      expect((await platform.startFlexibleUpdate()).updateError,
          isA<PlayxInAppUpdateCanceledError>());

      handle((_) async => throw PlatformException(
          code: 'INSTALL_NOT_ALLOWED', message: 'low storage'));
      final error = (await platform.completeFlexibleUpdate()).updateError;
      expect(error, isA<PlayxInstallError>());
      expect(error!.errorCode, 'INSTALL_NOT_ALLOWED');

      handle((_) async => throw PlatformException(code: 'WHO_KNOWS'));
      expect((await platform.getUpdatePriority()).updateError,
          isA<DefaultFailureError>());
    });

    test('a missing native implementation is a default failure', () async {
      messenger.setMockMethodCallHandler(_channel, null);
      final error = (await platform.getUpdateAvailability()).updateError;
      expect(error, isA<DefaultFailureError>());
    });

    test('any other exception is a default failure', () async {
      handle((_) async => throw const FormatException('bad'));
      final error = (await platform.refreshInAppUpdate()).updateError;
      expect(error, isA<DefaultFailureError>());
      expect(error!.message, contains('bad'));
    });
  });

  group('download events', () {
    PlayxDownloadInfo info(int status) => PlayxDownloadInfo(
          status: PlayxDownloadStatus.from(status),
          bytesDownloaded: 0,
          totalBytesToDownload: 0,
          installErrorCode: 0,
        );

    test('are parsed, with empty and malformed events as null', () async {
      messenger.setMockStreamHandler(
        _events,
        MockStreamHandler.inline(onListen: (_, sink) {
          sink.success('{"status":2,"bytesDownloaded":10,'
              '"totalBytesToDownload":100,"installErrorCode":0}');
          sink.success('');
          sink.success('not json');
          sink.success(
              '{"status":3,"bytesDownloaded":100,"totalBytesToDownload":100}');
          sink.endOfStream();
        }),
      );

      final events = await platform.getDownloadInfo().toList();

      expect(events, hasLength(4));
      expect(events[0]!.status, PlayxDownloadStatus.downloading);
      expect(events[0]!.bytesDownloaded, 10);
      expect(events[0]!.totalBytesToDownload, 100);
      expect(events[1], isNull);
      expect(events[2], isNull);
      expect(events[3]!.status, PlayxDownloadStatus.downloaded);
      expect(events[3]!.installErrorCode, 0);
      expect(info(3).status, PlayxDownloadStatus.downloaded);
    });
  });
}

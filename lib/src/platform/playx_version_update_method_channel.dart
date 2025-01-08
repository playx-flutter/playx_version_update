import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:playx_version_update/playx_version_update.dart';

import 'playx_version_update_platform_interface.dart';

const String _playxMethodChannelName = "PLAYX_METHOD_CHANNEL_NAME";
const String _downloadEventChannelName = "DOWNLOAD_EVENT_CHANNEL_NAME";

const String _getUpdateAvailability = "GET_UPDATE_AVAILABILITY";

const String _getUpdateStalenessDays = "GET_UPDATE_STALENESS_DAYS";

const String _getUpdatePriority = "GET_UPDATE_PRIORITY";

const String _isUpdateAllowed = "IS_UPDATE_ALLOWED";
const String _isUpdateAllowedTypeKey = "IS_UPDATE_ALLOWED_TYPE_KEY";

const String _startImmediateUpdate = "START_IMMEDIATE_UPDATE";
const String _startFlexibleUpdate = "START_FLEXIBLE_UPDATE";

const String _completeFlexibleUpdate = "COMPLETE_FLEXIBLE_UPDATE";

const String _isFlexibleUpdateNeedToBeInstalled =
    "IS_FLEXIBLE_UPDATE_NEED_TO_BE_INSTALLED";

const String _refreshPlayxUpdate = "REFRESH_PLAYX_UPDATE";

/// An implementation of [PlayxVersionUpdatePlatform] that uses method channels.
class MethodChannelPlayxVersionUpdate extends PlayxVersionUpdatePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(_playxMethodChannelName);

  final downloadEventChannel = const EventChannel(_downloadEventChannelName);

  @override
  Future<PlayxVersionUpdateResult<PlayxAppUpdateAvailability>>
      getUpdateAvailability() async {
    if (kIsWeb || !Platform.isAndroid) {
      return PlayxVersionUpdateResult<PlayxAppUpdateAvailability>.error(
          PlatformNotSupportedError());
    }
    try {
      final index =
          await methodChannel.invokeMethod<num>(_getUpdateAvailability);
      final availability =
          PlayxAppUpdateAvailability.fromUpdateAvailability(index);
      return PlayxVersionUpdateResult.success(availability);
    } on PlatformException catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              e.code, e.message ?? ''));
    } on Exception catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              defaultFailureErrorCode, e.toString()));
    }
  }

  @override
  Future<PlayxVersionUpdateResult<int>> getUpdateStalenessDays() async {
    if (kIsWeb || !Platform.isAndroid) {
      return PlayxVersionUpdateResult<int>.error(PlatformNotSupportedError());
    }

    try {
      final days =
          await methodChannel.invokeMethod<int>(_getUpdateStalenessDays) ?? -1;
      return PlayxVersionUpdateResult.success(days);
    } on PlatformException catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              e.code, e.message ?? ''));
    } on Exception catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              defaultFailureErrorCode, e.toString()));
    }
  }

  @override
  Future<PlayxVersionUpdateResult<int>> getUpdatePriority() async {
    if (kIsWeb || !Platform.isAndroid) {
      return PlayxVersionUpdateResult<int>.error(PlatformNotSupportedError());
    }

    try {
      final priority =
          await methodChannel.invokeMethod<int>(_getUpdatePriority) ?? -1;
      return PlayxVersionUpdateResult.success(priority);
    } on PlatformException catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              e.code, e.message ?? ''));
    } on Exception catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              defaultFailureErrorCode, e.toString()));
    }
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> isUpdateAllowed(
      PlayxAppUpdateType type) async {
    if (kIsWeb || !Platform.isAndroid) {
      return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
    }

    try {
      final isAllowed =
          await methodChannel.invokeMethod<bool>(_isUpdateAllowed, {
                _isUpdateAllowedTypeKey: type.index,
              }) ??
              false;
      return PlayxVersionUpdateResult.success(isAllowed);
    } on PlatformException catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              e.code, e.message ?? ''));
    } on Exception catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              defaultFailureErrorCode, e.toString()));
    }
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> startImmediateUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
    }

    try {
      final isStarted =
          await methodChannel.invokeMethod<bool>(_startImmediateUpdate) ??
              false;
      return PlayxVersionUpdateResult.success(isStarted);
    } on PlatformException catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              e.code, e.message ?? ''));
    } on Exception catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              defaultFailureErrorCode, e.toString()));
    }
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> startFlexibleUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
    }

    try {
      final isStarted =
          await methodChannel.invokeMethod<bool>(_startFlexibleUpdate) ?? false;
      return PlayxVersionUpdateResult.success(isStarted);
    } on PlatformException catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              e.code, e.message ?? ''));
    } on Exception catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              defaultFailureErrorCode, e.toString()));
    }
  }

  @override
  Stream<PlayxDownloadInfo?> getDownloadInfo() {
    if (kIsWeb || !Platform.isAndroid) {
      return const Stream.empty();
    }
    return downloadEventChannel.receiveBroadcastStream().distinct().map((info) {
      if (info is String && info.isNotEmpty) {
        return PlayxDownloadInfo.fromJson(info);
      }
      return null;
    });
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> completeFlexibleUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
    }

    try {
      final isCompleted =
          await methodChannel.invokeMethod<bool>(_completeFlexibleUpdate) ??
              false;
      return PlayxVersionUpdateResult.success(isCompleted);
    } on PlatformException catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              e.code, e.message ?? ''));
    } on Exception catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              defaultFailureErrorCode, e.toString()));
    }
  }

  @override
  Future<PlayxVersionUpdateResult<bool>>
      isFlexibleUpdateNeedToBeInstalled() async {
    if (kIsWeb || !Platform.isAndroid) {
      return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
    }

    try {
      final isNeeded = await methodChannel
              .invokeMethod<bool>(_isFlexibleUpdateNeedToBeInstalled) ??
          false;

      return PlayxVersionUpdateResult.success(isNeeded);
    } on PlatformException catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              e.code, e.message ?? ''));
    } on Exception catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              defaultFailureErrorCode, e.toString()));
    }
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> refreshInAppUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return PlayxVersionUpdateResult<bool>.error(PlatformNotSupportedError());
    }

    try {
      final isRefreshed =
          await methodChannel.invokeMethod<bool>(_refreshPlayxUpdate) ?? false;
      return PlayxVersionUpdateResult.success(isRefreshed);
    } on PlatformException catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              e.code, e.message ?? ''));
    } on Exception catch (e) {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromInAppUpdateErrorCode(
              defaultFailureErrorCode, e.toString()));
    }
  }
}

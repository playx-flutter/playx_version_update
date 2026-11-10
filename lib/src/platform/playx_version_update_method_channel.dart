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
///
/// The native side only exists on Android; on every other platform each call
/// returns a [PlatformNotSupportedError].
class MethodChannelPlayxVersionUpdate extends PlayxVersionUpdatePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(_playxMethodChannelName);

  final downloadEventChannel = const EventChannel(_downloadEventChannelName);

  bool get _isAndroid => PlayxPlatform.current == PlayxPlatform.android;

  /// Calls [method] on the native side and turns the outcome into a result.
  ///
  /// [map] converts the native value (possibly `null`) to the result value.
  Future<PlayxVersionUpdateResult<R>> _call<T, R>(
    String method,
    R Function(T? value) map, {
    Object? arguments,
  }) async {
    if (!_isAndroid) {
      return PlayxVersionUpdateResult<R>.error(PlatformNotSupportedError());
    }

    try {
      final value = await methodChannel.invokeMethod<T>(method, arguments);
      return PlayxVersionUpdateResult.success(map(value));
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
  Future<PlayxVersionUpdateResult<PlayxAppUpdateAvailability>>
      getUpdateAvailability() {
    return _call<num, PlayxAppUpdateAvailability>(
      _getUpdateAvailability,
      PlayxAppUpdateAvailability.fromUpdateAvailability,
    );
  }

  @override
  Future<PlayxVersionUpdateResult<int>> getUpdateStalenessDays() {
    return _call<int, int>(_getUpdateStalenessDays, (days) => days ?? -1);
  }

  @override
  Future<PlayxVersionUpdateResult<int>> getUpdatePriority() {
    return _call<int, int>(_getUpdatePriority, (priority) => priority ?? -1);
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> isUpdateAllowed(
      PlayxAppUpdateType type) {
    return _call<bool, bool>(
      _isUpdateAllowed,
      (isAllowed) => isAllowed ?? false,
      arguments: {_isUpdateAllowedTypeKey: type.index},
    );
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> startImmediateUpdate() {
    return _call<bool, bool>(
        _startImmediateUpdate, (isStarted) => isStarted ?? false);
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> startFlexibleUpdate() {
    return _call<bool, bool>(
        _startFlexibleUpdate, (isStarted) => isStarted ?? false);
  }

  @override
  Stream<PlayxDownloadInfo?> getDownloadInfo() {
    if (!_isAndroid) {
      return const Stream.empty();
    }
    return downloadEventChannel.receiveBroadcastStream().distinct().map((info) {
      if (info is String && info.isNotEmpty) {
        try {
          return PlayxDownloadInfo.fromJson(info);
        } catch (_) {
          // A malformed event must not break the stream.
          return null;
        }
      }
      return null;
    });
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> completeFlexibleUpdate() {
    return _call<bool, bool>(
        _completeFlexibleUpdate, (isCompleted) => isCompleted ?? false);
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> isFlexibleUpdateNeedToBeInstalled() {
    return _call<bool, bool>(
        _isFlexibleUpdateNeedToBeInstalled, (isNeeded) => isNeeded ?? false);
  }

  @override
  Future<PlayxVersionUpdateResult<bool>> refreshInAppUpdate() {
    return _call<bool, bool>(
        _refreshPlayxUpdate, (isRefreshed) => isRefreshed ?? false);
  }
}

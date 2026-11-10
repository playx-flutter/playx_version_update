import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';
import 'package:playx_version_update/src/core/network/exceptions/network_exception.dart';

import 'playx_remote_version_info.dart';
import 'playx_version_request.dart';
import 'playx_version_source.dart';

/// A [PlayxVersionSource] backed by a function: the shortest way to read
/// versions from Firebase Remote Config or your own API.
///
/// ```dart
/// PlayxUpdateOptions(
///   versionSource: PlayxCallbackVersionSource((request) async {
///     final config = FirebaseRemoteConfig.instance;
///     await config.fetchAndActivate();
///     return PlayxRemoteVersionInfo(
///       version: config.getString('latest_version'),
///       minVersion: config.getString('min_version'),
///       storeUrl: config.getString('store_url'),
///     );
///   }),
/// )
/// ```
///
/// A thrown [NetworkException] is reported as a `PlayxVersionNetworkError`,
/// any other error as a `DefaultFailureError`.
class PlayxCallbackVersionSource implements PlayxVersionSource {
  final Future<PlayxRemoteVersionInfo> Function(PlayxVersionRequest request)
  _fetch;

  const PlayxCallbackVersionSource(this._fetch);

  @override
  Future<PlayxVersionUpdateResult<PlayxRemoteVersionInfo>> fetch(
    PlayxVersionRequest request,
  ) async {
    try {
      return PlayxVersionUpdateResult.success(await _fetch(request));
    } on NetworkException catch (e) {
      return PlayxVersionUpdateResult.error(PlayxVersionNetworkError(e));
    } catch (e) {
      return PlayxVersionUpdateResult.error(
        DefaultFailureError(errorMsg: 'Version source failed: $e'),
      );
    }
  }
}

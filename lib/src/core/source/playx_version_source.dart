import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';

import 'playx_remote_version_info.dart';
import 'playx_version_request.dart';

/// Where the latest app version comes from.
///
/// By default the package reads it from Google Play / the App Store
/// ([PlayxStoreVersionSource]). Provide your own through
/// `PlayxUpdateOptions.versionSource` to use Firebase Remote Config or your
/// own backend, or combine several with [PlayxFallbackVersionSource].
///
/// Values set directly in `PlayxUpdateOptions` (`newVersion`, `minVersion`,
/// the platform overrides and `forceUpdate`) always win over a source.
abstract interface class PlayxVersionSource {
  /// Returns the version information for [request], or an error.
  Future<PlayxVersionUpdateResult<PlayxRemoteVersionInfo>> fetch(
    PlayxVersionRequest request,
  );
}

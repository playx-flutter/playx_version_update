import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';

import 'playx_remote_version_info.dart';
import 'playx_version_request.dart';
import 'playx_version_source.dart';

/// Tries [sources] in order and uses the first one that succeeds.
///
/// ```dart
/// versionSource: PlayxFallbackVersionSource([
///   PlayxCallbackVersionSource(fetchFromMyBackend),
///   PlayxStoreVersionSource(), // used if the backend fails
/// ])
/// ```
///
/// If every source fails, the last error is returned.
class PlayxFallbackVersionSource implements PlayxVersionSource {
  final List<PlayxVersionSource> sources;

  const PlayxFallbackVersionSource(this.sources);

  @override
  Future<PlayxVersionUpdateResult<PlayxRemoteVersionInfo>> fetch(
    PlayxVersionRequest request,
  ) async {
    PlayxVersionUpdateError? lastError;
    for (final source in sources) {
      final result = await source.fetch(request);
      if (result.isSuccess) return result;
      lastError = result.updateError;
    }
    return PlayxVersionUpdateResult.error(
      lastError ??
          const DefaultFailureError(errorMsg: 'No version source configured.'),
    );
  }
}

import 'package:playx_version_update/src/core/model/playx_platform_value.dart';
import 'package:playx_version_update/src/core/model/playx_platform_version.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';

import 'playx_remote_version_info.dart';
import 'playx_version_request.dart';
import 'playx_version_source.dart';

/// A [PlayxVersionSource] with fixed values per platform, for example values
/// you read once from your backend or hard-code. Each platform can have its
/// own version, minimum version, release notes and store URL.
///
/// ```dart
/// PlayxUpdateOptions(
///   versionSource: PlayxStaticVersionSource(
///     version: PlayxPlatformVersion(android: '2.1.0', ios: '2.0.5'),
///     minVersion: PlayxPlatformVersion(android: '1.5.0', ios: '2.0.0'),
///     storeUrls: PlayxPlatformValue(ios: 'https://apps.apple.com/app/id1'),
///   ),
/// )
/// ```
///
/// It is the replacement for the deprecated `newPlatformVersion` and
/// `minPlatformVersion` options. If [version] has no value for the current
/// platform the check fails; chain it with [PlayxFallbackVersionSource] to
/// fall back to the store.
class PlayxStaticVersionSource implements PlayxVersionSource {
  /// The latest version per platform.
  final PlayxPlatformVersion version;

  /// The minimum version per platform. Apps older than it are forced to
  /// update.
  final PlayxPlatformVersion? minVersion;

  /// What's new, per platform.
  final PlayxPlatformValue<String>? releaseNotes;

  /// Where users update the app, per platform.
  final PlayxPlatformValue<String>? storeUrls;

  const PlayxStaticVersionSource({
    required this.version,
    this.minVersion,
    this.releaseNotes,
    this.storeUrls,
  });

  @override
  Future<PlayxVersionUpdateResult<PlayxRemoteVersionInfo>> fetch(
    PlayxVersionRequest request,
  ) async {
    final platform = request.platform;
    final latest = version.forPlatform(platform);
    if (latest == null || latest.isEmpty) {
      return PlayxVersionUpdateResult.error(
        DefaultFailureError(
          errorMsg: 'No version configured for ${platform.name}.',
        ),
      );
    }

    return PlayxVersionUpdateResult.success(
      PlayxRemoteVersionInfo(
        version: latest,
        minVersion: minVersion?.forPlatform(platform),
        releaseNotes: releaseNotes?.forPlatform(platform),
        storeUrl: storeUrls?.forPlatform(platform),
      ),
    );
  }
}

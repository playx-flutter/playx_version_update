import 'package:playx_version_update/src/core/datasource/remote_store_data_source.dart';
import 'package:playx_version_update/src/core/datasource/store_urls.dart';
import 'package:playx_version_update/src/core/model/playx_platform.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';

import 'playx_remote_version_info.dart';
import 'playx_version_request.dart';
import 'playx_version_source.dart';

/// Reads the version from Google Play (Android) or the App Store (iOS).
/// This is the default [PlayxVersionSource]. It supports Android and iOS only;
/// other platforms need a custom source.
///
/// When the caller already supplied the new version
/// ([PlayxVersionRequest.providedVersion]), Android does not request the
/// Google Play page at all, because the store URL can be built from the
/// package name. iOS still performs the lookup, as it is the only source of
/// the App Store URL, unless the caller supplied both the new version and the
/// store URL ([PlayxVersionRequest.providedStoreUrl]).
class PlayxStoreVersionSource implements PlayxVersionSource {
  final RemoteStoreDataSource _dataSource;

  PlayxStoreVersionSource([RemoteStoreDataSource? dataSource])
    : _dataSource = dataSource ?? RemoteStoreDataSource();

  @override
  Future<PlayxVersionUpdateResult<PlayxRemoteVersionInfo>> fetch(
    PlayxVersionRequest request,
  ) async {
    if (request.platform == PlayxPlatform.android) {
      final playUrl = getGooglePlayUrl(
        packageId: request.packageId,
        country: request.country,
        language: request.language,
      );

      final provided = request.providedVersion;
      if (provided != null) {
        return PlayxVersionUpdateResult.success(
          PlayxRemoteVersionInfo(version: provided, storeUrl: playUrl),
        );
      }

      final result = await _dataSource.getPlayStoreInfo(
        packageId: request.packageId,
        country: request.country,
        language: request.language,
        enableLog: request.enableLog,
        networkOptions: request.networkOptions,
      );
      return result.map(
        success: (info) => PlayxVersionUpdateResult.success(
          PlayxRemoteVersionInfo(
            version: info.version,
            minVersion: info.minVersion,
            releaseNotes: info.releaseNotes,
            storeUrl: playUrl,
          ),
        ),
        error: PlayxVersionUpdateResult.error,
      );
    }

    if (request.platform != PlayxPlatform.ios) {
      // Only Google Play and the App Store can be read. Other platforms need
      // a custom PlayxVersionSource.
      return const PlayxVersionUpdateResult.error(NotSupportedException());
    }

    // The lookup is only needed for the App Store URL (and the extras). With
    // both a version and a URL supplied there is nothing left to ask for.
    final providedVersion = request.providedVersion;
    final providedUrl = request.providedStoreUrl;
    if (providedVersion != null && providedUrl != null) {
      return PlayxVersionUpdateResult.success(
          PlayxRemoteVersionInfo(version: providedVersion, storeUrl: providedUrl));
    }

    final result = await _dataSource.getAppStoreInfo(
      packageId: request.packageId,
      country: request.country,
      language: request.language,
      enableLog: request.enableLog,
      networkOptions: request.networkOptions,
    );
    return result.map(
      success: (info) => PlayxVersionUpdateResult.success(
        PlayxRemoteVersionInfo(
          version: info.version,
          minVersion: info.minVersion,
          releaseNotes: info.releaseNotes,
          storeUrl: info.storeUrl,
        ),
      ),
      error: PlayxVersionUpdateResult.error,
    );
  }
}

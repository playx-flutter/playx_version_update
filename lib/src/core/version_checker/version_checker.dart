
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:playx_version_update/src/core/datasource/remote_store_data_source.dart';
import 'package:playx_version_update/src/core/datasource/store_urls.dart';
import 'package:playx_version_update/src/core/model/playx_platform.dart';
import 'package:playx_version_update/src/core/model/playx_platform_value.dart';
import 'package:playx_version_update/src/core/model/playx_platform_version.dart';
import 'package:playx_version_update/src/core/model/playx_version_update_info.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';
import 'package:playx_version_update/src/core/source/playx_remote_version_info.dart';
import 'package:playx_version_update/src/core/source/playx_store_version_source.dart';
import 'package:playx_version_update/src/core/source/playx_version_request.dart';
import 'package:playx_version_update/src/core/source/playx_version_source.dart';
import 'package:playx_version_update/src/core/version_checker/version.dart';

import '../model/options/playx_network_options.dart';
import '../model/options/playx_update_options.dart';

String? resolvePlatformVersionForCurrentPlatform({
  required PlayxPlatform platform,
  required String? genericVersion,
  required PlayxPlatformVersion? platformVersion,
}) {
  final version = platformVersion?.forPlatform(platform);
  if (version == null || version.isEmpty) return genericVersion;
  return version;
}

/// The app id used to look the app up on [platform]: `options.appIds`, then
/// `androidPackageName` / `iosBundleId`, then [fallback] (the package name
/// read from the app itself). Empty values count as not provided.
String resolvePackageId({
  required PlayxPlatform platform,
  required PlayxUpdateOptions options,
  required String fallback,
}) {
  String? usable(String? id) => id == null || id.isEmpty ? null : id;

  final legacy = switch (platform) {
    PlayxPlatform.android => options.androidPackageName,
    PlayxPlatform.ios => options.iosBundleId,
    _ => null,
  };
  return usable(options.appIds?.forPlatform(platform)) ??
      usable(legacy) ??
      fallback;
}

class VersionChecker {
  static final VersionChecker _instance = VersionChecker._internal();

  factory VersionChecker() {
    return _instance;
  }

  VersionChecker._internal() : _defaultSource = PlayxStoreVersionSource();

  /// Creates a checker that reads store data from [dataSource], for testing.
  @visibleForTesting
  VersionChecker.withDataSource(RemoteStoreDataSource dataSource)
      : _defaultSource = PlayxStoreVersionSource(dataSource);

  /// The source used when `PlayxUpdateOptions.versionSource` is not set.
  final PlayxVersionSource _defaultSource;

  Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>> checkVersion({
    PlayxUpdateOptions options = const PlayxUpdateOptions(),
  }) async {
    final platform = PlayxPlatform.current;
    // The default source reads Google Play and the App Store only; other
    // platforms are supported through a custom version source.
    final hasStore =
        platform == PlayxPlatform.android || platform == PlayxPlatform.ios;
    if (platform == null || (!hasStore && options.versionSource == null)) {
      return const PlayxVersionUpdateResult.error(NotSupportedException());
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String version = packageInfo.version;

    final packageId = resolvePackageId(
        platform: platform, options: options, fallback: packageInfo.packageName);

    return checkVersionFor(
      platform: platform,
      localVersion: version,
      packageId: packageId,
      country: options.country,
      language: options.language,
      newVersion: options.newVersion,
      newPlatformVersion: options.newPlatformVersion,
      minVersion: options.minVersion,
      minPlatformVersion: options.minPlatformVersion,
      forceUpdate: options.forceUpdate,
      storeUrls: options.storeUrls,
      source: options.versionSource,
      enableLog: options.enableNetworkLogging,
      networkOptions: options.networkOptions,
    );
  }

  /// Checks the version for one platform.
  ///
  /// The latest version comes from [source] (the store by default). Values
  /// supplied by the caller (`newVersion`, `minVersion`, the platform
  /// overrides and `forceUpdate`) win over the source. If the caller supplied
  /// the new version, a failing source is ignored.
  @visibleForTesting
  Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>> checkVersionFor({
    required PlayxPlatform platform,
    required String localVersion,
    required String packageId,
    required String country,
    required String language,
    required String? newVersion,
    required PlayxPlatformVersion? newPlatformVersion,
    required String? minVersion,
    required PlayxPlatformVersion? minPlatformVersion,
    required bool? forceUpdate,
    PlayxPlatformValue<String>? storeUrls,
    PlayxVersionSource? source,
    bool enableLog = false,
    PlayxNetworkOptions? networkOptions,
  }) async {
    final providedVersion = _providedVersion(
        platform: platform,
        newVersion: newVersion,
        newPlatformVersion: newPlatformVersion);

    final providedStoreUrl = _usable(storeUrls?.forPlatform(platform));

    var sourceResult = await (source ?? _defaultSource).fetch(
      PlayxVersionRequest(
        platform: platform,
        packageId: packageId,
        country: country,
        language: language,
        networkOptions: networkOptions,
        enableLog: enableLog,
        providedVersion: providedVersion,
        providedStoreUrl: providedStoreUrl,
      ),
    );
    if (providedVersion != null && sourceResult.isError) {
      sourceResult = PlayxVersionUpdateResult.success(
          PlayxRemoteVersionInfo(version: providedVersion));
    }

    return sourceResult.mapAsync(success: (info) async {
      final currentVersion = resolvePlatformVersionForCurrentPlatform(
            platform: platform,
            genericVersion: providedVersion ?? info.version,
            platformVersion: newPlatformVersion,
          ) ??
          '';
      final canUpdateResult = await shouldUpdate(
          version: localVersion, currentVersion: currentVersion);

      return canUpdateResult.mapAsync(success: (shouldUpdate) async {
        final effectiveMinVersion = resolvePlatformVersionForCurrentPlatform(
          platform: platform,
          genericVersion: minVersion ?? info.minVersion,
          platformVersion: minPlatformVersion,
        );
        final normalizedMinVersion = await getMinVersionVersion(
            minVersion: effectiveMinVersion, storeVersion: currentVersion);
        bool shouldAppForcedToUpdate = await shouldForceUpdate(
            version: localVersion,
            minVersion: normalizedMinVersion,
            playxForceUpdate: forceUpdate);

        // Caller's URL > the source's URL > the one derived from the package.
        final storeUrl = providedStoreUrl ??
            _usable(info.storeUrl) ??
            (platform == PlayxPlatform.android
                ? getGooglePlayUrl(
                    packageId: packageId, country: country, language: language)
                : '');

        final updateInfo = PlayxVersionUpdateInfo(
          localVersion: localVersion,
          newVersion: currentVersion,
          country: country,
          storeUrl: storeUrl,
          canUpdate: shouldUpdate,
          forceUpdate: shouldAppForcedToUpdate,
          releaseNotes: info.releaseNotes,
          minVersion: normalizedMinVersion,
          newPlatformVersion: newPlatformVersion,
          minPlatformVersion: minPlatformVersion,
        );

        return PlayxVersionUpdateResult.success(updateInfo);
      }, error: (error) async {
        return PlayxVersionUpdateResult<PlayxVersionUpdateInfo>.error(error);
      });
    }, error: (error) async {
      return PlayxVersionUpdateResult<PlayxVersionUpdateInfo>.error(error);
    });
  }

  /// The store URL of the current platform, without a version check.
  ///
  /// See [resolveStoreUrlFor].
  Future<PlayxVersionUpdateResult<String>> resolveStoreUrl(
      PlayxUpdateOptions options) async {
    final platform = PlayxPlatform.current;
    if (platform == null) {
      return const PlayxVersionUpdateResult.error(NotSupportedException());
    }

    final packageInfo = await PackageInfo.fromPlatform();
    return resolveStoreUrlFor(
      platform: platform,
      packageId: resolvePackageId(
          platform: platform,
          options: options,
          fallback: packageInfo.packageName),
      options: options,
    );
  }

  /// Finds the store URL of [platform]: `options.storeUrls`, then on Android
  /// the Google Play URL built from [packageId] (no network), otherwise one
  /// request to the version source (the store by default).
  @visibleForTesting
  Future<PlayxVersionUpdateResult<String>> resolveStoreUrlFor({
    required PlayxPlatform platform,
    required String packageId,
    required PlayxUpdateOptions options,
  }) async {
    final provided = _usable(options.storeUrls?.forPlatform(platform));
    if (provided != null) return PlayxVersionUpdateResult.success(provided);

    if (platform == PlayxPlatform.android) {
      return PlayxVersionUpdateResult.success(getGooglePlayUrl(
          packageId: packageId,
          country: options.country,
          language: options.language));
    }

    final result = await (options.versionSource ?? _defaultSource).fetch(
      PlayxVersionRequest(
        platform: platform,
        packageId: packageId,
        country: options.country,
        language: options.language,
        networkOptions: options.networkOptions,
        enableLog: options.enableNetworkLogging,
      ),
    );
    return result.map(
      success: (info) {
        final url = _usable(info.storeUrl);
        return url == null
            ? const PlayxVersionUpdateResult.error(DefaultFailureError(
                errorMsg:
                    'No store URL available. Set PlayxUpdateOptions.storeUrls.'))
            : PlayxVersionUpdateResult.success(url);
      },
      error: PlayxVersionUpdateResult.error,
    );
  }

  static String? _usable(String? value) =>
      value == null || value.isEmpty ? null : value;

  /// The new version supplied by the caller for the current platform, if any.
  String? _providedVersion({
    required PlayxPlatform platform,
    required String? newVersion,
    required PlayxPlatformVersion? newPlatformVersion,
  }) {
    final version = resolvePlatformVersionForCurrentPlatform(
      platform: platform,
      genericVersion: newVersion,
      platformVersion: newPlatformVersion,
    );
    return version == null || version.isEmpty ? null : version;
  }

  Future<String?> getMinVersionVersion({
    required String? minVersion,
    required String? storeVersion,
  }) async {
    if (minVersion == null || minVersion.isEmpty) return null;

    try {
      Version minimumVersion = Version.parse(minVersion);
      if (storeVersion != null && storeVersion.isNotEmpty) {
        final currentVersion = Version.parse(storeVersion);
        if (minimumVersion > currentVersion) {
          minimumVersion = currentVersion;
        }
      }
      return minimumVersion.toString();
    } catch (_) {
      return null;
    }
  }

  Future<bool> shouldForceUpdate(
      {required String version,
      required String? minVersion,
      required bool? playxForceUpdate}) async {
    if (playxForceUpdate != null) return playxForceUpdate;

    if (minVersion == null || minVersion.isEmpty) return false;

    try {
      final localVersion = Version.parse(version);
      Version minimumVersion = Version.parse(minVersion);
      return (localVersion <= minimumVersion);
    } catch (_) {
      return false;
    }
  }

  Future<PlayxVersionUpdateResult<bool>> shouldUpdate(
      {required String version, required String currentVersion}) async {
    if (currentVersion.isEmpty) {
      return const PlayxVersionUpdateResult.error(VersionFormatException());
    }
    try {
      final localVersion = Version.parse(version);
      final newVersion = Version.parse(currentVersion);
      return PlayxVersionUpdateResult.success(newVersion > localVersion);
    } catch (_) {
      return const PlayxVersionUpdateResult.error(VersionFormatException());
    }
  }
}

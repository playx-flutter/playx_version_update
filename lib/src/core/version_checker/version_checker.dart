import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:playx_version_update/src/core/datasource/remote_store_data_source.dart';
import 'package:playx_version_update/src/core/datasource/store_urls.dart';
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
  required bool isAndroid,
  required String? genericVersion,
  required PlayxPlatformVersion? platformVersion,
}) {
  final version = platformVersion?.forCurrentPlatform(isAndroid: isAndroid);
  if (version == null || version.isEmpty) return genericVersion;
  return version;
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
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const PlayxVersionUpdateResult.error(NotSupportedException());
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String version = packageInfo.version;

    final isAndroid = Platform.isAndroid;
    final packageId = isAndroid
        ? options.androidPackageName ?? packageInfo.packageName
        : options.iosBundleId ?? packageInfo.packageName;

    return checkVersionFor(
      isAndroid: isAndroid,
      localVersion: version,
      packageId: packageId,
      country: options.country,
      language: options.language,
      newVersion: options.newVersion,
      newPlatformVersion: options.newPlatformVersion,
      minVersion: options.minVersion,
      minPlatformVersion: options.minPlatformVersion,
      forceUpdate: options.forceUpdate,
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
    required bool isAndroid,
    required String localVersion,
    required String packageId,
    required String country,
    required String language,
    required String? newVersion,
    required PlayxPlatformVersion? newPlatformVersion,
    required String? minVersion,
    required PlayxPlatformVersion? minPlatformVersion,
    required bool? forceUpdate,
    PlayxVersionSource? source,
    bool enableLog = false,
    PlayxNetworkOptions? networkOptions,
  }) async {
    final providedVersion = _providedVersion(
        isAndroid: isAndroid,
        newVersion: newVersion,
        newPlatformVersion: newPlatformVersion);

    var sourceResult = await (source ?? _defaultSource).fetch(
      PlayxVersionRequest(
        isAndroid: isAndroid,
        packageId: packageId,
        country: country,
        language: language,
        networkOptions: networkOptions,
        enableLog: enableLog,
        providedVersion: providedVersion,
      ),
    );
    if (providedVersion != null && sourceResult.isError) {
      sourceResult = PlayxVersionUpdateResult.success(
          PlayxRemoteVersionInfo(version: providedVersion));
    }

    return sourceResult.mapAsync(success: (info) async {
      final currentVersion = resolvePlatformVersionForCurrentPlatform(
            isAndroid: isAndroid,
            genericVersion: providedVersion ?? info.version,
            platformVersion: newPlatformVersion,
          ) ??
          '';
      final canUpdateResult = await shouldUpdate(
          version: localVersion, currentVersion: currentVersion);

      return canUpdateResult.mapAsync(success: (shouldUpdate) async {
        final effectiveMinVersion = resolvePlatformVersionForCurrentPlatform(
          isAndroid: isAndroid,
          genericVersion: minVersion ?? info.minVersion,
          platformVersion: minPlatformVersion,
        );
        final normalizedMinVersion = await getMinVersionVersion(
            minVersion: effectiveMinVersion, storeVersion: currentVersion);
        bool shouldAppForcedToUpdate = await shouldForceUpdate(
            version: localVersion,
            minVersion: normalizedMinVersion,
            playxForceUpdate: forceUpdate);

        final sourceUrl = info.storeUrl;
        final storeUrl = sourceUrl != null && sourceUrl.isNotEmpty
            ? sourceUrl
            : isAndroid
                ? getGooglePlayUrl(
                    packageId: packageId, country: country, language: language)
                : '';

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

  /// The new version supplied by the caller for the current platform, if any.
  String? _providedVersion({
    required bool isAndroid,
    required String? newVersion,
    required PlayxPlatformVersion? newPlatformVersion,
  }) {
    final version = resolvePlatformVersionForCurrentPlatform(
      isAndroid: isAndroid,
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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:playx_version_update/src/core/datasource/remote_store_data_source.dart';
import 'package:playx_version_update/src/core/model/playx_version_update_info.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';
import 'package:playx_version_update/src/core/version_checker/version.dart';

import '../model/options/playx_update_options.dart';

class VersionChecker {
  static final VersionChecker _instance = VersionChecker._internal();

  factory VersionChecker() {
    return _instance;
  }

  VersionChecker._internal();

  final _dataSource = RemoteStoreDataSource();

  Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>> checkVersion({
    PlayxUpdateOptions options = const PlayxUpdateOptions(),
  }) async {

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const PlayxVersionUpdateResult.error(NotSupportedException());
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String version = packageInfo.version;


    if (Platform.isAndroid) {
      final packageId = options.androidPackageName ?? packageInfo.packageName;

      return _checkAndroidVersion(
          localVersion: version,
          packageId: packageId,
          country: options.country,
          language: options.language,
          newVersion: options.newVersion,
          forceUpdate: options.forceUpdate);
    } else if (Platform.isIOS) {
      final packageId = options.iosBundleId ?? packageInfo.packageName;
      return _checkIosVersion(
          localVersion: version,
          packageId: packageId,
          country: options.country,
          language: options.language,
          newVersion: options.newVersion,
          forceUpdate: options.forceUpdate);
    }

    return const PlayxVersionUpdateResult.error(NotSupportedException());
  }

  Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>>
      _checkAndroidVersion({
    required String localVersion,
    required String packageId,
    required String country,
    required String language,
    required String? newVersion,
    required bool? forceUpdate,
  }) async {
    final storeInfo = await _dataSource.getPlayStoreInfo(
        packageId: packageId, country: country, language: language);

    return storeInfo.mapAsync(success: (infoResult) async {
      final info = infoResult.data;

      final currentVersion = newVersion ?? info.version;
      final canUpdateResult = await shouldUpdate(
          version: localVersion, currentVersion: currentVersion);

      return canUpdateResult.mapAsync(success: (shouldUpdate) async {
        final minVersion = await getMinVersionVersion(
            minVersion: info.minVersion, storeVersion: info.version);
        bool shouldAppForcedToUpdate = await shouldForceUpdate(
            version: localVersion,
            minVersion: minVersion,
            playxForceUpdate: forceUpdate);

        final updateInfo = PlayxVersionUpdateInfo(
          localVersion: localVersion,
          newVersion: currentVersion,
          country: country,
          storeUrl: getGooglePlayUrl(
              packageId: packageId, country: country, language: language),
          canUpdate: shouldUpdate,
          forceUpdate: shouldAppForcedToUpdate,
          releaseNotes: info.releaseNotes,
          minVersion: minVersion,
        );

        return PlayxVersionUpdateResult.success(updateInfo);
      }, error: (error) async {
        return PlayxVersionUpdateResult<PlayxVersionUpdateInfo>.error(error);
      });
    }, error: (error) async {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromNetworkException(error.error));
    });
  }

  Future<PlayxVersionUpdateResult<PlayxVersionUpdateInfo>> _checkIosVersion({
    required String localVersion,
    required String packageId,
    required String country,
    required String language,
    required String? newVersion,
    required bool? forceUpdate,
  }) async {
    final storeInfo = await _dataSource.getAppStoreInfo(
        packageId: packageId, country: country, language: language);

    return storeInfo.mapAsync(success: (infoResult) async {
      final info = infoResult.data;

      final currentVersion = newVersion ?? info.version;
      final canUpdateResult = await shouldUpdate(
          version: localVersion, currentVersion: currentVersion);

      return canUpdateResult.mapAsync(success: (shouldUpdate) async {
        final minVersion = await getMinVersionVersion(
            minVersion: info.minVersion, storeVersion: info.version);
        bool shouldAppForcedToUpdate = await shouldForceUpdate(
            version: localVersion,
            minVersion: minVersion,
            playxForceUpdate: forceUpdate);

        final updateInfo = PlayxVersionUpdateInfo(
          localVersion: localVersion,
          newVersion: currentVersion,
          country: country,
          storeUrl: info.storeUrl ?? '',
          canUpdate: shouldUpdate,
          forceUpdate: shouldAppForcedToUpdate,
          releaseNotes: info.releaseNotes,
          minVersion: minVersion,
        );

        return PlayxVersionUpdateResult.success(updateInfo);
      }, error: (error) async {
        return PlayxVersionUpdateResult<PlayxVersionUpdateInfo>.error(error);
      });
    }, error: (error) async {
      return PlayxVersionUpdateResult.error(
          PlayxVersionUpdateError.fromNetworkException(error.error));
    });
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

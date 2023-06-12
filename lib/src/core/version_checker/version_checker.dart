import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:playx_version_update/src/core/datasource/remote_store_data_source.dart';
import 'package:playx_version_update/src/core/model/playx_version_update_info.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_result.dart';
import 'package:version/version.dart';

class VersionChecker {
  static final VersionChecker _instance = VersionChecker._internal();

  factory VersionChecker() {
    return _instance;
  }

  VersionChecker._internal();

  final _dataSource = RemoteStoreDataSource();

  Future<PlayxVersionResult<PlayxVersionUpdateInfo>> checkVersion({
    String? localVersion,
    String? newVersion,
    String? minVersion,
    bool forceUpdate = false,
    String? googlePlayId,
    String? appStoreId,
    required String country,
    required String language,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String version = packageInfo.version;

    if (Platform.isAndroid) {
      final packageId = googlePlayId ?? packageInfo.packageName;
      Fimber.d('check version packageId :$packageId, version :$version ');

      return _checkAndroidVersion(
          localVersion: version,
          packageId: packageId,
          country: country,
          language: language,
          newVersion: newVersion,
          forceUpdate: forceUpdate);
    } else if (Platform.isIOS) {
      final packageId = appStoreId ?? packageInfo.packageName;
      return _checkIosVersion(
          localVersion: version,
          packageId: packageId,
          country: country,
          language: language,
          newVersion: newVersion,
          forceUpdate: forceUpdate);
    } else {
      return const PlayxVersionResult.error(NotSupportedException());
    }
  }

  Future<PlayxVersionResult<PlayxVersionUpdateInfo>> _checkAndroidVersion({
    required String localVersion,
    required String packageId,
    required String country,
    required String language,
    required String? newVersion,
    required bool forceUpdate,
  }) async {
    final storeInfo = await _dataSource.getPlayStoreInfo(
        packageId: packageId, country: country, language: language);

    return storeInfo.mapAsync(success: (infoResult) async {
      final info = infoResult.data;

      final currentVersion = newVersion ?? info.version;
      final canUpdateResult = await shouldUpdate(
          version: localVersion, currentVersion: currentVersion);

      return canUpdateResult.mapAsync(success: (shouldUpdateResult) async {
        final shouldUpdate = shouldUpdateResult.data;

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

        return PlayxVersionResult.success(updateInfo);
      }, error: (error) async {
        return PlayxVersionResult.error(error.error);
      });
    }, error: (error) async {
      return PlayxVersionResult.error(error.error);
    });
  }

  Future<PlayxVersionResult<PlayxVersionUpdateInfo>> _checkIosVersion({
    required String localVersion,
    required String packageId,
    required String country,
    required String language,
    required String? newVersion,
    required bool forceUpdate,
  }) async {
    final storeInfo = await _dataSource.getAppStoreInfo(
        packageId: packageId, country: country, language: language);

    return storeInfo.mapAsync(success: (infoResult) async {
      final info = infoResult.data;

      final currentVersion = newVersion ?? info.version;
      final canUpdateResult = await shouldUpdate(
          version: localVersion, currentVersion: currentVersion);

      return canUpdateResult.mapAsync(success: (shouldUpdateResult) async {
        final shouldUpdate = shouldUpdateResult.data;

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

        return PlayxVersionResult.success(updateInfo);
      }, error: (error) async {
        return PlayxVersionResult.error(error.error);
      });
    }, error: (error) async {
      return PlayxVersionResult.error(error.error);
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
      required bool playxForceUpdate}) async {
    if (playxForceUpdate) return true;

    if (minVersion == null || minVersion.isEmpty) return false;

    try {
      final localVersion = Version.parse(version);
      Version minimumVersion = Version.parse(minVersion);
      return (localVersion <= minimumVersion);
    } catch (_) {
      return false;
    }
  }

  Future<PlayxVersionResult<bool>> shouldUpdate(
      {required String version, required String currentVersion}) async {
    if (currentVersion.isEmpty) {
      return const PlayxVersionResult.error(VersionFormatException());
    }
    try {
      final localVersion = Version.parse(version);
      final newVersion = Version.parse(currentVersion);
      return PlayxVersionResult.success(newVersion > localVersion);
    } catch (_) {
      return const PlayxVersionResult.error(VersionFormatException());
    }
  }
}

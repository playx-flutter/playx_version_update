import 'package:fimber/fimber.dart';
import 'package:playx_version_update/src/core/model/playx_version_update_info.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_result.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/version_checker/version_checker.dart';
import 'platform/playx_version_update_platform_interface.dart';

abstract class PlayxVersionUpdate {
  PlayxVersionUpdate._();

  static final _versionChecker = VersionChecker();

  static Future<PlayxVersionResult<PlayxVersionUpdateInfo>> checkVersion({
    String? localVersion,
    String? newVersion,
    String? minVersion,
    bool forceUpdate = false,
    String? googlePlayId,
    String? appStoreId,
    String country = 'us',
    String language = 'en',
  }) async {
    return _versionChecker.checkVersion(
      localVersion: localVersion,
      newVersion: newVersion,
      minVersion: minVersion,
      forceUpdate: forceUpdate,
      googlePlayId: googlePlayId,
      appStoreId: appStoreId,
      country: country,
      language: language,
    );
  }

  static Future<void> openStore(
      {required String storeUrl,
      LaunchMode launchMode = LaunchMode.externalApplication}) async {
    final Uri url = Uri.parse(storeUrl);
    if (await canLaunchUrl(url)) {
      try {
        launchUrl(url, mode: launchMode);
      } catch (e) {
        Fimber.e("couldn't open store");
      }
    }
  }

  Future<String?> getPlatformVersion() {
    return PlayxVersionUpdatePlatform.instance.getPlatformVersion();
  }
}

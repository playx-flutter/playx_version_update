import 'package:playx_version_update/src/core/model/playx_version.dart';
import 'package:playx_version_update/src/core/model/playx_version_update_info.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_result.dart';

import 'core/version_checker/version_checker.dart';
import 'platform/playx_version_update_platform_interface.dart';

abstract class PlayxVersionUpdate {
  PlayxVersionUpdate._();

  static final _versionChecker = VersionChecker();

  static Future<PlayxVersionResult<PlayxVersionUpdateInfo>> checkVersion(
      {required PlayxVersion playxVersion}) async {
    return _versionChecker.checkVersion(playxVersion: playxVersion);
  }

  Future<String?> getPlatformVersion() {
    return PlayxVersionUpdatePlatform.instance.getPlatformVersion();
  }
}

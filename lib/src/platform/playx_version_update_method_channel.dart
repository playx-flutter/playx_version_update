import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'playx_version_update_platform_interface.dart';

/// An implementation of [PlayxVersionUpdatePlatform] that uses method channels.
class MethodChannelPlayxVersionUpdate extends PlayxVersionUpdatePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('playx_version_update');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

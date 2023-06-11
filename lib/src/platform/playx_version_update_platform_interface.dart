import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'playx_version_update_method_channel.dart';

abstract class PlayxVersionUpdatePlatform extends PlatformInterface {
  /// Constructs a PlayxVersionUpdatePlatform.
  PlayxVersionUpdatePlatform() : super(token: _token);

  static final Object _token = Object();

  static PlayxVersionUpdatePlatform _instance = MethodChannelPlayxVersionUpdate();

  /// The default instance of [PlayxVersionUpdatePlatform] to use.
  ///
  /// Defaults to [MethodChannelPlayxVersionUpdate].
  static PlayxVersionUpdatePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PlayxVersionUpdatePlatform] when
  /// they register themselves.
  static set instance(PlayxVersionUpdatePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

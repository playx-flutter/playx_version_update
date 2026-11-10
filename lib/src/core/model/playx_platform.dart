import 'dart:io';

import 'package:flutter/foundation.dart';

/// The platforms an app can run on and be updated for.
enum PlayxPlatform {
  android,
  ios,
  macos,
  windows,
  linux;

  static bool _isOverridden = false;
  static PlayxPlatform? _override;

  /// The platform the app is running on, or `null` on the web and on
  /// unsupported platforms.
  static PlayxPlatform? get current {
    if (_isOverridden) return _override;
    if (kIsWeb) return null;
    return fromOperatingSystem(Platform.operatingSystem);
  }

  /// Makes [current] return [platform] (`null` for the web or an unsupported
  /// platform), so platform specific code can be tested on any host. Call
  /// [debugResetCurrent] afterwards.
  @visibleForTesting
  static void debugSetCurrent(PlayxPlatform? platform) {
    _isOverridden = true;
    _override = platform;
  }

  /// Undoes [debugSetCurrent].
  @visibleForTesting
  static void debugResetCurrent() {
    _isOverridden = false;
    _override = null;
  }

  /// Maps `Platform.operatingSystem` to a [PlayxPlatform], or `null` if the
  /// operating system is not supported.
  static PlayxPlatform? fromOperatingSystem(String operatingSystem) {
    return switch (operatingSystem) {
      'android' => android,
      'ios' => ios,
      'macos' => macos,
      'windows' => windows,
      'linux' => linux,
      _ => null,
    };
  }
}

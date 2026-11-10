import 'dart:io';

import 'package:flutter/foundation.dart';

/// The platforms an app can run on and be updated for.
enum PlayxPlatform {
  android,
  ios,
  macos,
  windows,
  linux;

  /// The platform the app is running on, or `null` on the web and on
  /// unsupported platforms.
  static PlayxPlatform? get current {
    if (kIsWeb) return null;
    return fromOperatingSystem(Platform.operatingSystem);
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

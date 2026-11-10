import 'playx_platform_value.dart';

/// Per-platform version values, for example the latest or the minimum version
/// on Android and on iOS.
///
/// Each platform can have its own value, so the minimum version can differ
/// between platforms.
class PlayxPlatformVersion extends PlayxPlatformValue<String> {
  const PlayxPlatformVersion({
    super.android,
    super.ios,
    super.macos,
    super.windows,
    super.linux,
  });

  String? forCurrentPlatform({required bool isAndroid}) {
    return isAndroid ? android : ios;
  }
}

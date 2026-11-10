import 'playx_platform.dart';

/// A value that can differ per platform, for example a version, a store URL
/// or an app id.
///
/// Set the platforms you care about; the package picks the one for the
/// current platform with [forPlatform].
class PlayxPlatformValue<T> {
  final T? android;
  final T? ios;
  final T? macos;
  final T? windows;
  final T? linux;

  const PlayxPlatformValue({
    this.android,
    this.ios,
    this.macos,
    this.windows,
    this.linux,
  });

  /// The value for [platform], or `null` if none was set.
  T? forPlatform(PlayxPlatform platform) {
    return switch (platform) {
      PlayxPlatform.android => android,
      PlayxPlatform.ios => ios,
      PlayxPlatform.macos => macos,
      PlayxPlatform.windows => windows,
      PlayxPlatform.linux => linux,
    };
  }

  @override
  String toString() {
    return '$runtimeType{android: $android, ios: $ios, macos: $macos, '
        'windows: $windows, linux: $linux}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlayxPlatformValue<T> &&
        other.runtimeType == runtimeType &&
        other.android == android &&
        other.ios == ios &&
        other.macos == macos &&
        other.windows == windows &&
        other.linux == linux;
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, android, ios, macos, windows, linux);
}

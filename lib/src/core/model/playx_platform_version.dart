/// Per-platform version values.
///
/// Deprecated together with `PlayxUpdateOptions.newPlatformVersion` and
/// `minPlatformVersion`: use a `PlayxVersionSource` instead, which receives
/// the platform in its request.
@Deprecated('Use PlayxUpdateOptions.versionSource instead.')
class PlayxPlatformVersion {
  final String? android;
  final String? ios;

  const PlayxPlatformVersion({
    this.android,
    this.ios,
  });

  String? forCurrentPlatform({required bool isAndroid}) {
    return isAndroid ? android : ios;
  }

  @override
  String toString() {
    return 'PlayxPlatformVersion{android: $android, ios: $ios}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlayxPlatformVersion &&
        other.android == android &&
        other.ios == ios;
  }

  @override
  int get hashCode => android.hashCode ^ ios.hashCode;
}

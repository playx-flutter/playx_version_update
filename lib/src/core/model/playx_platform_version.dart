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

class PlayxVersionUpdateInfo {
  String localVersion;
  String newVersion;
  bool forceUpdate;
  String storeUrl;
  String country;
  bool canUpdate;
  String? releaseNotes;
  String? minVersion;

  PlayxVersionUpdateInfo({
    required this.localVersion,
    required this.newVersion,
    required this.canUpdate,
    required this.forceUpdate,
    required this.storeUrl,
    this.country = 'en',
    this.releaseNotes,
    this.minVersion,
  });

  @override
  String toString() {
    return 'PlayxVersionUpdateInfo{localVersion: $localVersion, newVersion: $newVersion, forceUpdate: $forceUpdate, storeUrl: $storeUrl, country: $country, canUpdate: $canUpdate, releaseNotes: $releaseNotes, minVersion: $minVersion}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlayxVersionUpdateInfo &&
        other.localVersion == localVersion &&
        other.newVersion == newVersion &&
        other.forceUpdate == forceUpdate &&
        other.storeUrl == storeUrl &&
        other.country == country &&
        other.canUpdate == canUpdate &&
        other.releaseNotes == releaseNotes &&
        other.minVersion == minVersion;
  }

  @override
  int get hashCode {
    return localVersion.hashCode ^
        newVersion.hashCode ^
        forceUpdate.hashCode ^
        storeUrl.hashCode ^
        country.hashCode ^
        canUpdate.hashCode ^
        releaseNotes.hashCode ^
        minVersion.hashCode;
  }
}

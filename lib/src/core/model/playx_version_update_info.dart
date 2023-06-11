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
}

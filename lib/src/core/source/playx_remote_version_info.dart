/// Version information returned by a [PlayxVersionSource].
class PlayxRemoteVersionInfo {
  /// The latest available version of the app.
  final String version;

  /// The minimum version allowed to keep running. Apps older than this are
  /// forced to update, unless `PlayxUpdateOptions.forceUpdate` says otherwise.
  final String? minVersion;

  /// What's new in [version].
  final String? releaseNotes;

  /// Where users update the app. On Android the Google Play URL is used when
  /// this is missing; on iOS the update button needs it.
  final String? storeUrl;

  const PlayxRemoteVersionInfo({
    required this.version,
    this.minVersion,
    this.releaseNotes,
    this.storeUrl,
  });

  @override
  String toString() =>
      'PlayxRemoteVersionInfo{version: $version, minVersion: $minVersion, '
      'releaseNotes: $releaseNotes, storeUrl: $storeUrl}';
}

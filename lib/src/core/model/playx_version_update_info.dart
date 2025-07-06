/// Represents comprehensive information about the app's version update status.
///
/// This class is typically returned by methods like [PlayxVersionUpdate.checkVersion]
/// and provides all the necessary details to determine if an update is available,
/// if it's mandatory, and how to direct the user to the update.
class PlayxVersionUpdateInfo {
  /// The version of the app currently installed on the user's device.
  final String localVersion;

  /// The latest version of the app available on the respective app store (Google Play or Apple App Store).
  final String newVersion;

  /// Indicates whether the update is mandatory.
  ///
  /// This can be determined by a `minVersion` specified in the app's store description
  /// or explicitly set via [PlayxUpdateOptions].
  final bool forceUpdate;

  /// The direct URL to the app's listing in the Google Play Store or Apple App Store.
  final String storeUrl;

  /// The country code used when fetching store information.
  ///
  /// Defaults to 'en' if not specified during the version check.
  final String country;

  /// Indicates whether an update is available and the current app version
  /// can be updated to the [newVersion].
  final bool canUpdate;

  /// Optional: Release notes or a summary of new features and changes
  /// available in the [newVersion].
  ///
  /// This information is typically fetched from the app store listing.
  final String? releaseNotes;

  /// Optional: The minimum version of the app required to run, as parsed
  /// from the app's store description (e.g., `[Minimum Version :1.0.0]`).
  ///
  /// If the [localVersion] is below this [minVersion], then [forceUpdate] will be true.
  final String? minVersion;

  /// Creates a new instance of [PlayxVersionUpdateInfo].
  const PlayxVersionUpdateInfo({
    required this.localVersion,
    required this.newVersion,
    required this.canUpdate,
    required this.forceUpdate,
    required this.storeUrl,
    this.country = 'en',
    this.releaseNotes,
    this.minVersion,
  });

  /// Returns a string representation of the [PlayxVersionUpdateInfo] instance,
  /// useful for debugging.
  @override
  String toString() {
    return 'PlayxVersionUpdateInfo{localVersion: $localVersion, newVersion: $newVersion, forceUpdate: $forceUpdate, storeUrl: $storeUrl, country: $country, canUpdate: $canUpdate, releaseNotes: $releaseNotes, minVersion: $minVersion}';
  }

  /// Compares this [PlayxVersionUpdateInfo] instance with [other] for equality.
  ///
  /// Returns true if all properties of both instances are identical.
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

  /// Returns a hash code for this [PlayxVersionUpdateInfo] instance.
  ///
  /// The hash code is based on all properties of the instance.
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
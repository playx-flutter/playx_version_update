/// Configuration for version checking.
class PlayxUpdateOptions {
  /// The current version of the app. If not provided, it's fetched from `package_info_plus`.
  final String? localVersion;

  /// The new version to compare against.
  ///
  ///  **If you provide a value here, the package will use it directly and
  /// skip fetching the version from the app stores.** This is useful for testing
  /// or if you get version information from a custom backend.
  final String? newVersion;

  /// The minimum required version for the app to run.
  ///
  /// If the app's `localVersion` is less than `minVersion`, the result will
  /// indicate a forced update is required, **unless `forceUpdate` is explicitly set to `false`**.
  final String? minVersion;

  /// Manually set the force update status.
  ///
  /// By default, this is `null`. When `null`, the force update status is automatically
  /// determined by comparing the app's `localVersion` against the `minVersion` (if provided).
  /// You can set this to `true` or `false` to override the automatic calculation.
  final bool? forceUpdate;

  /// The app's package name on the Google Play Store (e.g., 'com.example.app').
  /// If not provided, it's fetched from `package_info_plus`.
  final String? androidPackageName;

  /// The app's bundle ID on the Apple App Store (e.g., 'com.example.app').
  /// If not provided, it's fetched from `package_info_plus`.
  final String? iosBundleId;

  /// The two-letter country code for the store country. Defaults to 'us'.
  final String country;

  /// The two-letter language code for store details. Defaults to 'en'.
  final String language;

  const PlayxUpdateOptions({
    this.localVersion,
    this.newVersion,
    this.minVersion,
    this.forceUpdate,
    this.androidPackageName,
    this.iosBundleId,
    this.country = 'us',
    this.language = 'en',
  });
}

import 'package:playx_version_update/src/core/model/playx_platform_version.dart';

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

  /// Platform-specific new app versions, typically provided by a custom backend.
  ///
  /// On the current platform, this value overrides [newVersion] when provided.
  final PlayxPlatformVersion? newPlatformVersion;

  /// Platform-specific minimum required app versions, typically provided by a custom backend.
  ///
  /// On the current platform, this value overrides [minVersion] when provided.
  final PlayxPlatformVersion? minPlatformVersion;

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

  /// Whether to enable network logging.
  final bool enableNetworkLogging;

  const PlayxUpdateOptions({
    this.localVersion,
    this.newVersion,
    this.minVersion,
    this.newPlatformVersion,
    this.minPlatformVersion,
    this.forceUpdate,
    this.androidPackageName,
    this.iosBundleId,
    this.country = 'us',
    this.language = 'en',
    this.enableNetworkLogging = false,
  });
}

import 'package:playx_version_update/src/core/model/options/playx_network_options.dart';
import 'package:playx_version_update/src/core/model/playx_platform_value.dart';
import 'package:playx_version_update/src/core/model/playx_platform_version.dart';
import 'package:playx_version_update/src/core/source/playx_version_source.dart';

/// Configuration for version checking.
class PlayxUpdateOptions {
  /// The current version of the app. If not provided, it's fetched from `package_info_plus`.
  final String? localVersion;

  /// The new version to compare against.
  ///
  /// **If you provide a value here, the package uses it as the store version.**
  /// This is useful for testing or if you get version information from a
  /// custom backend.
  ///
  /// - On **Android** the Google Play page is not requested at all, so no
  ///   store failure (offline, consent page, ...) can fail the check. Release
  ///   notes and the store's minimum version are then unavailable; provide
  ///   [minVersion] if you need one.
  /// - On **iOS** the App Store lookup is still attempted, because it is the
  ///   only source of the store URL, release notes and minimum version. If it
  ///   fails, the provided version is used anyway.
  final String? newVersion;

  /// The minimum required version for the app to run.
  ///
  /// If the app's `localVersion` is less than `minVersion`, the result will
  /// indicate a forced update is required, **unless `forceUpdate` is explicitly set to `false`**.
  final String? minVersion;

  /// Platform-specific new app versions, typically provided by a custom backend.
  ///
  /// On the current platform, this value overrides [newVersion] when provided.
  ///
  /// Deprecated: a [PlayxVersionSource] already knows the platform
  /// (`PlayxVersionRequest.isAndroid`), so return the right version from
  /// [versionSource] instead.
  @Deprecated('Use versionSource, which receives the platform in its request.')
  final PlayxPlatformVersion? newPlatformVersion;

  /// Platform-specific minimum required app versions, typically provided by a custom backend.
  ///
  /// On the current platform, this value overrides [minVersion] when provided.
  ///
  /// Deprecated: a [PlayxVersionSource] already knows the platform
  /// (`PlayxVersionRequest.isAndroid`), so return the right minimum version
  /// from [versionSource] instead.
  @Deprecated('Use versionSource, which receives the platform in its request.')
  final PlayxPlatformVersion? minPlatformVersion;

  /// Manually set the force update status.
  ///
  /// By default, this is `null`. When `null`, the force update status is automatically
  /// determined by comparing the app's `localVersion` against the `minVersion` (if provided).
  /// You can set this to `true` or `false` to override the automatic calculation.
  final bool? forceUpdate;

  /// The app's package name on the Google Play Store (e.g., 'com.example.app').
  /// If not provided, it's fetched from `package_info_plus`.
  ///
  /// A shortcut for `appIds: PlayxPlatformValue(android: ...)`; [appIds] wins
  /// when both are set.
  final String? androidPackageName;

  /// The app's bundle ID on the Apple App Store (e.g., 'com.example.app').
  /// If not provided, it's fetched from `package_info_plus`.
  ///
  /// A shortcut for `appIds: PlayxPlatformValue(ios: ...)`; [appIds] wins
  /// when both are set.
  final String? iosBundleId;

  /// The app's id on each platform: the Google Play package name, the App
  /// Store bundle id, or the identifier used by another platform's store.
  /// Set every platform once; the package uses the one of the current
  /// platform. Platforms without a value fall back to [androidPackageName] /
  /// [iosBundleId], then to the id read from the app itself.
  final PlayxPlatformValue<String>? appIds;

  /// The two-letter country code for the store country. Defaults to 'us'.
  final String country;

  /// The two-letter language code for store details. Defaults to 'en'.
  final String language;

  /// Whether to log the version-check network traffic to the console:
  /// request method, URL and headers, response status, headers, timing and a
  /// short body preview, plus errors and retries. Sensitive headers are masked.
  final bool enableNetworkLogging;

  /// Settings for the store request: retries, timeouts, headers, a custom
  /// `Dio` instance and cancellation. See [PlayxNetworkOptions].
  final PlayxNetworkOptions networkOptions;

  /// Where the latest version comes from. Defaults to the store
  /// (`PlayxStoreVersionSource`). Use `PlayxCallbackVersionSource` for Firebase
  /// Remote Config or your own backend, and `PlayxFallbackVersionSource` to
  /// chain several. Values set directly on these options (`newVersion`,
  /// `minVersion`, the platform overrides, `forceUpdate`) always win over it.
  final PlayxVersionSource? versionSource;

  const PlayxUpdateOptions({
    this.localVersion,
    this.newVersion,
    this.minVersion,
    @Deprecated('Use versionSource, which receives the platform in its request.')
    this.newPlatformVersion,
    @Deprecated('Use versionSource, which receives the platform in its request.')
    this.minPlatformVersion,
    this.forceUpdate,
    this.androidPackageName,
    this.iosBundleId,
    this.country = 'us',
    this.language = 'en',
    this.enableNetworkLogging = false,
    this.networkOptions = const PlayxNetworkOptions(),
    this.versionSource,
    this.appIds,
  });
}

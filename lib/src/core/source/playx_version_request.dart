import 'package:playx_version_update/src/core/model/options/playx_network_options.dart';
import 'package:playx_version_update/src/core/model/playx_platform.dart';

/// What a [PlayxVersionSource] is asked for.
class PlayxVersionRequest {
  /// The platform the check runs on.
  final PlayxPlatform platform;

  /// Whether the check runs on Android.
  bool get isAndroid => platform == PlayxPlatform.android;

  /// Whether the check runs on iOS.
  bool get isIos => platform == PlayxPlatform.ios;

  /// The Google Play package name or the App Store bundle id.
  final String packageId;

  /// The two-letter store country code.
  final String country;

  /// The two-letter store language code.
  final String language;

  /// The network settings from `PlayxUpdateOptions.networkOptions`, or `null`
  /// for the defaults.
  final PlayxNetworkOptions? networkOptions;

  /// Whether network logging was requested.
  final bool enableLog;

  /// The new version the caller already supplied (`newVersion` or the
  /// platform override), if any. It always wins over what a source returns,
  /// so a source may skip work when it is set.
  final String? providedVersion;

  /// The store URL the caller already supplied for this platform
  /// (`PlayxUpdateOptions.storeUrls`), if any. It always wins over a URL a
  /// source returns, so a source does not need to look one up.
  final String? providedStoreUrl;

  const PlayxVersionRequest({
    required this.platform,
    required this.packageId,
    required this.country,
    required this.language,
    this.networkOptions,
    this.enableLog = false,
    this.providedVersion,
    this.providedStoreUrl,
  });
}

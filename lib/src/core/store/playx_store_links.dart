import 'package:playx_version_update/src/core/model/playx_platform.dart';

/// Builds the links used to open an app's store page.
abstract final class PlayxStoreLinks {
  /// The link that opens the store app directly instead of a browser, derived
  /// from the web [storeUrl], or `null` if there is none:
  ///
  /// - Android, a Google Play page -> `market://details?id=<package>`
  /// - iOS, an App Store page -> the same URL with the `itms-apps` scheme
  /// - macOS, a Mac App Store page -> the same URL with the `macappstores`
  ///   scheme
  ///
  /// Any other URL (a custom scheme, another store, a short link) has no
  /// deep link: it is opened as it is.
  static Uri? deepLinkFor(String storeUrl, {PlayxPlatform? platform}) {
    final uri = Uri.tryParse(storeUrl);
    if (uri == null || !uri.hasAuthority) return null;

    switch (platform ?? PlayxPlatform.current) {
      case PlayxPlatform.android:
        final isPlay =
            uri.host == 'play.google.com' &&
            uri.path.startsWith('/store/apps/details');
        final id = uri.queryParameters['id'];
        if (!isPlay || id == null || id.isEmpty) return null;
        return Uri(
          scheme: 'market',
          host: 'details',
          queryParameters: {'id': id},
        );
      case PlayxPlatform.ios:
        final isAppStore =
            uri.host == 'apps.apple.com' || uri.host == 'itunes.apple.com';
        final isWeb = uri.scheme == 'https' || uri.scheme == 'http';
        if (!isAppStore || !isWeb) return null;
        return uri.replace(scheme: 'itms-apps');
      case PlayxPlatform.macos:
        final isMacAppStore =
            uri.host == 'apps.apple.com' || uri.host == 'itunes.apple.com';
        final isWebUrl = uri.scheme == 'https' || uri.scheme == 'http';
        if (!isMacAppStore || !isWebUrl) return null;
        return uri.replace(scheme: 'macappstores');
      default:
        return null;
    }
  }

  /// The links to try to open [storeUrl], best first: the deep link when
  /// [preferStoreApp] is set and one exists, then the URL itself.
  static List<Uri> candidates(
    String storeUrl, {
    bool preferStoreApp = true,
    PlayxPlatform? platform,
  }) {
    final uri = Uri.tryParse(storeUrl);
    if (uri == null || storeUrl.isEmpty) return const [];

    final deepLink = preferStoreApp
        ? deepLinkFor(storeUrl, platform: platform)
        : null;
    return [?deepLink, uri];
  }
}

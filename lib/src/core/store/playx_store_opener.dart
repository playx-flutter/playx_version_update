import 'package:playx_version_update/src/core/model/playx_platform.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_error.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';
import 'package:url_launcher/url_launcher.dart';

import 'playx_store_links.dart';

/// Opens [storeUrl], trying the store app's deep link first (see
/// [PlayxStoreLinks]) and the web URL after it.
///
/// `canLaunchUrl` is deliberately not used: it needs the app to declare
/// `<queries>` (Android 11+) or `LSApplicationQueriesSchemes` (iOS) for each
/// scheme, while launching only fails softly when nothing can handle a link.
///
/// [platform] and [launch] exist for tests.
Future<PlayxVersionUpdateResult<bool>> openStoreUrl(
  String storeUrl, {
  LaunchMode launchMode = LaunchMode.externalApplication,
  bool preferStoreApp = true,
  PlayxPlatform? platform,
  Future<bool> Function(Uri uri, LaunchMode mode)? launch,
}) async {
  final launcher = launch ?? (uri, mode) => launchUrl(uri, mode: mode);
  final candidates = PlayxStoreLinks.candidates(
    storeUrl,
    preferStoreApp: preferStoreApp,
    platform: platform,
  );
  if (candidates.isEmpty) {
    return const PlayxVersionUpdateResult.error(
      DefaultFailureError(errorMsg: 'Could not launch store: no valid URL.'),
    );
  }

  Object? lastError;
  for (final uri in candidates) {
    try {
      if (await launcher(uri, launchMode)) {
        return const PlayxVersionUpdateResult.success(true);
      }
    } catch (e) {
      lastError = e;
    }
  }

  return PlayxVersionUpdateResult.error(
    DefaultFailureError(
      errorMsg: lastError == null
          ? 'Could not launch store.'
          : 'Could not launch store. : $lastError',
    ),
  );
}

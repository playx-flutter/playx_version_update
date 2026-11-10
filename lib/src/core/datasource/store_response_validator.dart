import 'package:playx_version_update/src/core/network/exceptions/network_exception.dart';
import 'package:playx_version_update/src/core/network/network_response.dart';

import 'store_type.dart';

/// Detects store responses that are successful (HTTP 200) but do not contain
/// the data we are looking for.
abstract final class StoreResponseValidator {
  /// Throws a [NetworkException] if [response] is not the expected page.
  static void validate(StoreType store, NetworkResponse response) {
    if (store == StoreType.googlePlay && isGoogleConsentPage(response)) {
      throw const ConsentRequiredException();
    }
  }

  /// Whether [response] is Google's cookie-consent page.
  ///
  /// Google redirects users in some regions (EU/UK) to
  /// `consent.google.com`. Some clients get the consent form inline instead,
  /// so a page that mentions the consent host but has none of the app-page
  /// version markers is treated as one too.
  static bool isGoogleConsentPage(NetworkResponse response) {
    if (response.finalUri.host == 'consent.google.com') return true;

    final body = response.body;
    return body.contains('consent.google.com') &&
        !body.contains('softwareVersion') &&
        !body.contains('Current Version');
  }
}

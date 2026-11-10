import 'package:playx_version_update/src/core/network/exceptions/network_exception.dart';
import 'package:playx_version_update/src/core/network/network_response.dart';

import 'store_type.dart';

/// Detects store responses that are successful (HTTP 200) but do not contain
/// the data we are looking for.
abstract final class StoreResponseValidator {
  /// Throws a [NetworkException] if [response] is not the expected page.
  ///
  /// [versionFound] tells whether a version could be read from the body.
  static void validate(
    StoreType store,
    NetworkResponse response, {
    required bool versionFound,
  }) {
    if (store == StoreType.googlePlay &&
        isGoogleConsentPage(response, versionFound: versionFound)) {
      throw const ConsentRequiredException();
    }
  }

  /// Whether [response] is Google's cookie-consent page.
  ///
  /// Google redirects users in some regions (EU/UK) to
  /// `consent.google.com`, which is conclusive. Some clients get the consent
  /// form inline instead: a page that mentions the consent host is only
  /// treated as the form when no version could be read from it, because a
  /// real app page may also reference that host in its scripts.
  static bool isGoogleConsentPage(
    NetworkResponse response, {
    required bool versionFound,
  }) {
    if (response.finalUri.host == 'consent.google.com') return true;
    return !versionFound && response.body.contains('consent.google.com');
  }
}

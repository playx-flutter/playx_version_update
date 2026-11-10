import 'package:playx_version_update/src/core/network/exceptions/network_exception.dart';

import 'store_type.dart';

/// Refines generic HTTP failures with what is known about each store's API.
///
/// - **Google Play** (scraped details page): answers `404` for a package that
///   does not exist, and `429` when throttled.
/// - **App Store** (iTunes lookup API): answers `200` with `resultCount: 0`
///   for an unknown bundle id (handled while parsing), and is rate limited
///   (roughly 20 requests per minute per IP) by answering `403`/`429`.
abstract final class StoreErrorMapper {
  static NetworkException refine(StoreType store, NetworkException error) {
    if (error is! ApiException) return error;

    switch ((store, error.statusCode)) {
      case (_, 404):
        return AppNotFoundException(cause: error.cause);
      case (StoreType.appStore, 403):
        return TooManyRequestsException(cause: error.cause);
      default:
        return error;
    }
  }
}

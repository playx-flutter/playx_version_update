/// Google Play details page for [packageId].
String getGooglePlayUrl(
        {required String packageId,
        required String country,
        required String language}) =>
    "https://play.google.com/store/apps/details?id=$packageId&hl=$language&gl=$country";

/// App Store (iTunes) lookup endpoint for [packageId] (the bundle id).
///
/// With [isMac] the Mac App Store is searched (`entity=macSoftware`), so a
/// macOS app is found by its bundle id.
String getAppStoreInfoUrl({
  required String packageId,
  required String country,
  required String language,
  bool isMac = false,
}) =>
    "https://itunes.apple.com/lookup?bundleId=$packageId&country=$country&lang=$language${isMac ? '&entity=macSoftware' : ''}";

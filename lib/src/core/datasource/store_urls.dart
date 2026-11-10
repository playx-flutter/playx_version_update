/// Google Play details page for [packageId].
String getGooglePlayUrl(
        {required String packageId,
        required String country,
        required String language}) =>
    "https://play.google.com/store/apps/details?id=$packageId&hl=$language&gl=$country";

/// App Store (iTunes) lookup endpoint for [packageId] (the bundle id).
String getAppStoreInfoUrl(
        {required String packageId,
        required String country,
        required String language}) =>
    "https://itunes.apple.com/lookup?bundleId=$packageId&country=$country&lang=$language";

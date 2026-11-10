import 'package:playx_version_update/playx_version_update.dart';

/// Real, published apps used by the store demos, so the lookups work
/// without the example being on any store.
///
/// - Android: Gemini (Google Play)
/// - iOS: Shortcuts (App Store)
/// - macOS: Xcode (Mac App Store)
///
/// For your own app none of this is needed: the ids are read from the app
/// itself. Use `appIds` only to override them.
const kStoreAppIds = PlayxPlatformValue<String>(
  android: 'com.google.android.apps.bard',
  ios: 'com.apple.shortcuts',
  macos: 'com.apple.dt.Xcode',
);

/// Ids that exist on no store, to show the "app not found" error.
const kUnknownAppIds = PlayxPlatformValue<String>(
  android: 'com.example.not.published',
  ios: 'com.example.not.published',
  macos: 'com.example.not.published',
);

/// The store pages of the apps above, for the demos that set `storeUrls`.
const kStoreUrls = PlayxPlatformValue<String>(
  android:
      'https://play.google.com/store/apps/details?id=com.google.android.apps.bard',
  ios: 'https://apps.apple.com/app/shortcuts/id915249334',
  macos: 'https://apps.apple.com/app/xcode/id497799835?mt=12',
);

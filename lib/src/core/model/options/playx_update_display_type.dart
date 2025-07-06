import 'package:playx_version_update/playx_version_update.dart';

/// Defines the preferred UI presentation for Flutter-based update prompts.
///
/// This enum is used to configure the appearance of update dialogs or pages
/// presented by functions like [PlayxVersionUpdate.showUpdateDialog] on both Android and iOS,
/// and for the iOS-specific UI within [PlayxVersionUpdate.showInAppUpdateDialog].
///
/// **Important Note:** This enum does **not** control the UI for Android's
/// native in-app updates (Immediate or Flexible) triggered by [PlayxVersionUpdate.showInAppUpdateDialog],
/// as their presentation is managed by the Google Play Store.
enum PlayxUpdateDisplayType {
  /// Shows a standard dialog for updates.
  /// On Android, this corresponds to a Material dialog.
  /// On iOS, this corresponds to a Cupertino dialog.
  dialog,

  /// Shows a full-screen page for updates.
  /// On both Android and iOS, this corresponds to [PlayxUpdatePage].
  page,

  /// Shows a full-screen page only if a force update is required.
  /// Otherwise, it shows a dialog. This applies to Flutter-based UIs
  /// on both Android and iOS.
  pageOnForceUpdate,
}

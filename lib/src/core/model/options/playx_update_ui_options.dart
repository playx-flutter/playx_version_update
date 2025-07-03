import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/callbacks.dart';
import 'playx_update_display_type.dart';


/// Options for customizing the user interface of Flutter-based update prompts.
///
/// These options apply to the UI shown by [PlayxVersionUpdate.showUpdateDialog] on both Android
/// and iOS, and to the iOS-specific UI within [PlayxVersionUpdate.showInAppUpdateDialog].
///
/// **Important Note:** These options do **not** control the UI for Android's
/// native in-app updates (Immediate or Flexible) triggered by [PlayxVersionUpdate.showInAppUpdateDialog],
/// as their presentation is managed by the Google Play Store.
class PlayxUpdateUIOptions {
  /// The title of the update dialog or page.
  ///
  /// This function receives [PlayxVersionUpdateInfo] which contains
  /// `localVersion`, `newVersion`, and `canUpdate`, allowing you to
  /// customize the title based on the update information.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final UpdateTextInfoCallback? title;

  /// The description message in the update dialog or page.
  ///
  /// This function receives [PlayxVersionUpdateInfo] which contains
  /// `localVersion`, `newVersion`, and `canUpdate`, allowing you to
  /// customize the description based on the update information.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final UpdateTextInfoCallback? description;

  /// The title for the release notes section within the update UI.
  /// Applies to Flutter-based UIs on both Android and iOS if [showReleaseNotes] is true.
  final UpdateTextInfoCallback? releaseNotesTitle;

  /// Whether to display release notes within the update UI. Defaults to `false`.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final bool showReleaseNotes;

  /// Whether the dialog or page can be dismissed by the user.
  ///
  /// If `true`, the user can dismiss the dialog or page.
  /// If `false`, the dialog or page will not be dismissible.
  /// If not provided, defaults to `true` for non-force updates.
  final bool? isDismissible;

  /// Whether to show the dismiss button when a force update is required.
  /// If `true`, the dismiss button will be shown even when a force update is required.
  /// And It will close the app when pressed.
  /// If `false`, the dismiss button will not be shown when a force update is required.
  final bool showDismissButtonOnForceUpdate;

  /// The text for the update action button. Defaults to 'Update'.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final String updateButtonText;

  /// The text for the dismiss button. Defaults to 'Later' or 'Close App' if the app is forced to update.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final String? dismissButtonText;

  /// Callback when the update button is pressed.
  /// Overrides the default behavior of opening the app store.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final UpdatePressedCallback? onUpdate;

  /// Callback when the dismiss button is pressed.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final UpdateCancelPressedCallback? onCancel;

  /// The launch mode for opening the app store URL when the update button is pressed
  /// and [onUpdate] is not provided. Defaults to [LaunchMode.externalApplication].
  /// Applies to Flutter-based UIs on both Android and iOS.
  final LaunchMode launchMode;

  /// A leading widget to display at the top of the update UI (e.g., an icon or image).
  /// Applies to Flutter-based UIs on both Android and iOS.
  final Widget? leading;

  /// Determines the preferred UI presentation for Flutter-based update prompts.
  ///
  /// This option applies to the UI shown by [PlayxVersionUpdate.showUpdateDialog] on both Android
  /// and iOS, and to the iOS-specific UI within [PlayxVersionUpdate.showInAppUpdateDialog].
  ///
  /// **Note:** This does not control the UI for Android's native in-app updates.
  final PlayxUpdateDisplayType displayType;

  /// Text style for the update UI's title.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final TextStyle? titleTextStyle;

  /// Text style for the update UI's description.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final TextStyle? descriptionTextStyle;

  /// Text style for the release notes title within the update UI.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final TextStyle? releaseNotesTitleTextStyle;

  /// Text style for the actual release notes content within the update UI.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final TextStyle? releaseNotesTextStyle;

  /// Text style for the update action button's text.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final TextStyle? updateButtonTextStyle;

  /// Text style for the dismiss button's text.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final TextStyle? dismissButtonTextStyle;

  /// Style for the update action button itself.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final ButtonStyle? updateButtonStyle;

  /// Style for the dismiss button itself.
  /// Applies to Flutter-based UIs on both Android and iOS.
  final ButtonStyle? dismissButtonStyle;


  const PlayxUpdateUIOptions({
    this.title,
    this.description,
    this.releaseNotesTitle,
    this.showReleaseNotes = false,
    this.isDismissible,
    this.showDismissButtonOnForceUpdate =true,
    this.updateButtonText = 'Update',
    this.dismissButtonText,
    this.onUpdate,
    this.onCancel,
    this.launchMode = LaunchMode.externalApplication,
    this.leading,
    this.displayType = PlayxUpdateDisplayType.pageOnForceUpdate,
    this.titleTextStyle,
    this.descriptionTextStyle,
    this.releaseNotesTitleTextStyle,
    this.releaseNotesTextStyle,
    this.updateButtonTextStyle,
    this.dismissButtonTextStyle,
    this.updateButtonStyle,
    this.dismissButtonStyle,
  });
}
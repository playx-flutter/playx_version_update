import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/callbacks.dart';

/// Configuration for the update UI (Dialog or Page).
class PlayxUpdateUIOptions {
  /// Custom title for the update UI.
  final UpdateNameInfoCallback? title;
  /// Custom description for the update UI.
  final UpdateNameInfoCallback? description;
  /// Title for the release notes section.
  final UpdateNameInfoCallback? releaseNotesTitle;
  /// Whether to display release notes. Defaults to false.
  final bool showReleaseNotes;
  /// Whether to show a dismiss button on a force update UI. Defaults to true.
  final bool showDismissButtonOnForceUpdate;
  /// Custom text for the update button.
  final String? updateActionTitle;
  /// Custom text for the dismiss button.
  final String? dismissActionTitle;
  /// Callback when the update button is pressed. Overrides the default store opening behavior.
  final UpdatePressedCallback? onUpdate;
  /// Callback when the dismiss button is pressed.
  final UpdateCancelPressedCallback? onCancel;
  /// The launch mode for opening the app store.
  final LaunchMode launchMode;
  /// A leading widget for the update UI (e.g., an icon or image).
  final Widget? leading;
  /// Whether to show a full page for a force update instead of a dialog. Defaults to false.
  final bool showPageOnForceUpdate;
  /// Whether the update UI is dismissible. If null, it's non-dismissible for force updates.
  final bool? isDismissible;

  const PlayxUpdateUIOptions({
    this.showPageOnForceUpdate = false,
    this.isDismissible,
    this.title,
    this.description,
    this.releaseNotesTitle,
    this.showReleaseNotes = false,
    this.showDismissButtonOnForceUpdate = true,
    this.updateActionTitle,
    this.dismissActionTitle,
    this.onUpdate,
    this.onCancel,
    this.launchMode = LaunchMode.externalApplication,
    this.leading,
  });
}


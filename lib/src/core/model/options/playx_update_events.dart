import 'package:playx_version_update/src/core/model/in_app_updates/playx_app_update_type.dart';
import 'package:playx_version_update/src/core/model/playx_version_update_info.dart';
import 'package:playx_version_update/src/core/model/result/playx_version_update_result.dart';

/// How the user closed the update UI without updating.
enum PlayxUpdateDismissReason {
  /// The user tapped the dismiss button ("Later" / "Close app").
  button,

  /// The user used the system back button/gesture or tapped outside the dialog.
  system,
}

/// Callbacks for the update flow, mainly for analytics.
///
/// ```dart
/// PlayxUpdateUIOptions(
///   events: PlayxUpdateEvents(
///     onShown: (info) => analytics.log('update_shown', info.newVersion),
///     onUpdateTapped: (info) => analytics.log('update_tapped'),
///     onDismissed: (info, reason) => analytics.log('update_dismissed'),
///   ),
/// )
/// ```
class PlayxUpdateEvents {
  /// The update dialog or page was displayed.
  final void Function(PlayxVersionUpdateInfo info)? onShown;

  /// The user tapped the update button.
  final void Function(PlayxVersionUpdateInfo info)? onUpdateTapped;

  /// The user closed the update UI without updating.
  final void Function(
    PlayxVersionUpdateInfo info,
    PlayxUpdateDismissReason reason,
  )?
  onDismissed;

  /// A Google Play in-app update of the given type is about to start (Android).
  final void Function(PlayxAppUpdateType type)? onInAppUpdateStarted;

  /// A Google Play in-app update finished, successfully or not (Android).
  final void Function(
    PlayxAppUpdateType type,
    PlayxVersionUpdateResult<bool> result,
  )?
  onInAppUpdateResult;

  const PlayxUpdateEvents({
    this.onShown,
    this.onUpdateTapped,
    this.onDismissed,
    this.onInAppUpdateStarted,
    this.onInAppUpdateResult,
  });
}

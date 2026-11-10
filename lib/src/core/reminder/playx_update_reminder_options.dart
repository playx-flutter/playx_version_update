import 'playx_update_storage.dart';

/// Configures how the update prompt is suppressed after the user chose
/// "Later" or "Skip this version".
///
/// ```dart
/// PlayxVersionUpdate.showUpdateDialog(
///   context: context,
///   reminderOptions: PlayxUpdateReminderOptions(
///     storage: PrefsUpdateStorage(prefs), // keep the choice across launches
///     snoozeDuration: Duration(days: 3),
///     allowSkipVersion: true,
///   ),
/// );
/// ```
///
/// Forced updates are never suppressed.
class PlayxUpdateReminderOptions {
  /// Where the choice is stored. Defaults to an in-memory storage, which is
  /// forgotten when the app restarts.
  final PlayxUpdateStorage? storage;

  /// How long the prompt stays hidden after the user dismisses it for a
  /// version. Use `null` to prompt again on the next check.
  /// Defaults to one day.
  final Duration? snoozeDuration;

  /// Whether the update UI offers a "Skip this version" button. A skipped
  /// version is never prompted again; a newer version is.
  final bool allowSkipVersion;

  /// The label of the "Skip this version" button.
  final String skipButtonText;

  const PlayxUpdateReminderOptions({
    this.storage,
    this.snoozeDuration = const Duration(days: 1),
    this.allowSkipVersion = false,
    this.skipButtonText = 'Skip this version',
  });
}

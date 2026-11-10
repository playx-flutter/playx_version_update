import 'package:playx_version_update/playx_version_update.dart';

/// Shared by the update dialog and page: reports user actions to
/// [PlayxUpdateEvents] and records them in the [PlayxUpdateReminder].
///
/// Only the first outcome (update, skip or dismiss) of a shown UI is
/// reported, so closing the UI after tapping a button is not counted twice.
class UpdateUiController {
  final PlayxVersionUpdateInfo info;
  final PlayxUpdateEvents events;
  final PlayxUpdateReminder? reminder;

  bool _resolved = false;
  bool _shown = false;

  UpdateUiController({required this.info, required this.events, this.reminder});

  /// Whether to offer a "Skip this version" button.
  bool get canSkip =>
      reminder?.options.allowSkipVersion == true && !info.forceUpdate;

  String get skipButtonText =>
      reminder?.options.skipButtonText ?? 'Skip this version';

  void shown() {
    if (_shown) return;
    _shown = true;
    events.onShown?.call(info);
  }

  void updateTapped() {
    // The user may tap update several times (the UI can stay open).
    events.onUpdateTapped?.call(info);
    _resolved = true;
  }

  /// Handles the update button: reports the tap, then opens the store with
  /// `onUpdate` (which replaces everything), `storeLauncher` or the default
  /// `openStore`, and reports whether the store was opened.
  Future<void> performUpdate(PlayxUpdateUIOptions uiOptions) async {
    updateTapped();

    final onUpdate = uiOptions.onUpdate;
    if (onUpdate != null) {
      onUpdate(info, uiOptions.launchMode);
      return;
    }

    var opened = false;
    try {
      final launcher = uiOptions.storeLauncher;
      if (launcher != null) {
        opened = await launcher(info);
      } else {
        final result = await PlayxVersionUpdate.openStore(
          storeUrl: info.storeUrl,
          launchMode: uiOptions.launchMode,
          preferStoreApp: uiOptions.preferStoreApp,
        );
        opened = result.updateData ?? false;
      }
    } catch (_) {
      opened = false;
    }
    events.onStoreOpenResult?.call(info, opened);
  }

  void dismissed(PlayxUpdateDismissReason reason) {
    if (_resolved) return;
    _resolved = true;
    events.onDismissed?.call(info, reason);
    reminder?.snooze(info);
  }

  void skipped() {
    if (_resolved) return;
    _resolved = true;
    events.onVersionSkipped?.call(info);
    reminder?.skipVersion(info);
  }
}

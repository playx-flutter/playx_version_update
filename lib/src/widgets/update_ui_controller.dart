import 'package:flutter/foundation.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/store/playx_store_opener.dart';
import 'package:playx_version_update/src/core/utils/guard.dart';

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
  bool _updating = false;

  UpdateUiController({required this.info, required this.events, this.reminder});

  /// Whether to offer a "Skip this version" button.
  bool get canSkip =>
      reminder?.options.allowSkipVersion == true && !info.forceUpdate;

  String get skipButtonText =>
      reminder?.options.skipButtonText ?? 'Skip this version';

  void shown() {
    if (_shown) return;
    _shown = true;
    guardCallback('calling PlayxUpdateEvents.onShown',
        () => events.onShown?.call(info));
  }

  void updateTapped() {
    // The user may tap update several times (the UI can stay open).
    _resolved = true;
    guardCallback('calling PlayxUpdateEvents.onUpdateTapped',
        () => events.onUpdateTapped?.call(info));
  }

  /// Handles the update button: reports the tap, then opens the store with
  /// `onUpdate` (which replaces everything), `storeLauncher` or the default
  /// `openStore`, and reports whether the store was opened.
  Future<void> performUpdate(PlayxUpdateUIOptions uiOptions) async {
    // Ignore taps while the store is being opened.
    if (_updating) return;
    _updating = true;

    try {
      updateTapped();

      final onUpdate = uiOptions.onUpdate;
      if (onUpdate != null) {
        guardCallback('calling PlayxUpdateUIOptions.onUpdate',
            () => onUpdate(info, uiOptions.launchMode));
        return;
      }

      var opened = false;
      try {
        final launcher = uiOptions.storeLauncher;
        if (launcher != null) {
          opened = await launcher(info);
        } else {
          // Not `openStore`: an empty URL must fail here, not trigger a lookup.
          final result = await openStoreUrl(
            info.storeUrl,
            launchMode: uiOptions.launchMode,
            preferStoreApp: uiOptions.preferStoreApp,
          );
          opened = result.updateData ?? false;
        }
      } catch (error, stack) {
        opened = false;
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'playx_version_update',
          context: ErrorDescription('while opening the store'),
        ));
      }
      guardCallback('calling PlayxUpdateEvents.onStoreOpenResult',
          () => events.onStoreOpenResult?.call(info, opened));
    } finally {
      _updating = false;
    }
  }

  void dismissed(PlayxUpdateDismissReason reason) {
    if (_resolved) return;
    _resolved = true;
    guardCallback('calling PlayxUpdateEvents.onDismissed',
        () => events.onDismissed?.call(info, reason));
    reminder?.snooze(info);
  }

  void skipped() {
    if (_resolved) return;
    _resolved = true;
    guardCallback('calling PlayxUpdateEvents.onVersionSkipped',
        () => events.onVersionSkipped?.call(info));
    reminder?.skipVersion(info);
  }
}

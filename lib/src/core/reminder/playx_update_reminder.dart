import 'package:playx_version_update/src/core/model/playx_version_update_info.dart';

import 'playx_update_reminder_options.dart';
import 'playx_update_storage.dart';

/// Why an update prompt was not shown.
enum PlayxPromptSuppressedReason {
  /// The user chose "Skip this version" for this version.
  skippedVersion,

  /// The user dismissed the prompt for this version and the snooze period has
  /// not ended yet.
  snoozed,
}

/// Remembers when the user dismissed or skipped an update, and decides whether
/// the prompt should be shown again.
///
/// [PlayxVersionUpdate.showUpdateDialog] uses it when you pass
/// `reminderOptions`. You can also use it directly to build your own UI.
class PlayxUpdateReminder {
  static const _skippedVersionKey = 'playx_update.skipped_version';
  static const _snoozedVersionKey = 'playx_update.snoozed_version';
  static const _snoozedUntilKey = 'playx_update.snoozed_until';

  final PlayxUpdateReminderOptions options;
  final DateTime Function() _now;

  PlayxUpdateReminder([
    this.options = const PlayxUpdateReminderOptions(),
    DateTime Function()? clock,
  ]) : _now = clock ?? DateTime.now;

  PlayxUpdateStorage get _storage =>
      options.storage ?? PlayxInMemoryUpdateStorage.shared;

  /// Why the prompt for [info] should not be shown, or `null` if it should.
  ///
  /// Forced updates are never suppressed. Storage failures are ignored: the
  /// prompt is shown rather than risking a missed update.
  Future<PlayxPromptSuppressedReason?> suppressionReason(
    PlayxVersionUpdateInfo info,
  ) async {
    if (info.forceUpdate) return null;

    try {
      if (await _storage.read(_skippedVersionKey) == info.newVersion) {
        return PlayxPromptSuppressedReason.skippedVersion;
      }

      final snoozedVersion = await _storage.read(_snoozedVersionKey);
      final snoozedUntil = DateTime.tryParse(
        await _storage.read(_snoozedUntilKey) ?? '',
      );
      if (snoozedVersion == info.newVersion &&
          snoozedUntil != null &&
          _now().isBefore(snoozedUntil)) {
        return PlayxPromptSuppressedReason.snoozed;
      }
    } catch (_) {}
    return null;
  }

  /// Whether the prompt for [info] should be shown.
  Future<bool> shouldPrompt(PlayxVersionUpdateInfo info) async =>
      await suppressionReason(info) == null;

  /// Hides the prompt for [info]'s version for [PlayxUpdateReminderOptions.snoozeDuration].
  /// Does nothing if snoozing is disabled or the update is forced.
  Future<void> snooze(PlayxVersionUpdateInfo info) async {
    final duration = options.snoozeDuration;
    if (duration == null || info.forceUpdate) return;

    try {
      await _storage.write(_snoozedVersionKey, info.newVersion);
      await _storage.write(
        _snoozedUntilKey,
        // UTC, so a time zone or daylight saving change cannot shift the deadline.
        _now().add(duration).toUtc().toIso8601String(),
      );
    } catch (_) {}
  }

  /// Never prompts for [info]'s version again. Does nothing if the update is
  /// forced.
  Future<void> skipVersion(PlayxVersionUpdateInfo info) async {
    if (info.forceUpdate) return;

    try {
      await _storage.write(_skippedVersionKey, info.newVersion);
    } catch (_) {}
  }

  /// Forgets every snoozed or skipped version.
  Future<void> reset() async {
    try {
      await _storage.remove(_skippedVersionKey);
      await _storage.remove(_snoozedVersionKey);
      await _storage.remove(_snoozedUntilKey);
    } catch (_) {}
  }
}

import 'package:playx_version_update/src/core/model/options/playx_update_events.dart';
import 'package:playx_version_update/src/core/model/playx_version_update_info.dart';

/// Shared by the update dialog and page: reports user actions to
/// [PlayxUpdateEvents].
///
/// Only the first outcome (update or dismiss) of a shown UI is
/// reported, so closing the UI after tapping a button is not counted twice.
class UpdateUiController {
  final PlayxVersionUpdateInfo info;
  final PlayxUpdateEvents events;

  bool _resolved = false;
  bool _shown = false;

  UpdateUiController({required this.info, required this.events});

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

  void dismissed(PlayxUpdateDismissReason reason) {
    if (_resolved) return;
    _resolved = true;
    events.onDismissed?.call(info, reason);
  }
}

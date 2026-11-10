import 'package:playx_version_update/playx_version_update.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UpdateTextInfoCallback = String Function(PlayxVersionUpdateInfo info);

typedef UpdatePressedCallback = Function(
    PlayxVersionUpdateInfo info, LaunchMode launchMode);

typedef UpdateCancelPressedCallback = Function(PlayxVersionUpdateInfo info);

/// Opens the store for [info] and reports whether it was opened.
///
/// See `PlayxUpdateUIOptions.storeLauncher`.
typedef StoreLauncherCallback = Future<bool> Function(
    PlayxVersionUpdateInfo info);

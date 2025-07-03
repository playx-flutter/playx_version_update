import 'package:playx_version_update/playx_version_update.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UpdateTextInfoCallback = String Function(PlayxVersionUpdateInfo info);

typedef UpdatePressedCallback = Function(
    PlayxVersionUpdateInfo info, LaunchMode launchMode);

typedef UpdateCancelPressedCallback = Function(PlayxVersionUpdateInfo info);

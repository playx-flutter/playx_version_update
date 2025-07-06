
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playx_version_update/playx_version_update.dart';

/// A platform-adaptive Flutter widget that displays an update dialog.
///
/// On Android, it renders a `Material` `AlertDialog`. On iOS, it renders a
/// `Cupertino` `CupertinoAlertDialog`. This widget is used by
/// [PlayxVersionUpdate.showUpdateDialog] to present update prompts.
///
/// It requires [PlayxVersionUpdateInfo] which contains details about the
/// update (e.g., current version, new version, whether it's a force update,
/// and store URL).
///
/// The appearance and behavior of the dialog are highly customizable via
/// [PlayxUpdateUIOptions]. You can set custom titles, descriptions, button texts,
/// and apply `TextStyle` and `ButtonStyle` to various elements.
///
/// ### Features:
/// - **Platform Adaptive:** Automatically renders Material dialog on Android and Cupertino dialog on iOS.
/// - **Customizable Content:** Control the text for the title, description, release notes title,
///   update button, and dismiss button using [uiOptions].
/// - **Styling Options:** Apply custom [TextStyle] and [ButtonStyle] to various text
///   and button elements for a branded look.
/// - **Release Notes:** Optionally display release notes ([PlayxVersionUpdateInfo.releaseNotes])
///   by setting `uiOptions.showReleaseNotes` to `true`.
/// - **Dismissibility:** The dialog's dismissibility is controlled by `uiOptions.isDismissible`.
///   By default, it's non-dismissible if `versionUpdateInfo.forceUpdate` is true.
/// - **Action Callbacks:** Provides callbacks `uiOptions.onUpdate` and `uiOptions.onCancel`
///   for custom logic when buttons are pressed. If `onUpdate` is not provided,
///   it defaults to opening the app store via `PlayxVersionUpdate.openStore`
///   using the specified `uiOptions.launchMode`.
///   If `onCancel` is not provided for a non-dismissible (force) update,
///   it defaults to `SystemNavigator.pop()` to close the app.
///
/// ### Behavior:
/// - If `versionUpdateInfo.canUpdate` is `false` or if running on web, this
///   widget returns `SizedBox.shrink()` (an empty widget).
/// - Uses `PopScope` to manage system back button behavior based on `isDismissible`.
///
/// ### Example Usage (Typically used by `showUpdateDialog`):
/// ```dart
/// // This dialog is typically shown internally by PlayxVersionUpdate.showUpdateDialog
/// // based on the uiOptions.presentation setting.
/// await PlayxVersionUpdate.showUpdateDialog(
///   context: context,
///   options: PlayxUpdateOptions(
///     googlePlayId: 'com.example.app',
///     appStoreId: 'com.example.app',
///   ),
///   uiOptions: PlayxUpdateUIOptions(
///     presentation: PlayxUpdateDisplayType.dialog, // Explicitly request a dialog
///     title: (info) => 'App Update ${info.newVersion}!',
///     description: (info) => 'A critical update is available. Please update now.',
///     releaseNotesTitle: (info) => 'What\'s New:',
///     showReleaseNotes: true,
///     isDismissible: false, // Make the dialog non-dismissible
///     updateButtonText: 'Update App',
///     dismissButtonText: 'Exit', // For non-dismissible, might be 'Exit'
///     updateButtonTextStyle: TextStyle(fontSize: 18, color: Colors.white),
///     updateButtonStyle: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
///   ),
/// );
/// ```
///
/// @see [PlayxVersionUpdateInfo] for update details.
/// @see [PlayxUpdateUIOptions] for customization options.
/// @see [PlayxVersionUpdate.showUpdateDialog] for the primary method to display this dialog.
class PlayxUpdateDialog extends StatefulWidget {
  final PlayxVersionUpdateInfo versionUpdateInfo;
  final PlayxUpdateUIOptions uiOptions;

  const PlayxUpdateDialog({
    super.key,
    required this.versionUpdateInfo,
    required this.uiOptions,
  });

  @override
  State<PlayxUpdateDialog> createState() => _PlayxUpdateDialogState();
}

class _PlayxUpdateDialogState extends State<PlayxUpdateDialog> {
  @override
  Widget build(BuildContext context) {
    if (!widget.versionUpdateInfo.canUpdate) {
      return const SizedBox.shrink();
    }
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    if (Platform.isAndroid) {
      return PopScope(
          canPop: isDismissible,
          onPopInvokedWithResult: (didPop, _) {},
          child: _buildAndroidDialog(context));
    } else if (Platform.isIOS) {
      return PopScope(
          canPop: isDismissible,
          onPopInvokedWithResult: (didPop, _) {},
          child: _buildIosDialog(context));
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAndroidDialog(BuildContext context) {
    return AlertDialog(
      title: Text(
        _getTitleText(),
        style: widget.uiOptions.titleTextStyle,
      ),
      content: SingleChildScrollView(
        child: Column(children: [
          Text(
            _getDescriptionText(),
            style: widget.uiOptions.descriptionTextStyle,
          ),
          if (shouldShowReleaseNotes) ...[
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: double.infinity,
              child: Text(
                widget.uiOptions.releaseNotesTitle
                        ?.call(widget.versionUpdateInfo) ??
                    'Release Notes:',
                textAlign: TextAlign.start,
                style: widget.uiOptions.releaseNotesTitleTextStyle ??
                    const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              (widget.versionUpdateInfo.releaseNotes ?? ''),
              style: widget.uiOptions.releaseNotesTextStyle,
            ),
          ]
        ]),
      ),
      actions: <Widget>[
        if (shouldShowDismissButton)
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Later');
              if (isDismissible) {
                widget.uiOptions.onCancel?.call(widget.versionUpdateInfo);
              } else {
                widget.uiOptions.onCancel?.call(widget.versionUpdateInfo) ??
                    SystemNavigator.pop();
              }
            },
            style: widget.uiOptions.dismissButtonStyle,
            child: Text(
              _getDismissActionTitle(),
              style: widget.uiOptions.dismissButtonTextStyle,
            ),
          ),
        TextButton(
          onPressed: () {
            if (widget.uiOptions.onUpdate != null) {
              widget.uiOptions.onUpdate
                  ?.call(widget.versionUpdateInfo, widget.uiOptions.launchMode);
            } else {
              PlayxVersionUpdate.openStore(
                  storeUrl: widget.versionUpdateInfo.storeUrl,
                  launchMode: widget.uiOptions.launchMode);
            }
            if (isDismissible) {
              Navigator.pop(context, 'Update');
            }
          },
          style: widget.uiOptions.updateButtonStyle,
          child: Text(
            widget.uiOptions.updateButtonText,
            style: widget.uiOptions.updateButtonTextStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildIosDialog(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(_getTitleText()),
      content: SingleChildScrollView(
        child: Column(children: [
          Text(
            _getDescriptionText(),
          ),
          if (shouldShowReleaseNotes) ...[
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: double.infinity,
              child: Text(
                widget.uiOptions.releaseNotesTitle
                        ?.call(widget.versionUpdateInfo) ??
                    'Release Notes:',
                textAlign: TextAlign.start,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text((widget.versionUpdateInfo.releaseNotes ?? '')),
          ]
        ]),
      ),
      actions: <CupertinoDialogAction>[
        if (shouldShowDismissButton)
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context, 'Later');
              if (isDismissible) {
                widget.uiOptions.onCancel?.call(widget.versionUpdateInfo);
              } else {
                widget.uiOptions.onCancel?.call(widget.versionUpdateInfo) ??
                    SystemNavigator.pop();
              }
            },
            child: Text(_getDismissActionTitle()),
          ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            if (isDismissible) {
              Navigator.pop(context, 'Update');
            }
            if (widget.uiOptions.onUpdate != null) {
              widget.uiOptions.onUpdate
                  ?.call(widget.versionUpdateInfo, widget.uiOptions.launchMode);
            } else {
              PlayxVersionUpdate.openStore(
                  storeUrl: widget.versionUpdateInfo.storeUrl,
                  launchMode: widget.uiOptions.launchMode);
            }
            if (isDismissible) {
              Navigator.pop(context, 'Update');
            }
          },
          child: Text(widget.uiOptions.updateButtonText),
        ),
      ],
    );
  }

  String _getTitleText() {
    String title = widget.uiOptions.title?.call(widget.versionUpdateInfo) ??
        'New version available.';
    return title;
  }

  String _getDescriptionText() {
    String description = widget.uiOptions.description
            ?.call(widget.versionUpdateInfo) ??
        'A new version of the app is now available. \n \nWould you like to update now to version ${widget.versionUpdateInfo.newVersion} ?';
    return description;
  }

  String _getDismissActionTitle() {
    final forceUpdate = widget.versionUpdateInfo.forceUpdate;
    final defaultTitle = forceUpdate ? 'Close App' : 'Later';
    String title = widget.uiOptions.dismissButtonText ?? defaultTitle;
    return title;
  }

  bool get shouldShowReleaseNotes =>
      widget.uiOptions.showReleaseNotes &&
      widget.versionUpdateInfo.releaseNotes != null &&
      widget.versionUpdateInfo.releaseNotes!.isNotEmpty;

  bool get shouldShowDismissButton => isDismissible ||
      (widget.uiOptions.showDismissButtonOnForceUpdate &&
          widget.versionUpdateInfo.forceUpdate);

  bool get isDismissible =>
      widget.uiOptions.isDismissible ?? !widget.versionUpdateInfo.forceUpdate;

}

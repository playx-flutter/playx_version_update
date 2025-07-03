import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/model/options/playx_update_ui_options.dart';
import 'package:url_launcher/url_launcher.dart';

///Dialog widget that shows material update dialog for android and Cupertino Dialog for IOS.
///It needs [PlayxVersionUpdateInfo] which contains information about the current version and the latest version.
///and whether the app should update of force update to the latest version.
/// and [canUpdate]which decides whether the version needs to be updated or not. If not the widget returns [SizedBox.shrink()]
///You can customize the widget by customizing [title], [description],[releaseNotesTitle],[updateActionTitle],[dismissActionTitle]
///[showReleaseNotes] : show the release notes or not.
///If the app needs to force update The dismiss button is hidden, You can show it by setting [showDismissButtonOnForceUpdate]
///[LaunchMode] :Which decide the desired mode to launch the store.
/// Support for these modes varies by platform. Platforms that do not support
/// the requested mode may substitute another mode. See [launchUrl] for more details.
/// It also provides callback functions for when user click on update or dismiss.
class PlayxUpdateDialog extends StatefulWidget {
  final PlayxVersionUpdateInfo versionUpdateInfo;
  final PlayxUpdateUIOptions uiOptions;
  final bool? isDismissible;

  const PlayxUpdateDialog(
      {super.key,
      required this.versionUpdateInfo,
      required this.uiOptions,
      this.isDismissible});

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
                widget.uiOptions.releaseNotesTitle?.call(widget.versionUpdateInfo) ??
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
            child: Text(_getDismissActionTitle()),
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
          child: Text(widget.uiOptions.updateActionTitle ?? 'Update'),
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
                widget.uiOptions.releaseNotesTitle?.call(widget.versionUpdateInfo) ??
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
          child: Text(widget.uiOptions.updateActionTitle ?? 'Update'),
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
    String description = widget.uiOptions.description?.call(widget.versionUpdateInfo) ??
        'A new version of the app is now available. \n \nWould you like to update now to version ${widget.versionUpdateInfo.newVersion} ?';
    return description;
  }

  String _getDismissActionTitle() {
    final forceUpdate = widget.versionUpdateInfo.forceUpdate;
    final defaultTitle = forceUpdate ? 'Close App' : 'Later';
    String title = widget.uiOptions.dismissActionTitle ?? defaultTitle;
    return title;
  }

  bool get shouldShowReleaseNotes =>
      widget.uiOptions.showReleaseNotes &&
      widget.versionUpdateInfo.releaseNotes != null &&
      widget.versionUpdateInfo.releaseNotes!.isNotEmpty;

  bool get shouldShowDismissButton =>
      !widget.versionUpdateInfo.forceUpdate ||
      (widget.versionUpdateInfo.forceUpdate &&
          widget.uiOptions.showDismissButtonOnForceUpdate);

  bool get isDismissible =>
      widget.isDismissible == true && !widget.versionUpdateInfo.forceUpdate;
}

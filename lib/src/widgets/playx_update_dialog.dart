import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayxUpdateDialog extends StatefulWidget {
  final PlayxVersionUpdateInfo versionUpdateInfo;
  final String? title;
  final String? description;
  final String? releaseNotesTitle;
  final bool showReleaseNotes;
  final bool showDismissButtonOnForceUpdate;
  final String? updateActionTitle;
  final String? dismissActionTitle;
  final String? forceDismissActionTitle;

  final String? forceUpdateTitle;
  final String? forceUpdateDescription;

  final VoidCallback? onUpdate;
  final VoidCallback? onCancel;
  final VoidCallback? onForceCancel;

  final LaunchMode launchMode;

  const PlayxUpdateDialog(
      {super.key,
      required this.versionUpdateInfo,
      this.title,
      this.description,
      this.releaseNotesTitle,
      this.showReleaseNotes = false,
      this.updateActionTitle,
      this.dismissActionTitle,
      this.forceDismissActionTitle,
      this.forceUpdateTitle,
      this.forceUpdateDescription,
      this.showDismissButtonOnForceUpdate = true,
      this.launchMode = LaunchMode.externalApplication,
      this.onUpdate,
      this.onCancel,
      this.onForceCancel});

  @override
  State<PlayxUpdateDialog> createState() => _PlayxUpdateDialogState();
}

class _PlayxUpdateDialogState extends State<PlayxUpdateDialog> {
  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return _buildAndroidDialog(context);
    } else if (Platform.isIOS) {
      return _buildIosDialog(context);
    } else {
      return Container();
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
                widget.releaseNotesTitle ?? 'Release Notes:',
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
              if (widget.versionUpdateInfo.forceUpdate) {
                widget.onForceCancel?.call();
              } else {
                widget.onCancel?.call();
              }
            },
            child: Text(_getDismissActionTitle()),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, 'Update');
            updateAndroidApp();
            widget.onUpdate?.call();
          },
          child: Text(widget.updateActionTitle ?? 'Update'),
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
                widget.releaseNotesTitle ?? 'Release Notes:',
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
              if (widget.versionUpdateInfo.forceUpdate) {
                widget.onForceCancel?.call();
              } else {
                widget.onCancel?.call();
              }
            },
            child: Text(_getDismissActionTitle()),
          ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context, 'Update');
            widget.onUpdate?.call();
            updateIosApp();
          },
          child: Text(widget.updateActionTitle ?? 'Update'),
        ),
      ],
    );
  }

  String _getTitleText() {
    String title = widget.title ?? 'New version available.';
    if (widget.versionUpdateInfo.forceUpdate) {
      if (widget.forceUpdateTitle != null) {
        title = widget.forceUpdateTitle!;
      }
    }
    return title;
  }

  String _getDescriptionText() {
    String description = widget.description ??
        'A new version of the app is now available. \n \nWould you like to update now to version ${widget.versionUpdateInfo.newVersion} ?';
    if (widget.versionUpdateInfo.forceUpdate) {
      if (widget.forceUpdateTitle != null) {
        description = widget.forceUpdateTitle!;
      }
    }

    return description;
  }

  String _getDismissActionTitle() {
    final forceUpdate = widget.versionUpdateInfo.forceUpdate;
    final defaultTitle = forceUpdate ? 'Close App' : 'Later';
    String title = widget.dismissActionTitle ?? defaultTitle;
    if (forceUpdate) {
      if (widget.forceDismissActionTitle != null) {
        title = widget.forceDismissActionTitle!;
      }
    }
    return title;
  }

  bool get shouldShowReleaseNotes =>
      widget.showReleaseNotes &&
      widget.versionUpdateInfo.releaseNotes != null &&
      widget.versionUpdateInfo.releaseNotes!.isNotEmpty;

  bool get shouldShowDismissButton =>
      !widget.versionUpdateInfo.forceUpdate ||
      (widget.versionUpdateInfo.forceUpdate &&
          widget.showDismissButtonOnForceUpdate);

  Future<void> updateAndroidApp() async {
    final Uri url = Uri.parse(widget.versionUpdateInfo.storeUrl);
    if (await canLaunchUrl(url)) {
      try {
        launchUrl(url, mode: widget.launchMode);
      } catch (e) {
        Fimber.e("couldn't open store");
      }
    }
  }

  Future<void> updateIosApp() async {
    final Uri url = Uri.parse(widget.versionUpdateInfo.storeUrl);
    if (await canLaunchUrl(url)) {
      try {
        launchUrl(url, mode: widget.launchMode);
      } catch (e) {
        Fimber.e("couldn't open store");
      }
    }
  }
}

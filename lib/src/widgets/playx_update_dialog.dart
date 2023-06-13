import 'dart:io';

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

  final VoidCallback? onUpdate;
  final Function(bool forceUpdate)? onCancel;
  final LaunchMode launchMode;

  const PlayxUpdateDialog({
    super.key,
    required this.versionUpdateInfo,
    this.title,
    this.description,
    this.releaseNotesTitle,
    this.showReleaseNotes = false,
    this.updateActionTitle,
    this.dismissActionTitle,
    this.showDismissButtonOnForceUpdate = true,
    this.launchMode = LaunchMode.externalApplication,
    this.onUpdate,
    this.onCancel,
  });

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
              widget.onCancel?.call(widget.versionUpdateInfo.forceUpdate);
            },
            child: Text(_getDismissActionTitle()),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, 'Update');
            PlayxVersionUpdate.openStore(
                storeUrl: widget.versionUpdateInfo.storeUrl,
                launchMode: widget.launchMode);
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
              widget.onCancel?.call(widget.versionUpdateInfo.forceUpdate);
            },
            child: Text(_getDismissActionTitle()),
          ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context, 'Update');
            widget.onUpdate?.call();
            PlayxVersionUpdate.openStore(
                storeUrl: widget.versionUpdateInfo.storeUrl,
                launchMode: widget.launchMode);
          },
          child: Text(widget.updateActionTitle ?? 'Update'),
        ),
      ],
    );
  }

  String _getTitleText() {
    String title = widget.title ?? 'New version available.';
    return title;
  }

  String _getDescriptionText() {
    String description = widget.description ??
        'A new version of the app is now available. \n \nWould you like to update now to version ${widget.versionUpdateInfo.newVersion} ?';
    return description;
  }

  String _getDismissActionTitle() {
    final forceUpdate = widget.versionUpdateInfo.forceUpdate;
    final defaultTitle = forceUpdate ? 'Close App' : 'Later';
    String title = widget.dismissActionTitle ?? defaultTitle;
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
}
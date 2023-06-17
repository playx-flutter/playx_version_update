import 'package:flutter/material.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/utils/callbacks.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayxUpdatePage extends StatefulWidget {
  final PlayxVersionUpdateInfo versionUpdateInfo;
  final UpdateNameInfoCallback? title;
  final UpdateNameInfoCallback? description;
  final UpdateNameInfoCallback? releaseNotesTitle;
  final bool showReleaseNotes;
  final bool showDismissButtonOnForceUpdate;
  final String? updateActionTitle;
  final String? dismissActionTitle;
  final UpdatePressedCallback? onUpdate;
  final UpdateCancelPressedCallback? onCancel;
  final LaunchMode launchMode;
  final Widget? leading;
  final bool? shouldPopOnBackPressed;

  const PlayxUpdatePage(
      {super.key,
      required this.versionUpdateInfo,
      this.title,
      this.description,
      this.releaseNotesTitle,
      this.showReleaseNotes = false,
      this.showDismissButtonOnForceUpdate = false,
      this.updateActionTitle,
      this.dismissActionTitle,
      this.onUpdate,
      this.onCancel,
      this.launchMode = LaunchMode.externalApplication,
      this.leading,
      this.shouldPopOnBackPressed});

  @override
  State<PlayxUpdatePage> createState() => _PlayxUpdatePageState();
}

class _PlayxUpdatePageState extends State<PlayxUpdatePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              if (widget.leading != null)
                SizedBox(
                  height: MediaQuery.of(context).size.height * (.5),
                  child: widget.leading,
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 8.0),
                      child: Text(
                        _getTitleText(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        // height: MediaQuery.of(context).size.height *
                        //     (widget.leading != null
                        //         ? shouldShowReleaseNotes
                        //             ? .2
                        //             : .1
                        //         : .5),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getDescriptionText(),
                                    style: TextStyle(
                                        fontSize:
                                            shouldShowReleaseNotes ? 16 : 18),
                                  ),
                                  if (shouldShowReleaseNotes) ...[
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        widget.releaseNotesTitle?.call(
                                                widget.versionUpdateInfo) ??
                                            'Release Notes:',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      widget.versionUpdateInfo.releaseNotes ??
                                          '',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ]
                                ]),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0, top: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25))),
                              onPressed: () {
                                if (widget.onUpdate != null) {
                                  widget.onUpdate?.call(
                                      widget.versionUpdateInfo,
                                      widget.launchMode);
                                } else {
                                  PlayxVersionUpdate.openStore(
                                      storeUrl:
                                          widget.versionUpdateInfo.storeUrl,
                                      launchMode: widget.launchMode);
                                }
                              },
                              child: Text(
                                widget.updateActionTitle ?? 'Update Now',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          if (shouldShowDismissButton)
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    )),
                                onPressed: () {
                                  widget.onCancel
                                      ?.call(widget.versionUpdateInfo);
                                },
                                child: Text(
                                  _getDismissActionTitle(),
                                  style: const TextStyle(
                                      fontSize: 18, color: Color(0xFFCCCBD2)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitleText() {
    String title = widget.title?.call(widget.versionUpdateInfo) ??
        'New Version available.';
    return title;
  }

  String _getDescriptionText() {
    String description = widget.description?.call(widget.versionUpdateInfo) ??
        'A new version of the app is now available. \nWould you like to update now to version ${widget.versionUpdateInfo.newVersion} ?';

    return description;
  }

  String _getDismissActionTitle() {
    final forceUpdate = widget.versionUpdateInfo.forceUpdate;
    final defaultTitle = forceUpdate ? 'Close App' : 'Not Now';
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

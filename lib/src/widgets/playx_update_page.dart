import 'package:flutter/material.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:playx_version_update/src/core/model/options/playx_update_ui_options.dart';


/// A full-screen Flutter widget designed to prompt users for an app update.
///
/// This page provides a customizable interface for displaying update information,
/// release notes, and action buttons. It's ideal for presenting mandatory
/// (force) updates or as an alternative to a dialog for non-force updates,
/// offering a more immersive user experience.
///
/// `PlayxUpdatePage` uses the styling and content defined in [uiOptions]
/// to render its elements, such as title, description, button texts, and
/// custom text styles.
///
/// This widget is a Flutter-based UI, meaning it provides a consistent look
/// and feel across both Android and iOS. It can be shown by setting the
/// `presentation` property in [PlayxUpdateUIOptions] to `PlayxUpdateDisplayType.page`
/// or `PlayxUpdateDisplayType.pageOnForceUpdate` when calling
/// [PlayxVersionUpdate.showUpdateDialog], or explicitly pushed onto the navigation
/// stack.
///
/// ### Usage:
/// Typically, you don't directly instantiate `PlayxUpdatePage` unless you
/// want to fully control its navigation. Instead, you configure it via
/// [PlayxUpdateUIOptions] and pass those options to [PlayxVersionUpdate.showUpdateDialog].
///
/// ### Example (indirect usage via showUpdateDialog):
/// ```dart
/// await PlayxVersionUpdate.showUpdateDialog(
///   context: context,
///   uiOptions: PlayxUpdateUIOptions(
///     presentation: PlayxUpdateDisplayType.page, // Force full-screen page
///     title: (info) => 'Time to Update!',
///     description: (info) => 'Version ${info.newVersion} is here with exciting new features!',
///     showReleaseNotes: true,
///     releaseNotesTitle: (info) => 'What\'s New:',
///     updateButtonText: 'Get the Update',
///     dismissButtonText: 'Maybe Later',
///     leading: Image.asset('assets/update_banner.png'),
///     titleTextStyle: const TextStyle(color: Colors.blue, fontSize: 28, fontWeight: FontWeight.bold),
///   ),
/// );
/// ```
///
/// ### Example (direct usage, e.g., for a critical update flow):
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => PlayxUpdatePage(
///       versionUpdateInfo: PlayxVersionUpdateInfo(
///         localVersion: '1.0.0',
///         newVersion: '1.0.1',
///         canUpdate: true,
///         forceUpdate: true, // Example: Assume a critical update
///         storeUrl: '[https://example.com/appstore_link](https://example.com/appstore_link)',
///         releaseNotes: 'Fixed critical bug.\nImproved performance.',
///       ),
///       uiOptions: PlayxUpdateUIOptions(
///         presentation: PlayxUpdateDisplayType.page,
///         title: (info) => 'Critical Update Required!',
///         isDismissible: false, // Make it non-dismissible
///         dismissButtonText: 'Exit App', // Custom text for forced exit
///       ),
///     ),
///   ),
/// );
/// ```
///
/// @see [PlayxUpdateUIOptions] for all available customization options.
/// @see [PlayxUpdateDisplayType] for presentation types.
/// @see [PlayxVersionUpdate.showUpdateDialog] for the primary way to trigger this UI.
class PlayxUpdatePage extends StatefulWidget {
  /// Information about the available update, including current and new versions,
  /// whether an update is available, force update status, and store URL.
  final PlayxVersionUpdateInfo versionUpdateInfo;

  /// Options for customizing the visual appearance and behavior of the update page.
  /// This includes text content, styles, button actions, and dismissibility.
  final PlayxUpdateUIOptions uiOptions;


  const PlayxUpdatePage(
      {super.key,
        required this.versionUpdateInfo,
        this.uiOptions = const PlayxUpdateUIOptions(),
      });

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
              if (widget.uiOptions.leading != null)
                SizedBox(
                  height: MediaQuery.of(context).size.height * (.5),
                  child: widget.uiOptions.leading,
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
                        style:widget.uiOptions.titleTextStyle?? const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getDescriptionText(),
                                    style: widget.uiOptions.descriptionTextStyle??TextStyle(
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
                                        widget.uiOptions.releaseNotesTitle?.call(
                                                widget.versionUpdateInfo) ??
                                            'Release Notes:',
                                        textAlign: TextAlign.center,
                                        style:widget.uiOptions.releaseNotesTitleTextStyle?? const TextStyle(
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
                                      style: widget.uiOptions.releaseNotesTextStyle??const TextStyle(fontSize: 15),
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
                              style:widget.uiOptions.updateButtonStyle?? ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25))),
                              onPressed: () {
                                if (widget.uiOptions.onUpdate != null) {
                                  widget.uiOptions.onUpdate?.call(
                                      widget.versionUpdateInfo,
                                      widget.uiOptions.launchMode);
                                } else {
                                  PlayxVersionUpdate.openStore(
                                      storeUrl:
                                          widget.versionUpdateInfo.storeUrl,
                                      launchMode: widget.uiOptions.launchMode);
                                }
                              },
                              child: Text(
                                widget.uiOptions.updateButtonText,
                                style: widget.uiOptions.updateButtonTextStyle??const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          if (shouldShowDismissButton)
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextButton(
                                style:widget.uiOptions.dismissButtonStyle?? TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    )),
                                onPressed: () {
                                  widget.uiOptions.onCancel
                                      ?.call(widget.versionUpdateInfo);
                                },
                                child: Text(
                                  _getDismissActionTitle(),
                                  style: widget.uiOptions.dismissButtonTextStyle??const TextStyle(
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
    String title = widget.uiOptions.title?.call(widget.versionUpdateInfo) ??
        'New Version available.';
    return title;
  }

  String _getDescriptionText() {
    String description = widget.uiOptions.description?.call(widget.versionUpdateInfo) ??
        'A new version of the app is now available. \nWould you like to update now to version ${widget.versionUpdateInfo.newVersion} ?';

    return description;
  }

  String _getDismissActionTitle() {
    final forceUpdate = widget.versionUpdateInfo.forceUpdate;
    final defaultTitle = forceUpdate ? 'Close App' : 'Not Now';
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

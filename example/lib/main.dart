
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playx_version_update/playx_version_update.dart';

final GlobalKey<ScaffoldMessengerState> globalKey =
GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(MaterialApp(
    home: const MyApp(),
    scaffoldMessengerKey: globalKey,
    debugShowCheckedModeBanner: false, // For cleaner example
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<PlayxDownloadInfo?>? downloadInfoStreamSubscription;
  String message = '';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
      WidgetsBinding.instance.addObserver(this);
      listenToFlexibleDownloadUpdates();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && Platform.isAndroid) {
      WidgetsBinding.instance.removeObserver(this);
    }
    downloadInfoStreamSubscription?.cancel();
    downloadInfoStreamSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playx Version Update Example'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final version = await PlayxVersionUpdate.getAppVersion();
                setState(() {
                  message = 'App Version: v$version';
                });
              },
              child: const Text('Get App Version'),
            ),
            ElevatedButton(
              onPressed: () {
                checkVersion(context);
              },
              child: const Text('Check Version (Custom UI)'),
            ),
            ElevatedButton(
              onPressed: () {
                showUpdateDialog(context);
              },
              child: const Text('Show Update Dialog (Customizable)'),
            ),
            ElevatedButton(
              onPressed: () {
                checkPlayAvailability(context);
              },
              child: const Text('Check Play Store Availability'),
            ),
            ElevatedButton(
              onPressed: () {
                startImmediateUpdate(context);
              },
              child: const Text('Start Immediate Update (Android/iOS)'),
            ),
            ElevatedButton(
              onPressed: () {
                startFlexibleUpdate(context);
              },
              child: const Text('Start Flexible Update (Android/iOS)'),
            ),
          ],
        ),
      ),
    );
  }

  /// Check if flexible update needs to be installed on app resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && Platform.isAndroid) {
      if (state == AppLifecycleState.resumed) {
        checkIfFlexibleUpdateNeedToBeInstalled();
      }
    }
  }

  Future<void> showUpdateDialog(BuildContext context) async {
    final result = await PlayxVersionUpdate.showUpdateDialog(
      context: context,
      options: const PlayxUpdateOptions(
        androidPackageName: 'com.google.android.apps.bard',
        iosBundleId: 'com.apple.shortcuts',
        forceUpdate: false,
      ),
      uiOptions: PlayxUpdateUIOptions(
        // Display Options
        displayType: PlayxUpdateDisplayType.dialog,
        isDismissible: true,
        showReleaseNotes: true,

        // Leading Image
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            'https://img.freepik.com/premium-vector/concept-system-update-software-installation-premium-vector_199064-146.jpg',
            height: 100,
            width: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.system_update_alt, size: 64),
          ),
        ),

        // Text & Style
        title: (info) => '🚀 A New Update is Available!',
        titleTextStyle: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        description: (info) => 'Version ${info.newVersion} is ready with exciting new features and enhancements. Update now to enjoy the latest improvements!',
        descriptionTextStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        releaseNotesTitle: (info) => '✨ What\'s New in ${info.newVersion}:',
        releaseNotesTitleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
        releaseNotesTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          height: 1.4,
        ),

        // Buttons
        updateButtonText: 'Update Now',
        updateButtonTextStyle: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        updateButtonStyle: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dismissButtonText: 'Remind Me Later',
        dismissButtonTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.redAccent,
        ),
        dismissButtonStyle: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
        ),

        // Actions
        onUpdate: (info, launchMode) async {
          setState(() {
            message = 'Update button pressed. Opening store...';
          });

          final res = await PlayxVersionUpdate.openStore(
            storeUrl: info.storeUrl,
            launchMode: launchMode,
          );

          res.when(
            success: (success) {
              debugPrint('✅ playx_open_store success: $success');
            },
            error: (error) {
              debugPrint('❌ playx_open_store error: $error');
              _showMessage('Failed to open store: ${error.message}', isError: true);
            },
          );
        },
        onCancel: (info) {
          setState(() {
            message = 'Dismiss button pressed.';
          });
          // Optionally handle force update here: SystemNavigator.pop();
        },
      ),
    );

    result.when(
      success: (isShown) {
        setState(() {
          message = 'Update dialog displayed: $isShown';
        });
      },
      error: (error) {
        setState(() {
          message = 'Error showing update dialog: ${error.message}';
        });
        _showMessage('Something went wrong: ${error.message}', isError: true);
      },
    );
  }

  /// Initiates a Flexible In-App Update flow.
  /// On Android, this uses the native Google Play In-App Updates Flexible flow.
  /// On iOS, this falls back to showing a custom Flutter page with customization options.
  Future<void> startFlexibleUpdate(BuildContext context) async {
    final result = await PlayxVersionUpdate.showInAppUpdateDialog(
      context: context,
      type: PlayxAppUpdateType.flexible,
      options: PlayxUpdateOptions(
        iosBundleId: 'com.apple.shortcuts', // Example bundle ID for iOS
      ),
      iosUiOptions: PlayxUpdateUIOptions(
        // These UI options apply only to the custom Flutter UI shown on iOS
        // or if a non-native fallback is implemented for Android.
        // For Android native Flexible update, Google Play controls the UI.
        showReleaseNotes: true,
        releaseNotesTitle: (info) => 'Recent Updates of ${info.newVersion}',
        title: (info) => 'Flexible Update Available!',
        description: (info) =>
        'A new version is ready for download. You can continue using the app while it downloads.',
        updateButtonText: 'Download & Install',
        dismissButtonText: 'Not Now',
        isDismissible: true, // Flexible update should be dismissible
        onUpdate: (info, launchMode) async {
          setState(() {
            message = 'iOS: Flexible Update button pressed. Opening store...';
          });
          final res = await PlayxVersionUpdate.openStore(
            storeUrl: info.storeUrl,
            launchMode: launchMode,
          );
          res.when(
            success: (success) {
              if (kDebugMode) print('iOS store open success :$success');
            },
            error: (error) {
              if (kDebugMode) print('iOS store open error :$error');
              _showMessage('iOS: Failed to open store: ${error.message}',
                  isError: true);
            },
          );
        },
        onCancel: (info) {
          setState(() {
            message = 'iOS: Flexible Update cancelled.';
          });
          // For flexible, cancelling is usually fine.
        },
      ),
    );

    result.when(
      success: (isShowed) {
        setState(() {
          message = 'showInAppUpdateDialog (Flexible) success: $isShowed';
        });
      },
      error: (error) {
        setState(() {
          message =
          'showInAppUpdateDialog (Flexible) error: ${error.message}';
        });
      },
    );
  }

  /// Initiates an Immediate In-App Update flow.
  /// On Android, this uses the native Google Play In-App Updates Immediate flow.
  /// On iOS, this falls back to showing a custom Flutter dialog/page.
  Future<void> startImmediateUpdate(BuildContext context) async {
    final result = await PlayxVersionUpdate.showInAppUpdateDialog(
      context: context,
      type: PlayxAppUpdateType.immediate,
      options: PlayxUpdateOptions(
        iosBundleId: 'com.apple.shortcuts', // Example bundle ID for iOS
      ),
      iosUiOptions: PlayxUpdateUIOptions(
        // These UI options apply only to the custom Flutter UI shown on iOS
        // For Android native Immediate update, Google Play controls the UI.
        showReleaseNotes: true,
        releaseNotesTitle: (info) => 'Critical Updates',
        title: (info) => 'Immediate Update Required!',
        description: (info) =>
        'This update is mandatory to continue using the app. Please update now.',
        updateButtonText: 'Update & Restart',
        // Immediate updates are typically not dismissible.
        isDismissible: false,
        onCancel: (info) {
          setState(() {
            message = 'iOS: Immediate Update cancelled/exited.';
          });
          // For immediate update, cancelling often means exiting the app.
          SystemNavigator.pop();
        },
      ),
    );

    result.when(
      success: (isShowed) {
        setState(() {
          message = 'showInAppUpdateDialog (Immediate) success: $isShowed';
        });
      },
      error: (error) {
        setState(() {
          message =
          'showInAppUpdateDialog (Immediate) error: ${error.message}';
        });
      },
    );
  }

  /// Listens to flexible download updates on Android.
  void listenToFlexibleDownloadUpdates() {
    downloadInfoStreamSubscription =
        PlayxVersionUpdate.listenToFlexibleDownloadUpdate().listen((info) {
          if (info == null) return;
          if (info.status == PlayxDownloadStatus.downloaded) {
            setState(() {
              message = 'Downloaded, trying to complete update';
            });
            completeFlexibleUpdate();
          } else if (info.status == PlayxDownloadStatus.downloading) {
            setState(() {
              message =
              'Current download in progress: ${info.bytesDownloaded} / ${info.totalBytesToDownload} bytes';
            });
          } else if (info.status == PlayxDownloadStatus.failed) {
            _showMessage('Flexible update download failed!', isError: true);
          }
        });
  }

  /// Checks for app version and demonstrates showing custom UI based on force update status.
  Future<void> checkVersion(BuildContext context) async {
    final result = await PlayxVersionUpdate.checkVersion(
      options: PlayxUpdateOptions(
        forceUpdate: false, // Set to true to test the PlayxUpdatePage flow
        androidPackageName: 'io.sourcya.playx.verion.update.example', // Example package name
        iosBundleId: 'com.apple.shortcuts', // Example bundle ID
      ),
    );

    result.when(
      success: (info) {
        setState(() {
          message =
          'Check version successful: ${info.newVersion} | Can update: ${info.canUpdate} | Force update: ${info.forceUpdate}';
        });

        if (info.forceUpdate) {
          // If it's a force update, push PlayxUpdatePage and remove all previous routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => PlayxUpdatePage(
                versionUpdateInfo: info,
                uiOptions: PlayxUpdateUIOptions(
                  // Configure PlayxUpdatePage specifically
                  displayType: PlayxUpdateDisplayType.pageOnForceUpdate, // It's a full page for force update
                  isDismissible: false, // Force update page is not dismissible
                  showReleaseNotes: false, // No release notes on this one
                  leading: Image.network(
                    'https://img.freepik.com/premium-vector/concept-system-update-software-installation-premium-vector_199064-146.jpg',
                    fit: BoxFit.contain,
                    height: 200,
                  ),
                  title: (info) => "Time to Update Your App!",
                  titleTextStyle: const TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 25,
                      fontWeight: FontWeight.bold),
                  description: (info) =>
                  'A new version of the app is now available.\n'
                      'The app needs to be updated to the latest version (V${info.newVersion}) in order to work properly.\n'
                      'Update now to enjoy the latest features and bug fixes.',
                  descriptionTextStyle: const TextStyle(fontSize: 16, color: Colors.black54),
                  updateButtonText: 'Update App Now',
                  updateButtonTextStyle: const TextStyle(fontSize: 18, color: Colors.white),
                  updateButtonStyle: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  // For a force update page, the dismiss button should typically be hidden
                  // or lead to app exit. Since isDismissible is false, the button won't show.
                  onCancel: (info) {
                    // This callback would only be invoked if isDismissible was true
                    // and the user managed to dismiss it or pressed a custom dismiss button.
                    SystemNavigator.pop(); // Exit app on cancel for force update
                  },
                ),
              ),
            ),
                (route) => false, // Remove all routes below this page
          );
        } else if (info.canUpdate) {
          // If update is available but not forced, show PlayxUpdateDialog
          showDialog(
            context: context,
            barrierDismissible: info.forceUpdate ? false : true, // Dialog dismissible based on force update
            builder: (context) => PlayxUpdateDialog(
              versionUpdateInfo: info,
              uiOptions: PlayxUpdateUIOptions(
                // Configure PlayxUpdateDialog
                displayType: PlayxUpdateDisplayType.dialog, // Explicitly a dialog
                showReleaseNotes: true,
                title: (info) => 'New Update Available!',
                titleTextStyle: const TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                description: (info) =>
                'Update to V${info.newVersion} to get the latest features.',
                updateButtonText: 'Update',
                dismissButtonText: 'Later',
                isDismissible: !info.forceUpdate, // Allow dismissal if not forced
              ),
            ),
          );
        } else {
          _showMessage('App is up to date!', isError: false);
        }
      },
      error: (error) {
        // network related errors
        if(error is NetworkException){
          if(error is NoInternetConnectionException){
            _showMessage('No internet connection. Please check your network settings.', isError: true);
          } else {
            _showMessage('Network error: ${error.message}', isError: true);
          }
        }else {
          _showMessage('Version check failed: ${error.message}', isError: true);
        }
        setState(() {
          message = 'Check version error: ${error.message}';
        });
      },
    );
  }

  /// Checks the availability of in-app updates.
  Future<void> checkPlayAvailability(BuildContext context) async {
    final result = await PlayxVersionUpdate.getUpdateAvailability();
    result.when(
      success: (availability) {
        setState(() {
          message = 'In-app Update Availability: $availability';
        });
      },
      error: (error) {
        setState(() {
          message = 'Check Play Availability error: ${error.message}';
        });
        _showMessage('Availability check failed: ${error.message}', isError: true);
      },
    );
  }

  /// Completes an update that is downloaded and needs to be installed,
  /// typically by showing a snack bar.
  Future<void> completeFlexibleUpdate() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final snackBar = SnackBar(
        content: const Text('An update has just been downloaded.'),
        action: SnackBarAction(
            label: 'Restart',
            onPressed: () async {
              final result = await PlayxVersionUpdate.completeFlexibleUpdate();
              result.when(
                success: (isCompleted) {
                  setState(() {
                    message = 'Flexible update completed: $isCompleted';
                  });
                },
                error: (error) {
                  setState(() {
                    message =
                    'Flexible update completion error: ${error.message}';
                  });
                  _showMessage('Update completion failed: ${error.message}',
                      isError: true);
                },
              );
            }),
        duration: const Duration(seconds: 10),
      );

      globalKey.currentState?.showSnackBar(snackBar);
    });
  }

  /// Checks whether there's a flexible update that needs to be installed.
  /// If there's an update, it shows a snack bar to prompt the user to install it.
  Future<void> checkIfFlexibleUpdateNeedToBeInstalled() async {
    final result = await PlayxVersionUpdate.isFlexibleUpdateNeedToBeInstalled();
    result.when(
      success: (isNeeded) {
        if (isNeeded) {
          completeFlexibleUpdate();
        }
      },
      error: (error) {
        setState(() {
          message =
          'Check Flexible update installation need error: ${error.message}';
        });
        _showMessage('Flexible update check failed: ${error.message}',
            isError: true);
      },
    );
  }

  void _showMessage(String msg, {bool isError = false}) {
    globalKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

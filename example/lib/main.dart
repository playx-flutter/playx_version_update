import 'dart:async';
import 'dart:io' show Platform, exit;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:playx_version_update/playx_version_update.dart';

final GlobalKey<ScaffoldMessengerState> globalKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(MaterialApp(
    home: const MyApp(),
    scaffoldMessengerKey: globalKey,
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
        title: const Text('Playx Version Update'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Text(message),
            ElevatedButton(
              onPressed: () async {
                final version = await PlayxVersionUpdate.getAppVersion();
                setState(() {
                  message = 'Version: v$version';
                });
              },
              child: const Text('App Version'),
            ),
            ElevatedButton(
              onPressed: () {
                checkVersion(context);
              },
              child: const Text('Check version'),
            ),
            ElevatedButton(
              onPressed: () {
                showUpdateDialog(context);
              },
              child: const Text('Show update dialog'),
            ),
            ElevatedButton(
              onPressed: () {
                checkPlayAvailability(context);
              },
              child: const Text('Check store availability'),
            ),
            ElevatedButton(
              onPressed: () {
                startImmediateUpdate(context);
              },
              child: const Text('Start immediate Update'),
            ),
            ElevatedButton(
              onPressed: () {
                startFlexibleUpdate(context);
              },
              child: const Text('Start Flexible Update'),
            ),
          ],
        ),
      ),
    );
  }

  ///check if flexible update needs to be installed on app resume.
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
        showReleaseNotes: false,
        googlePlayId: 'google play id',
        appStoreId: 'app store bundle id',
        forceUpdate: true,
        isDismissible: true,
        title: (info) => 'A new update is available',
        onUpdate: (info, launchMode) async {
          final storeUrl = info.storeUrl;
          print('store url :$storeUrl');
          final res = await PlayxVersionUpdate.openStore(storeUrl: storeUrl);
          res.when(success: (success) {
            print('playx_open_store: success :$success');
          }, error: (error) {
            print('playx_open_store: error :$error');
          });
        },
        onCancel: (info) {
          final forceUpdate = info.forceUpdate;
          if (forceUpdate) {
            exit(0);
          }
        });
    result.when(success: (isShowed) {
      setState(() {
        message = ' showUpdateDialog success : $isShowed';
      });
    }, error: (error) {
      setState(() {
        message = ' showUpdateDialog error : $error ${error.message}';
      });
    });
  }

  Future<void> startFlexibleUpdate(BuildContext context) async {
    final result = await PlayxVersionUpdate.showInAppUpdateDialog(
        context: context,
        type: PlayxAppUpdateType.flexible,
        appStoreId: 'app store bundle id',
        showReleaseNotes: true,
        releaseNotesTitle: (info) => 'Recent Updates of ${info.newVersion}',
        forceUpdate: true,
        showPageOnForceUpdate: true,
        onIosUpdate: (info, launchMode) async {
          final storeUrl = info.storeUrl;

          final res = await PlayxVersionUpdate.openStore(storeUrl: storeUrl);
          res.when(success: (success) {
            print('playx_open_store: success :$success');
          }, error: (error) {
            print('playx_open_store: error :$error');
          });
        },
        onIosCancel: (info) {
          final forceUpdate = info.forceUpdate;
          if (forceUpdate) {
            exit(0);
          } else {
            //Do nothing
          }
        });
    result.when(success: (isShowed) {
      setState(() {
        message = ' showInAppUpdateDialog success : $isShowed';
      });
    }, error: (error) {
      setState(() {
        message = ' showInAppUpdateDialog error : $error ${error.message}';
      });
    });
  }

  Future<void> startImmediateUpdate(BuildContext context) async {
    final result = await PlayxVersionUpdate.showInAppUpdateDialog(
      context: context,
      type: PlayxAppUpdateType.immediate,
      appStoreId: 'app store bundle id',
      //These for
      showReleaseNotes: true,
      releaseNotesTitle: (info) => 'Recent Updates',
    );
    result.when(success: (isShowed) {
      setState(() {
        message = ' showInAppUpdateDialog success : $isShowed';
      });
    }, error: (error) {
      setState(() {
        message = ' showInAppUpdateDialog error : $error ${error.message}';
      });
    });
  }

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
              'current download in progress : downloading :${info.bytesDownloaded} total to download : ${info.totalBytesToDownload}';
        });
      }
    });
  }

  Future<void> checkVersion(BuildContext context) async {
    final result = await PlayxVersionUpdate.checkVersion(
      localVersion: '1.0.0',
      newVersion: '1.1.0',
      forceUpdate: false,
      googlePlayId: 'google play id',
      appStoreId: 'app store bundle id',
      country: 'us',
      language: 'en',
    );

    result.when(success: (info) {
      setState(() {
        message =
            ' check version successfully :${info.newVersion} can update :${info.canUpdate}';
      });
      // decides what to show
      if (info.forceUpdate) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => PlayxUpdatePage(
              versionUpdateInfo: info,
              showReleaseNotes: false,
              showDismissButtonOnForceUpdate: false,
              leading: Image.network(
                'https://img.freepik.com/premium-vector/concept-system-update-software-installation-premium-vector_199064-146.jpg',
                fit: BoxFit.cover,
              ),
              title: (info) => "It's time to update",
              description: (info) =>
                  'A new version of the app is now available.\n'
                  'The app needs to be updated to the latest version in order to work properly.\n'
                  'Update now to V${info.newVersion} to enjoy the latest version features now.',
            ),
          ),
          (route) => false,
        );
      } else {
        showDialog(
            context: context,
            builder: (context) => PlayxUpdateDialog(
                  versionUpdateInfo: info,
                  showReleaseNotes: true,
                  title: (info) => 'New update available.',
                ));
      }
    }, error: (error) {
      setState(() {
        message = ' check version error :${error.message}';
      });
    });
  }

  Future<void> checkPlayAvailability(BuildContext context) async {
    final result = await PlayxVersionUpdate.getUpdateAvailability();
    result.when(success: (availability) {
      setState(() {
        message = ' checkPlayAvailability :$availability';
      });
    }, error: (error) {
      setState(() {
        message = ' checkPlayAvailability error : $error ${error.message}';
      });
    });
  }

  ///Completes an update that is downloaded and needs to be installed as it shows snack bar to ask the user to install the update.
  Future<void> completeFlexibleUpdate() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final snackBar = SnackBar(
        content: const Text('An update has just been downloaded.'),
        action: SnackBarAction(
            label: 'Restart',
            onPressed: () async {
              final result = await PlayxVersionUpdate.completeFlexibleUpdate();
              result.when(success: (isCompleted) {
                setState(() {
                  message =
                      ' completeFlexibleUpdate isCompleted : $isCompleted ';
                });
              }, error: (error) {
                setState(() {
                  message =
                      ' checkPlayAvailability error : $error ${error.message}';
                });
              });
            }),
        duration: const Duration(seconds: 10),
      );

      globalKey.currentState?.showSnackBar(snackBar);
    });
  }

  ///check whether there's an update needs to be installed.
  ///If there's an update needs to be installed shows snack bar to ask the user to install the update.
  Future<void> checkIfFlexibleUpdateNeedToBeInstalled() async {
    final result = await PlayxVersionUpdate.isFlexibleUpdateNeedToBeInstalled();
    result.when(success: (isNeeded) {
      if (isNeeded) {
        completeFlexibleUpdate();
      }
    }, error: (error) {
      setState(() {
        message =
            ' checkIfFlexibleUpdateNeedToBeInstalled error :$error :${error.message}';
      });
    });
  }
}

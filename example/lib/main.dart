import 'dart:async';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:playx_version_update/playx_version_update.dart';

final logger = FimberLog("PLAYX_VERSION_UPDATE 2");

void main() {
  Fimber.plantTree(DebugTree());

  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<PlayxDownloadInfo?>? downloadInfoStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    listenToFlexibleDownloadUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    downloadInfoStreamSubscription?.cancel();
    downloadInfoStreamSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                showInAppUpdateDialog(context);
              },
              child: const Text('Show in app update dialog'),
            ),
            ElevatedButton(
              onPressed: () {
                checkPlayAvailability(context);
              },
              child: const Text('Check store avialabilty'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //check if flexible update needs to be installed on app resume.
    if (state == AppLifecycleState.resumed) {
      completeFlexibleUpdate(context);
    }
  }

  Future<void> showUpdateDialog(BuildContext context) async {
    final result = await PlayxVersionUpdate.showUpdateDialog(
        context: context,
        googlePlayId: 'com.kiloo.subwaysurf',
        appStoreId: 'com.apple.tv',
        showReleaseNotes: true,
        releaseNotesTitle: 'Recent Updates');
    result.when(success: (isShowed) {
      logger.d(' showUpdateDialog success : $isShowed');
    }, error: (error) {
      logger.e(' showUpdateDialog error : $error ${error.message}');
    });
  }

  Future<void> showInAppUpdateDialog(BuildContext context) async {
    final result = await PlayxVersionUpdate.showInAppUpdateDialog(
      context: context,
      type: PlayxAppUpdateType.flexible,
      //These for
      googlePlayId: 'com.kiloo.subwaysurf',
      appStoreId: 'com.apple.tv',
      showReleaseNotes: true,
      releaseNotesTitle: 'Recent Updates',
    );
    result.when(success: (isShowed) {
      logger.d(' showUpdateDialog success : $isShowed');
    }, error: (error) {
      logger.e(' showUpdateDialog error : $error ${error.message}');
    });
  }

  void listenToFlexibleDownloadUpdates() {
    downloadInfoStreamSubscription =
        PlayxVersionUpdate.listenToFlexibleDownloadUpdate().listen((info) {
      if (info == null) return;
      if (info.status == PlayxDownloadStatus.downloaded) {
        completeFlexibleUpdate(context);
      } else if (info.status == PlayxDownloadStatus.downloading) {
        logger.d(
            'current download in progress : downloaded :${info.bytesDownloaded} total to download : ${info.totalBytesToDownload}');
      }
    });
  }

  Future<void> checkVersion(BuildContext context) async {
    final result = await PlayxVersionUpdate.checkVersion(
        googlePlayId: 'com.kiloo.subwaysurf', appStoreId: 'com.apple.tv');

    result.when(success: (info) {
      logger.d(
          ' check version successfully :$info can update :${info.canUpdate}');

      // decides what to show
      if (info.forceUpdate) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => PlayxUpdatePage(
              versionUpdateInfo: info,
              showReleaseNotes: false,
              showDismissButtonOnForceUpdate: false,
              leading: Image.network(
                  'https://img.freepik.com/premium-vector/concept-system-update-software-installation-premium-vector_199064-146.jpg'),
              title: "It's time to update",
              description:
                  'A new version of the app is now available.\nThe app needs to be updated to the latest version in order to work properly.\nEnjoy the latest version features now.',
            ),
          ),
        );
      } else {
        showDialog(
            context: context,
            builder: (context) => PlayxUpdateDialog(
                  versionUpdateInfo: info,
                  showReleaseNotes: true,
                  title: 'New update available.',
                ));
      }
    }, error: (error) {
      logger.d(' check version error :${error.message}');
    });
  }

  Future<void> checkPlayAvailability(BuildContext context) async {
    logger.d(' checkPlayAvailability :');
    final result = await PlayxVersionUpdate.getUpdateAvailability();
    result.when(success: (availability) {
      logger.d(' checkPlayAvailability :$availability');
    }, error: (error) {
      logger.d(' checkPlayAvailability error : $error ${error.message}');
    });
  }

  ///check whether there's an update needs to be installed.
  ///If there's an update needs to be installed shows snack bar to ask the user to install the update.
  Future<void> completeFlexibleUpdate(BuildContext context) async {
    final result = await PlayxVersionUpdate.isFlexibleUpdateNeedToBeInstalled();
    result.when(
        success: (isNeeded) {
          if (isNeeded) {
            final snackBar = SnackBar(
              content: const Text('An update has just been downloaded.'),
              action: SnackBarAction(
                  label: 'Restart',
                  onPressed: () async {
                    final result =
                        await PlayxVersionUpdate.completeFlexibleUpdate();
                    result.when(success: (isCompleted) {
                      logger.d(' Flexible update is $isCompleted');
                    }, error: (error) {
                      logger.d(
                          ' Flexible update error : $error ${error.message}');
                    });
                  }),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
        error: (error) {});
  }
}

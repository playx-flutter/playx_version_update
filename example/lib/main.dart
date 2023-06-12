import 'dart:async';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:playx_version_update/playx_version_update.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            checkVersion(context);
          },
          child: Text('Check version'),
        ),
      ),
    );
  }

  Future<void> checkVersion(BuildContext context) async {
    Fimber.plantTree(DebugTree());
    final result = await PlayxVersionUpdate.checkVersion(
        googlePlayId: 'com.kiloo.subwaysurf', appStoreId: 'com.apple.tv');
    result.when(success: (info) {
      Fimber.d(' check version successfully :$info');

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
      Fimber.d(' check version error :${error.message}');
    });
  }
}

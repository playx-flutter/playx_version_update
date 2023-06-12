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
        googlePlayId: 'io.sourcya.tmt.track', appStoreId: 'com.apple.tv');
    result.when(success: (info) {
      Fimber.d(' check version successfully :$info');
      showDialog(
          context: context,
          builder: (context) => PlayxUpdateDialog(
                versionUpdateInfo: info,
                showReleaseNotes: true,
                title: 'New update available.',
              ));
    }, error: (error) {
      Fimber.d(' check version error :${error.message}');
    });
  }
}

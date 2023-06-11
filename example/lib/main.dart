import 'dart:async';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:playx_version_update/playx_version_update.dart';

void main() {
  runApp(const MyApp());
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
    checkVersion();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on:'),
        ),
      ),
    );
  }

  Future<void> checkVersion() async {
    Fimber.plantTree(DebugTree());
    final result = await PlayxVersionUpdate.checkVersion(
        playxVersion:
            PlayxVersion(googlePlayId: 'pdf.reader.pdfviewer.pdfeditor'));

    result.when(success: (info) {
      Fimber.d(' check version successfully :$info');
    }, error: (error) {
      Fimber.d(' check version error :${error.message}');
    });
  }
}

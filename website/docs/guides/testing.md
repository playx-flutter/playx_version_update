---
id: testing
title: Testing
sidebar_position: 13
---

# Testing your integration

## Without the stores

Use a [version source](./version-sources.md) with fixed values: the check never touches the network and
there is always an update to show.

```dart
final options = PlayxUpdateOptions(
  localVersion: '1.0.0', // pretend this is the installed version
  versionSource: PlayxStaticVersionSource(
    version: PlayxPlatformVersion(
      android: '99.0.0',
      ios: '99.0.0',
      macos: '99.0.0',
    ),
  ),
);

await PlayxVersionUpdate.showUpdateDialog(context: context, options: options);
```

`localVersion` replaces the installed version, and `forceUpdate: true` or a `minVersion` above it lets you
see the forced update page.

## In widget tests

Register a source that returns what you need, and set the platform the dialog should render for:

```dart
testWidgets('shows the update dialog', (tester) async {
  PackageInfo.setMockInitialValues(
    appName: 'App',
    packageName: 'com.example.app',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );

  // ... pump a MaterialApp and call showUpdateDialog with a static source
});
```

The dialog renders on Android, iOS and macOS. Tests that run on another host need a platform override,
which is how this package's own tests run on every machine.

## With the real stores

The example app has an integration test that reads real apps from the real stores:

```bash
cd example
flutter test integration_test -d macos   # or an Android / iOS device
```

## Android in-app updates {#android-in-app-updates}

In-app updates **only work for apps installed from Google Play**. A build installed from Android Studio or
a local APK does not get them. To test:

1. **Publish an older version** to at least an **Internal testing** track in the Google Play Console.
   [Internal app sharing](https://developer.android.com/guide/playcore/in-app-updates/test) is a quicker way
   to iterate.
2. **Install it from Google Play** on the device or emulator, with a Google account that is a tester of
   that track, and open it once.
3. **Upload a newer version** to the same track, with a higher `versionCode` and `versionName`, containing
   your integration.
4. **Wait** for Google Play to process it. This can take minutes to hours. Clearing the Play Store cache or
   restarting the device sometimes helps.
5. **Open the older version.** It should now see the update. For a flexible update remember to
   [follow the download and prompt to install](./android-in-app-updates.md#flexible-update), and to check for
   an already downloaded update first.

Google's own guide: [Test in-app updates](https://developer.android.com/guide/playcore/in-app-updates/test).

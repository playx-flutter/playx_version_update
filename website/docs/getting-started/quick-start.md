---
id: quick-start
title: Quick start
sidebar_position: 2
---

# Quick start

## Ask users to update

The simplest integration is one call. It checks the store, compares versions, and shows a dialog if
there is a newer version:

```dart
await PlayxVersionUpdate.showUpdateDialog(context: context);
```

Call it when your app starts (for example from your home screen's `initState` with
`WidgetsBinding.instance.addPostFrameCallback`) or from a button.

By default the package uses the app's own package name or bundle id, the stores of the user's
platform, and a standard dialog. A forced update shows a full-screen page instead.

## Add the options you need

```dart
await PlayxVersionUpdate.showUpdateDialog(
  context: context,
  options: PlayxUpdateOptions(
    country: 'us',
    language: 'en',
  ),
  uiOptions: PlayxUpdateUIOptions(
    showReleaseNotes: true,
    updateButtonText: 'Update now',
    dismissButtonText: 'Later',
  ),
  // Remember "Later", and let users skip this version.
  reminderOptions: PlayxUpdateReminderOptions(
    snoozeDuration: Duration(days: 3),
    allowSkipVersion: true,
  ),
);
```

## Only check the version

If you want to build your own UI, use `checkVersion`:

```dart
final result = await PlayxVersionUpdate.checkVersion();

result.when(
  success: (info) {
    if (info.canUpdate) {
      print('Update ${info.localVersion} -> ${info.newVersion}');
      print('Forced: ${info.forceUpdate}');
    }
  },
  error: (error) => print('${error.errorCode}: ${error.message}'),
);
```

## Android in-app updates

On Android you can let Google Play download and install the update without leaving your app. On iOS
and macOS the same call shows the update dialog:

```dart
await PlayxVersionUpdate.showInAppUpdateDialog(
  context: context,
  type: PlayxAppUpdateType.flexible, // or PlayxAppUpdateType.immediate
);
```

## What's next

- [Check for updates](../guides/check-for-updates.md) explains the result and the options.
- [Update dialog and page](../guides/update-dialog-and-page.md) shows how to present updates.
- [Android in-app updates](../guides/android-in-app-updates.md) covers flexible updates in depth.

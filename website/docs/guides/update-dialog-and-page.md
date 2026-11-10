---
id: update-dialog-and-page
title: Update dialog and page
sidebar_position: 2
---

# Update dialog and page

## `showUpdateDialog`

`showUpdateDialog` checks the version and presents the update if there is one:

```dart
final result = await PlayxVersionUpdate.showUpdateDialog(
  context: context,
  options: PlayxUpdateOptions(),
  uiOptions: PlayxUpdateUIOptions(),
);
```

| Platform | Presentation |
| --- | --- |
| Android | Material `AlertDialog` |
| iOS, macOS | `CupertinoAlertDialog` |
| a forced update | by default a full-screen `PlayxUpdatePage`, see below |

The returned result tells what happened:

| Result | Meaning |
| --- | --- |
| `success(true)` | the dialog or page was shown |
| `success(false)` | an update exists, but the prompt was suppressed because the user chose "Later" or "Skip" before, see [Later and Skip](./later-and-skip.md) |
| `error(PlayxVersionCantUpdateError)` | the app is already up to date |
| `error(...)` | the check failed, or the platform has no dialog (`NotSupportedException`) |

It does **not** wait for the user to answer the dialog. Use the [events](./events.md) to know what the
user did.

## Dialog or page

`displayType` in `PlayxUpdateUIOptions` chooses the presentation:

| `PlayxUpdateDisplayType` | Behavior |
| --- | --- |
| `pageOnForceUpdate` (default) | a dialog, or a full-screen page when the update is forced |
| `dialog` | always a dialog |
| `page` | always a full-screen page |

A page for a forced update replaces every route below it, so the user cannot navigate away.

## Build your own flow

Use `checkVersion` and the widgets directly:

```dart
final result = await PlayxVersionUpdate.checkVersion();

result.when(
  success: (info) {
    if (!info.canUpdate) return;

    if (info.forceUpdate) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PlayxUpdatePage(
            versionUpdateInfo: info,
            uiOptions: PlayxUpdateUIOptions(isDismissible: false),
          ),
        ),
        (route) => false,
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (_) => PlayxUpdateDialog(
          versionUpdateInfo: info,
          uiOptions: PlayxUpdateUIOptions(showReleaseNotes: true),
        ),
      );
    }
  },
  error: (error) => debugPrint(error.message),
);
```

`PlayxUpdatePage` works on every platform, which makes it the way to show an update on Windows and
Linux with a [custom version source](./version-sources.md). `PlayxUpdateDialog` renders on Android, iOS
and macOS only.

## Dismissing and the back button

| | Dismissible update | Forced update |
| --- | --- | --- |
| Dismiss button | closes the dialog or page, then runs `onCancel` | stays open; runs `onCancel`, or exits the app if there is none |
| Back button or tap outside | closes it | blocked |
| Default dismiss label | "Later" (dialog), "Not Now" (page) | "Close App" |

A forced update shows the dismiss button only while `showDismissButtonOnForceUpdate` is `true`
(the default).

## Android and in-app updates

`showInAppUpdateDialog` starts Google Play's in-app update on Android and shows this dialog on iOS and
macOS. See [Android in-app updates](./android-in-app-updates.md).

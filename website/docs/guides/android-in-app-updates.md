---
id: android-in-app-updates
title: Android in-app updates
sidebar_position: 11
---

# Android in-app updates

Google Play's [in-app updates](https://developer.android.com/guide/playcore/in-app-updates) let users
update without leaving your app. There are two kinds:

| | Immediate | Flexible |
| --- | --- | --- |
| Experience | full-screen, the user must update and restart | downloads in the background; you choose when to install |
| Use for | critical fixes and security patches | features and minor fixes |
| Method | `startImmediateUpdate()` | `startFlexibleUpdate()` |

:::warning Testing
In-app updates only work for apps **installed from Google Play**. See [Testing](./testing.md#android-in-app-updates).
:::

## One call

`showInAppUpdateDialog` starts the right flow on Android, and shows the update dialog on iOS and macOS:

```dart
await PlayxVersionUpdate.showInAppUpdateDialog(
  context: context,
  type: PlayxAppUpdateType.flexible, // or immediate
);
```

On Android, if a flexible update is already downloaded it completes that one first. `events:` reports when
the update starts and finishes.

## Check availability

```dart
final availability = await PlayxVersionUpdate.getUpdateAvailability();

availability.when(
  success: (value) async {
    if (value != PlayxAppUpdateAvailability.available) return;

    // How long the update has been available, and how important it is (0-5).
    final days = (await PlayxVersionUpdate.getUpdateStalenessDays()).updateData ?? -1;
    final priority = (await PlayxVersionUpdate.getUpdatePriority()).updateData ?? 0;

    final type = priority >= 4 || days >= 7
        ? PlayxAppUpdateType.immediate
        : PlayxAppUpdateType.flexible;

    final allowed = await PlayxVersionUpdate.isUpdateAllowed(type: type);
    if (allowed.updateData ?? false) {
      // start the update
    }
  },
  error: (error) => print(error.message),
);
```

`getUpdateStalenessDays` and `getUpdatePriority` return `-1` when no update is available.

## Immediate update

```dart
final result = await PlayxVersionUpdate.startImmediateUpdate();

result.when(
  success: (accepted) {}, // in practice the app has already restarted
  error: (error) {
    if (error is PlayxInAppUpdateCanceledError) {
      // The user said no. Decide: remind later, or block the app.
    } else if (error is PlayxUpdateNotAllowedError) {
      // Not allowed for this user or device right now.
    }
  },
);
```

If the user leaves the app during an immediate update, the package resumes the Google Play screen when
the app comes back.

## Flexible update

Check for a download that already finished first, then start, then follow the progress:

```dart
Future<void> startFlexible(BuildContext context) async {
  // 1. A finished download is waiting to be installed?
  final pending = await PlayxVersionUpdate.isFlexibleUpdateNeedToBeInstalled();
  if (pending.updateData ?? false) {
    promptToInstall(context);
    return;
  }

  // 2. Start the download.
  final result = await PlayxVersionUpdate.startFlexibleUpdate();
  result.when(
    success: (started) {
      if (started) listenToProgress(context);
    },
    error: (error) {
      if (error is PlayxInAppUpdateCanceledError) {
        // The user declined.
      }
    },
  );
}
```

### Follow the download

```dart
StreamSubscription<PlayxDownloadInfo?>? _subscription;

void listenToProgress(BuildContext context) {
  _subscription = PlayxVersionUpdate.listenToFlexibleDownloadUpdate().listen((info) {
    if (info == null) return;

    switch (info.status) {
      case PlayxDownloadStatus.downloading:
        final percent = info.bytesDownloaded / info.totalBytesToDownload * 100;
        print('Downloading: ${percent.toStringAsFixed(0)}%');
      case PlayxDownloadStatus.downloaded:
        promptToInstall(context);
        _subscription?.cancel();
      case PlayxDownloadStatus.failed || PlayxDownloadStatus.canceled:
        _subscription?.cancel();
      default:
        break;
    }
  });
}

// Cancel the subscription when it is no longer needed, for example in dispose().
```

### Install it

Google Play does not restart the app for a flexible update. Ask the user first:

```dart
void promptToInstall(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('An update has been downloaded.'),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: 'Restart',
        onPressed: () => PlayxVersionUpdate.completeFlexibleUpdate(),
      ),
    ),
  );
}
```

In the **foreground** `completeFlexibleUpdate()` shows a full-screen screen and restarts the app. In the
**background** the update installs silently.

### Check again when the app resumes

A finished download can sit unused if the user left the app. Check on every resume:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    PlayxVersionUpdate.isFlexibleUpdateNeedToBeInstalled().then((result) {
      if (result.updateData ?? false) promptToInstall(context);
    });
  }
}
```

## Errors {#errors}

Calls return a `PlayxVersionUpdateError`. The common ones:

| `errorCode` | Class | Meaning |
| --- | --- | --- |
| `PLAYX_UPDATE_CANCELLED` | `PlayxInAppUpdateCanceledError` | the user denied or cancelled the update |
| `PLAYX_IN_APP_UPDATE_FAILED` | `PlayxInAppUpdateFailedError` | the flow failed |
| `PLAYX_UPDATE_NOT_AVAILABLE` | `PlayxUpdateNotAvailableError` | there is no update |
| `PLAYX_UPDATE_NOT_ALLOWED` | `PlayxUpdateNotAllowedError` | this update type is not allowed right now |
| `PLAYX_UPDATE_IN_PROGRESS` | `PlayxUpdateInProgressError` | another update is in progress |
| `ACTIVITY_NOT_FOUND` | `ActivityNotFoundError` | the app is not in the foreground |
| `PLATFORM_NOT_SUPPORTED_ERROR` | `PlatformNotSupportedError` | not Android |
| `INSTALL_*` | `PlayxInstallError` subclasses | the download or install failed: `INSTALL_API_NOT_AVAILABLE`, `INSTALL_APP_NOT_OWNED`, `INSTALL_DOWNLOAD_NOT_PRESENT`, `INSTALL_IN_PROGRESS`, `INSTALL_NOT_ALLOWED`, `INSTALL_UNAVAILABLE`, `INSTALL_INTERNAL_ERROR`, `INSTALL_INVALID_REQUEST`, `INSTALL_PLAY_STORE_NOT_FOUND`, `INSTALL_UNKNOWN_ERROR` |

See the [API reference](https://playx-flutter.github.io/playx_version_update/api/playx_version_update/PlayxVersionUpdateError-class.html)
for the full list.



# Playx Version Update

[![pub package](https://img.shields.io/pub/v/playx_version_update.svg?color=1284C5)](https://pub.dev/packages/playx_version_update)

**Playx Version Update** empowers you to deliver a **flawless update experience** for your Flutter app users. Seamlessly integrate **native in-app updates for Android** (immediate or flexible), and present **beautifully customizable Flutter UI for iOS**. Detect new versions intelligently, enforce minimum app versions, and keep your users on the latest, greatest version of your app with minimal effort.


----------


-   **Intelligent Update Detection:** Automatically finds new versions on Google Play (Android) and Apple App Store (iOS).

-   **Native Android In-App Updates:**

    -   **Immediate:** Full-screen, mandatory updates for critical fixes.

    -   **Flexible:** Background downloads for non-critical updates, with user-controlled installation.

-   **Customizable Cross-Platform UI:** Display tailored Flutter dialogs or full-screen update pages for iOS or any custom needs.

-   **Comprehensive Configuration:** Control version comparisons, set minimum required versions, and override force update status. Specify store IDs, country, and language for precise lookups.

-   **Flexible UI Customization:** Personalize titles, descriptions, buttons, colors, text styles, and even add custom widgets. Choose between dialogs or full-screen pages, with control over display types and button actions.

-   **Detailed Version Info:** Access new version number, release notes, force update status, and direct store URL.

-   **Minimum Version Enforcement:** Trigger forced updates by adding a `[Minimum Version :X.Y.Z]` tag to your store description.

-   **Robust Error Handling:** Specific error types for network, installation, cancellation, and platform issues.

## 💻 Installation

Add `playx_version_update` to your `pubspec.yaml` dependencies:

YAML

```
dependencies:
  playx_version_update: ^1.0.1 # Use the latest stable version

```

Then, run `flutter pub get` to fetch the package.

----------

## 🛠️ Requirements

> **Note:** This package currently supports **Android** and **iOS** platforms only. Support for other platforms may be added in future updates.

-   **Flutter:** `>=3.27.0`

-   **Dart:** `>=3.6.0 <4.0.0`

-   **Android:**

    -   `compileSdkVersion`: `36`

    -   `minSdkVersion`: `23`

    -   Java `JVM target`: `17`


----------

## 🚀 Usage

`Playx Version Update` offers multiple ways to handle app updates, from simple dialogs to full custom UI experiences.

All update operations return a `PlayxVersionUpdateResult`, which allows you to easily handle both success data and specific error types.

----------

### 1. In-App Update Flow (`showInAppUpdateDialog`)

Initiate platform-native in-app updates for Android (Flexible or Immediate) or display a customizable Flutter UI for iOS. This provides a more integrated user experience.


  <p float="left" align="middle"> <img src="https://github.com/playx-flutter/playx_version_update/blob/main/screenshots/screenshot1.jpg?raw=true" width="30%" >      
  <img src="https://github.com/playx-flutter/playx_version_update/blob/main/screenshots/screenshot3.jpg?raw=true" width="43%" >     
 </p>

```Dart

Future<void> showInAppUpdateFlow(BuildContext context) async {
  final result = await PlayxVersionUpdate.showInAppUpdateDialog(
    context: context,
    // Specify the desired Android update flow type
    type: PlayxAppUpdateType.flexible, // Or PlayxAppUpdateType.immediate

    // PlayxUpdateOptions: Basic options for the version check for ios
    iosOptions: const PlayxUpdateOptions(
      iosBundleId: 'com.your_company.your_app_id',  // If not provided it will get it from app info
    ),
    // PlayxUpdateUIOptions: Customize iOS-specific Flutter UI (Android uses native UI)
    iosUiOptions: PlayxUpdateUIOptions(
      showReleaseNotes: true,
      releaseNotesTitle: (info) => 'What\'s New in ${info.newVersion}?',
      // Customize how the iOS update UI behaves
      displayType: PlayxUpdateDisplayType.pageOnForceUpdate, // Show full page for forced iOS updates
      isDismissible: false, // Make the iOS update UI non-dismissible if forced
      },
    ),
  );

  result.when(
    success: (isShown) {
      if (isShown) {
        print('In-app update dialog process initiated or no update needed.');
      }
    },
    error: (error) {
      print('Error during in-app update dialog: ${error.message}');
      // Handle specific errors from PlayxVersionUpdateError hierarchy like PlayxInstallError
    },
  );
}

```
**Important Note for Android In App Updates:** If you choose `PlayxAppUpdateType.flexible`, your app is responsible for monitoring the download status  and prompting the user to complete the installation once the update is downloaded.   Refer to the ["Monitoring Flexible Updates"](#monitoring-flexible-updates) and ["Installing a Flexible Update"]( #installing-a-flexible-update) sections for detailed instructions.

### 2.  Simple Update Dialog (`showUpdateDialog`)

Quickly inform users about new updates with a standard Material (Android) or Cupertino (iOS) dialog. This method uses Flutter-based UI and is cross-platform.


   <p float="left" align="middle">    
 <img src="https://github.com/playx-flutter/playx_version_update/blob/main/screenshots/screenshot3.jpg?raw=true" width="45%" >     
    <img src="https://github.com/playx-flutter/playx_version_update/blob/main/screenshots/screenshot6.jpg?raw=true" width="30%" > </p>

```Dart
Future<void> showSimpleUpdateDialog(BuildContext context) async {
  final result = await PlayxVersionUpdate.showUpdateDialog(
    context: context,
    // PlayxUpdateOptions: Configure the version check
    options: const PlayxUpdateOptions(
      androidPackageName: 'com.your_company.your_app_id', // Your Android package name
      iosBundleId: 'com.your_company.your_app_id',      // Your iOS bundle ID
      minVersion: '1.0.0', // Optional: Sets a minimum required version for a forced update
    ),
    // PlayxUpdateUIOptions: Customize the Flutter UI of the dialog
    uiOptions: PlayxUpdateUIOptions(
      title: (info) => 'A New Update is Available!', // Dynamic title
      description: (info) => 'Version ${info.newVersion} is now available. '
          'Please update to get the latest features and bug fixes.', // Dynamic description
      showReleaseNotes: false, // Don't show release notes in this dialog
      updateButtonText: 'Update Now!',
      dismissButtonText: 'Not Now',
      // You can also customize text styles, button styles, etc.
    ),
  );

  result.when(
    success: (isShowed) {
      if (isShowed) {
        print('Update dialog displayed successfully.');
      } else {
        print('Update dialog was not shown (e.g., no update available).');
      }
    },
    error: (error) {
      print('Failed to show update dialog: ${error.message}');
      // Handle specific errors like NoInternetConnectionError, PlatformNotSupportedError etc.
    },
  );
}

```



----------

### 3. Custom UI with `checkVersion` & `PlayxUpdatePage`

For complete control over the update presentation, use `checkVersion` to get detailed update information and then display your own custom Flutter UI, such as the provided `PlayxUpdatePage`.
<p float="left" align="middle">    
 <img src="https://github.com/playx-flutter/playx_version_update/blob/main/screenshots/screenshot5.jpg?raw=true" width="25%"  > </p>

```Dart
Future<void> checkForUpdateAndShowCustomUI(BuildContext context) async {
  final result = await PlayxVersionUpdate.checkVersion(
    // PlayxUpdateOptions: Full control over version comparison logic
    options: PlayxUpdateOptions(
      // Optional: Provide local app version (defaults to PackageInfo.fromPlatform())
      localVersion: '1.0.0',
      // Optional: Provide new app version (bypasses store lookup if provided)
      newVersion: '1.1.0',
      // Optional: Manually override force update status (e.g., forceUpdate: true)
      // If null, it's calculated based on localVersion vs. minVersion
      forceUpdate: true,
      // Your app's store identifiers (essential for store lookups)
      androidPackageName: 'com.your_company.your_app_id',
      iosBundleId: 'com.your_company.your_app_id',
      // Optional: Country and language for fetching store information
      country: 'us',
      language: 'en',
    ),
  );

  result.when(
    success: (info) {
      // Use PlayxVersionUpdateInfo to decide how to present the update
      if (info.canUpdate) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => PlayxUpdatePage(
              versionUpdateInfo: info, // Pass the update info to the page
              // PlayxUpdateUIOptions: Customize the PlayxUpdatePage's look and feel
              uiOptions: PlayxUpdateUIOptions(
                showReleaseNotes: true,
                showDismissButtonOnForceUpdate: false, // Don't show dismiss for forced updates
                leading: Image.network('https://via.placeholder.com/150'), // Custom image at the top
                title: (i) => "It's Time to Update!", // Dynamic title
                description: (i) =>
                    'A new version of the app (${i.newVersion}) is available. '
                    'Update now to enjoy the latest features and improvements.', // Dynamic description
                // Custom text styling for various elements
                titleTextStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                updateButtonTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                // Custom button styling
                updateButtonStyle: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                // Control dismiss behavior
                isDismissible: !info.forceUpdate, // Make dismissible if not a forced update
                // Callback when user dismisses the page (if dismissible)
                onCancel: (info) => print('Update page dismissed for version ${info.newVersion}'),
              ),
            ),
          ),
        );
      } else {
        print('App is already up to date.');
      }
    },
    error: (error) {
      print('Error checking for update: ${error.message}');
      // Handle various errors like NoInternetConnectionError, VersionFormatException, etc.
    },
  );
}

```

----------

### Minimum App Version

You can automatically determine if an update should be forced by embedding a minimum version string in your app's Google Play Store or Apple App Store description.

Simply add `[Minimum Version :X.Y.Z]` to the end of your app's store description (e.g., `[Minimum Version :1.5.0]`). The package will parse this information and automatically update the `forceUpdate` value of `PlayxVersionUpdateInfo` returned by `checkVersion` accordingly.


-----

## Google Play In-App Updates (Android Only)

The `playx_version_update` package makes it super easy to integrate **Google Play's In-App Update** feature into your Android app. This means you can prompt users to update without them ever leaving your app or opening the Play Store separately\! You get two main update options: **immediate** and **flexible**.

Want to dive deeper into the Android SDK behind this? Check out the official Google documentation:

* [In-App Updates Overview](https://developer.android.com/guide/playcore/in-app-updates)
* [Kotlin/Java Implementation Guide](https://developer.android.com/guide/playcore/in-app-updates/kotlin-java)


-----



### Immediate Updates

**Immediate updates** are full-screen experiences that **require** your user to update and restart the app to continue. Think of these as **mandatory updates** for critical fixes or security patches. Once the user agrees, Google Play handles the download and installation in the background, typically restarting your app when it's done.

<p float="left" align="middle">    
      <img src="https://developer.android.com/static/images/app-bundle/immediate_flow.png" width="70%" >     
     </p>

#### Initiating an Immediate Update

**Before starting an immediate update, it's a good practice to first check if a flexible update has already been downloaded and is waiting to be installed.** If so, prioritize installing that existing download to save user data and storage.

```dart
import 'package:playx_version_update/playx_version_update.dart';
import 'package:flutter/material.dart';

Future<void> _startImmediateUpdateFlow() async {
  print('Trying to start an immediate update...');

  // Important: Always check if a flexible update is already downloaded.
  final isUpdateNeedToBeInstalledResult = await PlayxVersionUpdate.isFlexibleUpdateNeedToBeInstalled();
  isUpdateNeedToBeInstalledResult.when(
    success: (isNeeded) {
      if (isNeeded) {
        print('A flexible update is already downloaded! Completing it now instead of starting immediate.');
        PlayxVersionUpdate.completeFlexibleUpdate(); // Directly complete
        return; 
      }
    },
    error: (error) => print('Error checking for pending flexible update before immediate: ${error.message}'),
  );

  final result = await PlayxVersionUpdate.startImmediateUpdate();

  result.when(
    success: (isSucceeded) {
      print('Immediate update flow initiated successfully (user likely accepted).');
    },
    error: (error) {
      print('An error happened during the immediate update: ${error.message}');
      if (error is PlayxInAppUpdateCanceledError) {
        print('The user said "no" or cancelled the update.');
        // Decide what to do: Maybe show a reminder later, or block app use.
      } else if (error is InstallNotAllowedError) {
        print('Update blocked, maybe due to low storage or no internet.');
      } else {
        print('Unknown immediate update error: ${error.runtimeType}');
      }
    },
  );
}
```

#### What Happens When an Immediate Update Starts?

When you kick off an immediate update and the user agrees, Google Play takes over, showing the download progress right over your app. If the user closes your app during this, the update usually keeps downloading and installing in the background.

If the user declines or cancels the update, Google Play's screen will close, and your app will be back in control. At this point, you'll need to decide your next move:

* **Prompt again later:** Remind them on their next app launch.
* **Show a message:** Explain why the update is important.
* **Force restart:** If it's absolutely critical, you might have to prevent further app use until they update.

-----

### Flexible Updates

**Flexible updates** download in the background, letting users continue to use your app without interruption. Once the download is done, you decide when to prompt the user to install it. This is perfect for **non-critical updates** like new features or minor bug fixes.

<p float="left" align="middle">    
 <img src="https://developer.android.com/static/images/app-bundle/flexible_flow.png" width="70%" >     
 </p>

#### Initiating a Flexible Update

**Before starting a new flexible update download, it's a good practice to first check if a flexible update has already been downloaded and is waiting to be installed.** If so, prioritize installing that existing download to save user data and storage.

```dart
import 'package:playx_version_update/playx_version_update.dart';
import 'package:flutter/material.dart';

Future<void> _startFlexibleUpdateFlow(BuildContext context) async {
  print('Trying to start a flexible update download...');

  // Important: Always check if a flexible update is already downloaded.
  final isUpdateNeedToBeInstalledResult = await PlayxVersionUpdate.isFlexibleUpdateNeedToBeInstalled();
  isUpdateNeedToBeInstalledResult.when(
    success: (isNeeded) {
      if (isNeeded) {
        print('A flexible update is already downloaded! Completing it now instead of starting a new download.');
        _promptToCompleteFlexibleUpdate(context); 
        return; 
      }
    },
    error: (error) => print('Error checking for pending flexible update before new download: ${error.message}'),
  );

  final result = await PlayxVersionUpdate.startFlexibleUpdate();

  result.when(
    success: (isStarted) {
      if (isStarted) {
        print('Flexible update download started! We\'ll monitor its progress.');
        // Start listening to the download progress right away.
        listenToFlexibleDownloadUpdates(context);
      } else {
        print('Flexible update didn\'t start (user likely declined).');
      }
    },
    error: (error) {
      print('An error happened trying to start the flexible update: ${error.message}');
      if (error is PlayxInAppUpdateCanceledError) {
        print('The user cancelled the flexible update download.');
      } else if (error is InstallNotAllowedError) {
        print('Flexible update download not allowed due to device issues.');
      }
      // Handle other errors as needed.
    },
  );
}
```

#### Monitoring Flexible Updates

Once a flexible update download begins, you'll want to show your user how it's going (maybe a progress bar\!). You also need to know when it's completely downloaded and ready to install.

Use the `listenToFlexibleDownloadUpdate` stream to keep an eye on things:

```dart
import 'dart:async'; // For StreamSubscription
import 'package:playx_version_update/playx_version_update.dart';
import 'package:flutter/material.dart'; // For UI elements like SnackBar

StreamSubscription? _downloadInfoStreamSubscription;

void listenToFlexibleDownloadUpdates(BuildContext context) {
  _downloadInfoStreamSubscription = PlayxVersionUpdate.listenToFlexibleDownloadUpdate().listen((info) {
    if (info == null) {
      print('No flexible update download active.');
      return;
    }

    switch (info.status) {
      case PlayxDownloadStatus.downloaded:
        print('Flexible update downloaded! Ready to install.');
        // The update is ready! Prompt the user to install it.
        _promptToCompleteFlexibleUpdate(context);
        _downloadInfoStreamSubscription?.cancel(); // Stop listening once it's downloaded.
        break;
      case PlayxDownloadStatus.downloading:
        final progress = (info.bytesDownloaded / info.totalBytesToDownload) * 100;
        print('Download progress: ${progress.toStringAsFixed(1)}%');
        // Update your UI (e.g., a progress bar) with `info.bytesDownloaded` and `info.totalBytesToDownload`.
        break;
      case PlayxDownloadStatus.pending:
        print('Flexible update download is waiting to start.');
        break;
      case PlayxDownloadStatus.failed:
        print('Flexible update download failed.');
        _downloadInfoStreamSubscription?.cancel();
        // Inform the user and maybe offer a retry.
        break;
      case PlayxDownloadStatus.canceled:
        print('Flexible update download cancelled.');
        _downloadInfoStreamSubscription?.cancel();
        break;
      case PlayxDownloadStatus.installing:
        print('Flexible update is installing...');
        break;
      case PlayxDownloadStatus.installed: // Added this case for completeness with new enum
        print('Flexible update installed successfully.');
        _downloadInfoStreamSubscription?.cancel();
        break;
      default: // Handles unknown or any new statuses
        print('Flexible update status: ${info.status}');
        break;
    }
  }, onError: (error) {
    print('Error while monitoring download updates: $error');
  });
}

// IMPORTANT: Always cancel your stream subscription when it's no longer needed
// (e.g., in your widget's dispose method) to prevent memory leaks.
void disposeDownloadSubscription() {
  _downloadInfoStreamSubscription?.cancel();
}
```

-----

### Installing a Flexible Update

Once the flexible update is `downloaded` (you'll know from the stream above\!), you need to tell the app to install it. Unlike immediate updates, Google Play won't automatically restart your app for flexible updates.

We strongly recommend you show a clear message or notification to your user, asking if they're ready to restart and install the update.

```dart
import 'package:playx_version_update/playx_version_update.dart';
import 'package:flutter/material.dart';

/// Call this function when a flexible update is downloaded and ready.
/// It shows a SnackBar prompting the user to install.
Future<void> _promptToCompleteFlexibleUpdate(BuildContext context) async {
  final snackBar = SnackBar(
    content: const Text('A new update has finished downloading!'),
    action: SnackBarAction(
      label: 'Restart App',
      onPressed: () async {
        print('User tapped "Restart App" for flexible update.');
        final result = await PlayxVersionUpdate.completeFlexibleUpdate();
        result.when(
          success: (isCompleted) {
            print('Flexible update completion initiated: $isCompleted');
            // If successful, your app will restart automatically.
          },
          error: (error) {
            print('Failed to install flexible update: ${error.message}');
            if (error is InstallApiNotAvailableError) {
              print('In-app updates API not available on this device for installation.');
            } else if (error is InstallNotAllowedError) {
              print('Installation not allowed (e.g., low battery, no internet).');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: ${error.message}')),
            );
          },
        );
      }),
    duration: const Duration(seconds: 10), // Give user some time to see it
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
```

#### How Installation Works

* If you call `PlayxVersionUpdate.completeFlexibleUpdate()` while your app is in the **foreground**, Google Play will show a full-screen screen that restarts your app to complete the installation. Your app will then restart normally.
* If your app is in the **background** when you call it, the update will install silently without bothering the user.

-----

### Don't Forget Pending Updates on App Resume\!

It's really important to check for any flexible updates that were downloaded but not yet installed every time your app comes back to the foreground. This makes sure users get the latest version and downloaded updates don't just sit there wasting space.

```dart
import 'package:flutter/widgets.dart'; // For WidgetsBindingObserver
import 'package:playx_version_update/playx_version_update.dart';
import 'dart:io'; // For Platform.isAndroid

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Start listening to app lifecycle changes
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Stop listening when widget is removed
    disposeDownloadSubscription(); // Make sure to clean up any download listeners!
    super.dispose();
  }

  /// This gets called whenever the app changes its lifecycle state (e.g., goes to background, comes to foreground).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the app is resuming (coming back to foreground)
    if (state == AppLifecycleState.resumed) {
      _checkIfPendingFlexibleUpdate();
    }
  }

  /// Checks if a flexible update has been downloaded and is waiting to be installed.
  Future<void> _checkIfPendingFlexibleUpdate() async {
    if (Platform.isAndroid) {
      final result = await PlayxVersionUpdate.isFlexibleUpdateNeedToBeInstalled();
      result.when(
        success: (isNeeded) {
          if (isNeeded) {
            print('A flexible update is ready to install on app resume!');
            // You should prompt the user to install it here.
            // For example, by showing a SnackBar or a persistent notification/banner.
            if (mounted) { // Make sure the widget is still active before showing UI
               // You'd need a way to get a valid BuildContext here, or use a GlobalKey for ScaffoldMessenger.
               // For example: _promptToCompleteFlexibleUpdate(context);
               print('Consider prompting the user to install the downloaded update.');
            }
          } else {
            print('No pending flexible update to install.');
          }
        },
        error: (error) => print('Error checking for pending flexible update: ${error.message}'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is just a basic example for demonstration.
    // Your actual app UI would go here.
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Playx Version Update')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _checkForAppUpdate(context),
                child: const Text('Check for App Update'),
              ),
              const SizedBox(height: 20),
              const Text('This area will show update status in the console.'),
            ],
          ),
        ),
      ),
    );
  }
}
```

-----
### How to Check for Updates

Before you can offer an update, you need to know if one's even available\! Here's how you check and gather useful details like how old the update is and its priority.

```dart
import 'package:playx_version_update/playx_version_update.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // Needed for Platform.isAndroid

Future<void> _checkForAppUpdate(BuildContext context) async {
  // In-app updates are only for Android devices.
  if (!Platform.isAndroid) {
    print('In-app updates are only supported on Android.');
    return;
  }

  // Check if an update is available at all.
  final availabilityResult = await PlayxVersionUpdate.getUpdateAvailability();

  availabilityResult.when(
    success: (availability) async {
      // Using the provided enum for clarity
      if (availability == PlayxAppUpdateAvailability.available) {
        print('Good news! An update is available.');

        // Get how long the update has been available (staleness)
        final stalenessResult = await PlayxVersionUpdate.getUpdateStalenessDays();
        int stalenessDays = stalenessResult.when(
          success: (days) => days,
          error: (error) => -1, // Default if error
        );
        print('This update has been available for $stalenessDays days.');

        // Get the priority of the update (0-5, 5 is highest)
        final priorityResult = await PlayxVersionUpdate.getUpdatePriority();
        int priority = priorityResult.when(
          success: (p) => p,
          error: (error) => 0, // Default if error
        );
        print('The update priority is: $priority.');

        // Now, decide if you want an Immediate or Flexible update
        // based on staleness, priority, or your app's specific rules.
        if (priority >= 4 || stalenessDays >= 7) {
          // This update is pretty important or old, let's go with immediate.
          await _checkAndStartUpdate(PlayxAppUpdateType.immediate, context); // Pass context
        } else {
          // It's not super critical, a flexible update will do.
          await _checkAndStartUpdate(PlayxAppUpdateType.flexible, context); // Pass context
        }
      } else if (availability == PlayxAppUpdateAvailability.notAvailable) {
        print('No updates found. Your app is up to date!');
      } else if (availability == PlayxAppUpdateAvailability.inProgress) {
        print('An update is already in progress.');
      } else { // PlayxAppUpdateAvailability.unknown
        print('Could not determine update availability.');
      }
    },
    error: (error) {
      print('Failed to check for updates: ${error.message}');
      // Handle network errors, Play Store not available, etc.
    },
  );
}

// Helper to check if update type is allowed and then start it
Future<void> _checkAndStartUpdate(PlayxAppUpdateType type, BuildContext context) async {
  // Always check for already downloaded flexible updates first!
  final isUpdateNeedToBeInstalledResult = await PlayxVersionUpdate.isFlexibleUpdateNeedToBeInstalled();
  isUpdateNeedToBeInstalledResult.when(
    success: (isNeeded) {
      if (isNeeded) {
        print('A flexible update is already downloaded! Prioritizing installation...');
        _promptToCompleteFlexibleUpdate(context); // Use your existing prompt function
        return; // Stop here, we're handling the existing download
      }
    },
    error: (error) => print('Error checking for pending flexible update: ${error.message}'),
  );

  final isAllowed = await PlayxVersionUpdate.isUpdateAllowed(type: type);
  isAllowed.when(
    success: (allowed) {
      if (allowed) {
        if (type == PlayxAppUpdateType.immediate) {
          print('Immediate update is allowed. Starting now...');
          _startImmediateUpdateFlow();
        } else {
          print('Flexible update is allowed. Starting download...');
          _startFlexibleUpdateFlow(context); // Pass context
        }
      } else {
        print('${type == PlayxAppUpdateType.immediate ? "Immediate" : "Flexible"} update not allowed right now.');
      }
    },
    error: (error) => print('Error checking update allowance: ${error.message}'),
  );
}
```



## ⚠️ Important Notice for Testing In-App Updates (Android)

Android in-app updates **will only work if your app is installed directly from Google Play**. This means testing builds installed via Android Studio or other side-loading methods will **not** trigger in-app updates.

To successfully test in-app updates on Android, please ensure you follow these steps precisely:

1.  **Publish to a Test Track:** Your app (an **older version**) must be published to at least an **Internal test track** in your Google Play Console.

    -   **Internal App Sharing** is often a quicker alternative for rapid iteration testing, allowing you to share APKs/App Bundles directly without full track review cycles.

2.  **Install via Play Store:** On your emulator or physical device, install this **older version** of your app _directly_ from the Google Play Store link generated by your chosen test track (or internal app sharing link). Ensure the Google account on the device is a **tester** for that track and has downloaded the app at least once from the Play Store.

3.  **Upload a Newer Version:** Upload a **newer version** of your app (with an **incremented `versionCode` and `versionName`**) to the _same test track_ in the Google Play Console. This new version should contain your `playx_version_update` implementation.

4.  **Wait for Processing:** Allow some time (it can vary from minutes to several hours) for Google Play to process and make the new version available to your test track. Google Play Services and Play Store caches can sometimes cause delays; clearing the Play Store cache or restarting the device might help.

5.  **Test Update:** Now, when you open the **older version** of your app (the one you installed from the Play Store) on your emulator/device, it should detect the available update via the in-app update API.

    -   For **Flexible Updates**, remember that your app needs to explicitly monitor the download status and then prompt the user to complete the installation once the update is downloaded. Refer to the ["Monitoring Flexible Updates"](#monitoring-flexible-updates) and ["Installing a Flexible Update"]( #installing-a-flexible-update) sections for detailed instructions. It's also crucial to check for **already downloaded flexible updates** that might be pending installation before initiating a new update flow.

    -   For **Immediate Updates**, the full-screen UI should appear, requiring the user to update.


For detailed, official guidance on setting up your Android in-app update testing environment, please refer to the Android Developers documentation:

https://developer.android.com/guide/playcore/in-app-updates/test

For a complete list of all possible errors, refer to the [PlayxVersionUpdateError API Reference](https://pub.dev/documentation/playx_version_update/latest/playx_version_update/PlayxVersionUpdateError-class.html).


## 📄 Documentation & References

-   [In-app updates](https://developer.android.com/guide/playcore/in-app-updates) - Official Google Play documentation on in-app updates.

-   [playx_network](https://pub.dev/packages/playx_network) - The network package used internally for version checks.
    


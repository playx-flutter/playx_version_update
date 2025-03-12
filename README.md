


# Playx  Version Update
Effortlessly manage app updates and provide a seamless user experience with Playx Version Update. Easily notify users about new updates, offer flexible or immediate update options, and customize the update process in your Flutter projects.

Features  
Update Dialog: Inform users about new app updates with material design dialog on Android and Cupertino dialog on iOS.  
Google Play Integration: Initiate flexible or immediate updates directly from your app.  
Customizable UI: Display custom update UI including release notes and minimum version requirements.  
In-app Update Page: Show update information and options within your app for a seamless user experience.

## Installation

In `pubspec.yaml` add these lines to `dependencies`

```yaml  
 playx_version_update: ^0.1.1     
```   
## Requirements
> Note: The package currently supports Android and IOS platforms only. We will add support for other platforms in the future in the future.
- Flutter >=3.19.0
- Dart >=3.3.0 <4.0.0
- Android  `compileSDK` 34
- Minimum Android sdk is 23
- Java 17
- Android Gradle Plugin >=8.3.0
- Gradle wrapper >=8.4



## Usage

1. To show material update dialog in Android or Cupertino dialog in IOS that shows that the app needs to update.

    <p float="left" align="middle">  
  <img src="https://github.com/playx-flutter/playx_version_update/blob/main/screenshots/screenshot3.jpg?raw=true" width="45%" >   
     <img src="https://github.com/playx-flutter/playx_version_update/blob/main/screenshots/screenshot6.jpg?raw=true" width="30%" >    
 </p>  

  ```dart  
  PlayxVersionUpdate.showUpdateDialog(  
        context: context,  
        //show release notes or not  
        showReleaseNotes: false,  
        //customize store app id  
        googlePlayId: 'android package name',  
        appStoreId: 'ios bundle id',  
        //sets min version that force app to update if below this version  
        minVersion: '1.0.0',  
        //customize dialog layout like title.  
        title:(info)=> 'A new update is available',  
    );  
   ```  


Just like that you are able show an update  dialog for android and IOS.

2.  To show in app update for Android and Cupertino dialog in IOS, You can use this:
    <p float="left" align="middle">  
  <img src="https://github.com/playx-flutter/playx_version_update/blob/main/screenshots/screenshot1.jpg?raw=true" width="30%" >    
    <img src="https://github.com/playx-flutter/playx_version_update/blob/main/screenshots/screenshot3.jpg?raw=true" width="43%" >   
    </p>  


     ```dart  
       final result = await PlayxVersionUpdate.showInAppUpdateDialog(  
           context: context,  
           //Type for google play in app update either flexible or immediate update.  
           type: PlayxAppUpdateType.flexible,  
           //customize app store id in ios  
           appStoreId: 'app bundle id',  
           //show release notes or not in ios  
           showReleaseNotes: true,  
           //customize dialog layout like release notes title  in ios.  
           releaseNotesTitle: (info) => 'Recent Updates of ${info.newVersion}',  
           // When the user clicks on update action the app open the app store,  
           // If you want to override this behavior you can call [onIosUpdate].  
           onIosUpdate: (info, launchMode) async {  
             final storeUrl = info.storeUrl;  
             final res = await PlayxVersionUpdate.openStore(storeUrl: storeUrl);  
             res.when(success: (success) {  
                print('playx_open_store: success :$success');  
              }, error: (error) {  
               print('playx_open_store: error :$error');  
             });  
           },  
        
         );  
         result.when(success: (isShowed) {  
             print( ' showInAppUpdateDialog success : $isShowed');  
         }, error: (error) {  
             print(' showInAppUpdateDialog error : $error ${error.message}');  
         });  
      ```  
       Now we can show in app update either flexible or immediate update in android or dialog in IOS.  
       We will go in details about in app updates below.  

3. You can easily check Google play and App store version and create your own custom UI with :  
   For example we can show `PlayxUpdatePage` which displays information about app update.
    <p float="left" align="middle">  
     <img src="https://github.com/playx-flutter/playx_version_update/blob/main/screenshots/screenshot5.jpg?raw=true" height=500 >   
    </p>  

   ```dart  
     final result = await PlayxVersionUpdate.checkVersion(  
          //local app version if not provided It will get it from app version  
          localVersion: '1.0.0',  
          //new app version if not provided It will get it from store information.  
          newVersion: '1.1.0',  
          //If should force the update or not.  
          forceUpdate: true,  
          //googlePlayId and appStoreId if not provided It will get it from app version   
          googlePlayId: 'your app package name',  
          appStoreId: 'your app bundle id',  
          // country to fetch store information from.  
          country: 'us',  
          // language to fetch store information from. release notes will be in this language.  
          language: 'en',  
        );  
      
        result.when(success: (info) {  
        //When result is successful it returns instance of [PlayxVersionUpdateInfo]   
        //Which contains information about app whether it should update or not , force update,  
        //App version and store URL and more.  
        // You can use these info to show your custom ui.  
          Navigator.push(  
          context,  
          MaterialPageRoute<void>(  
            builder: (BuildContext context) => PlayxUpdatePage(  
              versionUpdateInfo: info,  
              showReleaseNotes: false,  
              showDismissButtonOnForceUpdate: false,  
              //show image or lottie animation on top of the page.  
              leading: Image.network('image url'),  
              title:(info)=> "It's time to update",  
              description:(info)=>  
                 'A new version of the app is now available.\nThe app needs to be updated to the latest version in order to work properly.\nEnjoy the latest version features now.',  
            ),  
          ),  
        );  
      
        }, error: (error) {  
          //handle the error that happened here.  
        });  
 ```  
### Minimum App Version  
You can set minimum version for the app that will force the app to update if the current version is below the minimum version.  
  
Simply add `[Minimum Version :1.0.0]` to the end of Google play or app store description.  
The package will parse this information and update `forceUpdate` value of of `PlayxVersionUpdateInfo`  
  
  
## Google Play In App updates  
The package uses Google play in app updates SDK to show either flexible or immediate updates.  
  
## Immediate updates  
  
Immediate updates are full screen UX flows that require the user to update and restart the app in order to continue using it. This UX flow is best for cases where an update is critical to the core functionality of your app. After a user accepts an immediate update, Google Play handles the update installation and app restart.  
<p float="left" align="middle">  
      <img src="https://developer.android.com/static/images/app-bundle/immediate_flow.png" width="80%" >   
     </p>  
  
#### To start a flexible update, You can use :  
```dart  
final result = await PlayxVersionUpdate.startImmediateUpdate();    
      result.when(success: (isSucceeded ) {    
       //The user accepted and the update succeeded   
       //(which, in practice, your app never should never receive because it already updated).  
      }, error: (error) {    
        //It can return one of these errors:  
      //[ActivityNotFoundError] : When the user started the update flow from background.    
      //[PlayxRequestCanceledError] : The user denied or canceled the update.    
      // [PlayxInAppUpdateFailedError] : The flow failed either during the user confirmation, the download, or the installation.  
       print('an error occurred :${error.message}');   
   });  
```  

## Handle an immediate update
When you start an immediate update and the user consents to begin the update, Google Play displays the update progress on top of your app's UI throughout the entire duration of the update. If the user closes or terminates your app during the update, the update should continue to download and install in the background without additional user confirmation.

In particular, your app should be able to handle cases where a user declines the update or cancels the download. When the user performs either of these actions, the Google Play UI closes. Your app should determine the best way to proceed.

If possible, let the user continue without the update and prompt them again later. If your app can't function without the update, consider displaying an informative message before restarting the update flow or prompting the user to close the app. That way, the user understands that they can relaunch your app when they're ready to install the required update.



## Flexible updates


<p float="left" align="middle">  
  <img src="https://developer.android.com/static/images/app-bundle/flexible_flow.png" width="90%" >   
 </p>  


To start a flexible update, You can use :
```dart  
final result = await PlayxVersionUpdate.startFlexibleUpdate();    
      result.when(success: (isStarted) {    
            //The user has accepted the update.  
      }, error: (error) {    
        //It can return one of these errors:  
        //[ActivityNotFoundError] : : When the user started the update flow from background.    
        //[PlayxRequestCanceledError] : The user denied the request to update.    
        //[PlayxInAppUpdateFailedError] :: Something failed during the request for user confirmation. For example, the user terminates the app before responding to the request.  
       print('an error occurred :${error.message}');   
   });  
```  
### Handle a flexible update

When you start a flexible update, a dialog first appears to the user to request consent. If the user consents, then the download starts in the background, and the user can continue to interact with your app. This section describes how to monitor and complete a flexible in-app update.

This necessary even if you used `PlayxVersionUpdate.showInAppUpdateDialog` in order to complete the flexible update.

#### Monitor the flexible update state

After the download begins for a flexible update, your app needs to monitor the update state to know when the update can be installed and to display the progress in your app's UI.

You can monitor the state of an update in progress by using `listenToFlexibleDownloadUpdate` stream. You can also provide a progress bar in the app's UI to inform users of the download's progress.

```dart  
  void listenToFlexibleDownloadUpdates() {  
    downloadInfoStreamSubscription =  
        PlayxVersionUpdate.listenToFlexibleDownloadUpdate().listen((info) {  
      if (info == null) return;  
      if (info.status == PlayxDownloadStatus.downloaded) {  
      //app is downloaded, complete the update  
        completeFlexibleUpdate();  
      } else if (info.status == PlayxDownloadStatus.downloading) {  
      print( 'current download in progress : bytes downloaded:${info.bytesDownloaded} total bytes to download : ${info.totalBytesToDownload}');  
      }  
  });  
  }  
```  
### Install a flexible update

When you detect the  `PlayxDownloadStatus.downloaded` state, you need to restart the app to install the update.

Unlike with immediate updates, Google Play does not automatically trigger an app restart for a flexible update. This is because during a flexible update, the user has an expectation to continue interacting with the app until they decide that they want to install the update.

It is recommended that you provide a notification (or some other UI indication) to inform the user that the update is ready to install and request confirmation before restarting the app.

Here's an example that shows `SnackBar` that asks user to restart the app to install the download.
```dart   
  ///Completes an update that is downloaded and needs to be installed as it shows snack bar to ask the user to install the update.  
  Future<void> completeFlexibleUpdate() async {  
      final snackBar = SnackBar(  
        content: const Text('An update has just been downloaded.'),  
        action: SnackBarAction(  
            label: 'Restart',  
            onPressed: () async {  
              final result = await PlayxVersionUpdate.completeFlexibleUpdate();  
              result.when(success: (isCompleted) {  
                print('completeFlexibleUpdate isCompleted : $isCompleted');  
              }, error: (error) {  
                print('completeFlexibleUpdate error has happened: ${error.message');  
              });  
            }),  
        duration: const Duration(seconds: 10),  
      );  
      globalKey.currentState?.showSnackBar(snackBar);  
  }  
```  



When you call `PlayxVersionUpdate.completeFlexibleUpdate()` in the foreground, the platform displays a full-screen UI that restarts the app in the background. After the platform installs the update, your app restarts into its main.

If you instead call  `PlayxVersionUpdate.completeFlexibleUpdate()` when your app is  in the background, the update is installed silently without obscuring the device UI.

Whenever the user brings your app to the foreground, check whether your app has an update waiting to be installed. If your app has an update in the  `DOWNLOADED` state, prompt the user to install the update. Otherwise, the update data continues to occupy the user's device storage.

For example listen to on app resume lifecycle using [`WidgetsBindingObserver`](https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html) and use :
```dart  
  ///check if flexible update needs to be installed on app resume.  
  @override  
  void didChangeAppLifecycleState(AppLifecycleState state) {  
    if (state == AppLifecycleState.resumed) {  
      checkIfFlexibleUpdateNeedToBeInstalled();  
    }  
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
     print('checkIfFlexibleUpdateNeedToBeInstalled error :$error :${error.message}');  
  }  
```  


## Important Notice
The in app updates will not work unless the app is downloaded From Google Play.  
To test in app updates you can use Google play [`Internal app sharing`](https://play.google.com/console/about/internalappsharing/) or [`Internal testing`](https://play.google.com/console/about/internal-testing/) .

Check out all possible errors from the [Api Reference](https://pub.dev/documentation/playx_version_update/latest/playx_version_update/PlayxVersionUpdateError-class.html).

## Documentation && References

- [In-app updates](https://developer.android.com/guide/playcore/in-app-updates), Google play in app updates sdk.
- [new_version_plus](https://pub.dev/packages/new_version_plus) package.
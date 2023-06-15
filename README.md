
# Playx  Version Update
Easily show material update dialog in Android or Cupertino dialog in IOS with support for Google play in app updates.

## Features
- Show material update dialog in Android or Cupertino dialog in IOS to inform user about new app updates.
- Easily start Google play flexible or immediate updates.
- Ability to show Google play in app updates in Android or Cupertino dialog in IOS.
- Ability to check store version and display custom UI.
- Ability to show release notes from the store.
- Ability to set minimum version for app update to force updates.
- Ability to show an update page, useful for in app updates.



## Installation

In `pubspec.yaml` add these lines to `dependencies`

```yaml  
playx_version_update: ^0.0.1 
```  
## Usage

1.  To show material update dialog in Android or Cupertino dialog in IOS that shows that the app needs to update.
    ```dart
      final result = await PlayxVersionUpdate.showUpdateDialog(
            context: context,
           //show release notes or not
           showReleaseNotes: false,
           //customize store app id
           googlePlayId: 'other app id',
           //sets min version that force app to update if below this version
           minVersion: '1.0.0',
          //customize dialog layout like title.
          title: 'A new update is available'
          //forces app update.
          forceUpdate: true,  
          //shows update page instead of dialog on force update
          showPageOnForceUpdate: true,
          //handle what the app should do after canceling the dialog.
          onCancel: (forceUpdate){
                   if(forceUpdate){
                   //exit the app on force update.
                        exit(0);
                    }else{
                       //Do nothing
                   }
       );
      result.when(success: (isShowed) {
             print(' showUpdateDialog success :');
       }, error: (error) {
            print( ' showUpdateDialog error : ${error.message}');
       });
       ```


      Just like that you are able show an update  dialog for android and IOS.

2.  To show in app update for Android and Cupertino dialog in IOS, You can use this:
     ```dart
       final result = await PlayxVersionUpdate.showInAppUpdateDialog(
           context: context,
           //Type for google play in app update either flexible or immediate update.
           type: PlayxAppUpdateType.flexible,
           //customize app store id in ios
           appStoreId: 'com.apple.tv',
           //show release notes or not in ios
           showReleaseNotes: true,
           //customize dialog layout like release notes title  in ios.
           releaseNotesTitle: 'Recent Updates',           
         );
         result.when(success: (isShowed) {
           setState(() {
             message = ' showInAppUpdateDialog success : $isShowed';
           });
         }, error: (error) {
           setState(() {
             message = ' showInAppUpdateDialog error : $error ${error.message}';
           });
         });
      ```
    Now we can show in app update either flexible or immediate update in android or dialog in ios.
    We will go in details about in app updates below.
 
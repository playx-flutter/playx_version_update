# Changelog

## 0.1.1
> Note : This release is a major release and may break some of the existing implementations. Please read the documentation carefully.
const factory PlayxVersionUpdateResult.success(T data) = PlayxVersionUpdateSuccessResult;
const factory PlayxVersionUpdateResult.error(PlayxVersionUpdateError error) = PlayxVersionUpdateErrorResult;

#### PlayxVersionUpdateResult
#### **Breaking Changes**
- `PlayxVersionUpdateResult.when` now returns a value instead of requiring callbacks to handle data.
- `map` and `mapAsync` now directly return transformed results instead of requiring wrapped factory calls.
- Renamed `Success` and `ERROR` classes to `PlayxVersionUpdateSuccessResult` and  `PlayxVersionUpdateErrorResult`.

#### **Updates**
✅ **New `isSuccess` and `isError` Getters** – Easily check the result type.  
✅ **More Flexible `when`, `map`, and `mapAsync` Methods** – Now return transformed values instead of requiring extra wrapping.  

### Enhancements
- Update packages.
- Use `playx_network` for network requests for better error handling.
- Dialog with `forceUpdate` can close the app using `SystemNavigator.pop()` if no `onCancel` callback is provided.



## 0.1.0
> Note : This release is a major release and may break some of the existing implementations. Please read the documentation carefully.

- Plugin now requires the following:
    * Flutter >=3.19.0
    * Dart >=3.3.0
    * compileSDK 34 for Android part
    * Java 17 for Android part
    * Gradle 8.4 for Android part
    * minimum Android sdk is 23

- Update packages.
- The plugin now supports wasm for web.
- Add new methods `getAppVersion` and `getAppBuildNumber` in `PlayxVersionUpdate` to get the app version and build number.
- Enhance compatibility with web.
- Update example app to latest android version and added other platforms.

## 0.0.6 - 0.0.7
- Update packages.
- Add `namespace` to build.gradle for the plugin.
- Remove package name for manifest.

## 0.0.5
- Update packages.
- Enhance network requests logging in debug.

## 0.0.4
- Update packages.
- Bump Dart version to 3.2.0 and flutter to 13.16.0
- Add topics

## 0.0.3
- Better support for IOS.
- Add `PlatformNotSupportedError` error when the platform is not supported, for example trying to use Google play in app update on IOS.

## 0.0.2
- Enhancements for force update.

## 0.0.1
- Initial release.

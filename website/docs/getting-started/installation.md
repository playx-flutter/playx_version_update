---
id: installation
title: Installation
sidebar_position: 1
---

# Installation

Add the package to your app:

```bash
flutter pub add playx_version_update
```

or in `pubspec.yaml`:

```yaml
dependencies:
  playx_version_update: ^2.0.0-beta.1
```

:::caution 2.0 is in beta
A normal `^1.3.0` constraint keeps resolving to 1.3.0 until 2.0.0 is released: a pre-release is only used
when you ask for it, as above. Please try it and [report problems](https://github.com/playx-flutter/playx_version_update/issues).
To test unreleased changes before a beta, depend on the repository:

```yaml
dependencies:
  playx_version_update:
    git:
      url: https://github.com/playx-flutter/playx_version_update.git
      ref: qa
```
:::

Then import it:

```dart
import 'package:playx_version_update/playx_version_update.dart';
```

## Requirements

| | Minimum |
| --- | --- |
| Dart | 3.10 |
| Flutter | 3.38.1 |
| Android | `minSdk` 23 |

The package depends on `dio`, `package_info_plus` and `url_launcher`.

## Platform setup

### Android

Nothing to add. The native in-app update code is part of the plugin, and it supports Android Gradle
Plugin 8 and 9.

:::note
Google Play in-app updates only work for apps **installed from Google Play**. See
[Testing](./../guides/testing.md#android-in-app-updates).
:::

### iOS

Nothing to add.

### macOS

Sandboxed macOS apps need the network entitlement to reach the store lookup. Add this to both
`macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

See [iOS and macOS](./../guides/ios-and-macos.md) for details.

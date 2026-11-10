---
id: intro
title: Introduction
slug: /intro
sidebar_position: 1
---

# Playx Version Update

**Playx Version Update** helps you keep your Flutter users on the latest version of your app. It finds
new versions, compares them with the installed one, shows an update dialog or page you can style,
and runs **native in-app updates on Android**.

## What it does

- **Finds new versions** on Google Play (Android), the App Store (iOS) and the Mac App Store
  (macOS), or from your own backend or Firebase Remote Config through
  [version sources](./guides/version-sources.md).
- **Native Android in-app updates**: immediate (full screen, mandatory) and flexible (background
  download, user chooses when to install). See [Android in-app updates](./guides/android-in-app-updates.md).
- **A customizable update UI**: a platform-adaptive dialog (Material on Android, Cupertino on iOS
  and macOS) and a full-screen page. See [Update dialog and page](./guides/update-dialog-and-page.md) and
  [Customizing the UI](./guides/customizing-the-ui.md).
- **Minimum versions**: force an update below a version, per platform. See
  [Minimum version](./guides/minimum-version.md).
- **"Later" and "Skip this version"** with pluggable storage. See [Later and Skip](./guides/later-and-skip.md).
- **Events** for analytics and **stable error codes**. See [Events](./guides/events.md) and
  [Network and errors](./guides/network-and-errors.md).
- **Opening the store** with deep links (`market://`, `itms-apps://`, `macappstores://`) and a hook for
  your own launcher. See [Opening the store](./guides/opening-the-store.md).

## Platform support

| Platform | Version lookup | Update dialog | In-app update |
| --- | --- | --- | --- |
| Android | Google Play | Material dialog | Google Play immediate / flexible |
| iOS | App Store | Cupertino dialog | opens the App Store |
| macOS | Mac App Store | Cupertino dialog | opens the Mac App Store |
| Windows, Linux | [custom version source](./guides/version-sources.md) | build your own with `PlayxUpdatePage` | not available |
| Web | not supported | not supported | not supported |

## Where to go next

- New here? Start with [Installation](./getting-started/installation.md) and the
  [Quick start](./getting-started/quick-start.md).
- Upgrading from 1.x? Read [Migrating to 2.0](./migration/migrating-to-2.md).
- Looking for a class or method? See the [API reference](https://playx-flutter.github.io/playx_version_update/api/).

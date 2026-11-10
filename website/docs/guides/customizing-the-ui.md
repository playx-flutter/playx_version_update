---
id: customizing-the-ui
title: Customizing the UI
sidebar_position: 3
---

# Customizing the UI

`PlayxUpdateUIOptions` controls the dialog and the page. Every field is optional.

```dart
PlayxUpdateUIOptions(
  title: (info) => 'Version ${info.newVersion} is here',
  description: (info) => 'Update to get the latest features and fixes.',
  showReleaseNotes: true,
  releaseNotesTitle: (info) => "What's new",
  updateButtonText: 'Update now',
  dismissButtonText: 'Maybe later',
  titleTextStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  updateButtonStyle: ElevatedButton.styleFrom(backgroundColor: Colors.green),
  leading: Image.asset('assets/update.png', height: 120),
)
```

## Texts

| Option | Default |
| --- | --- |
| `title` | "New version available." |
| `description` | a message with the new version |
| `showReleaseNotes` | `false` |
| `releaseNotesTitle` | "Release Notes:" |
| `updateButtonText` | "Update" |
| `dismissButtonText` | "Later" (dialog), "Not Now" (page), "Close App" (forced) |

`title`, `description` and `releaseNotesTitle` receive the `PlayxVersionUpdateInfo`, so you can
include versions in them.

## Styles

`titleTextStyle`, `descriptionTextStyle`, `releaseNotesTitleTextStyle`, `releaseNotesTextStyle`,
`updateButtonTextStyle`, `dismissButtonTextStyle`, `updateButtonStyle` and `dismissButtonStyle`.

`leading` is a widget shown above the content, for an image or illustration.

## Dismissal

| Option | Meaning |
| --- | --- |
| `isDismissible` | whether the user can dismiss it. Defaults to `true`, except for a forced update |
| `showDismissButtonOnForceUpdate` | show the dismiss button on a forced update (default `true`) |
| `displayType` | dialog, page, or page on force update, see [Update dialog and page](./update-dialog-and-page.md) |

## Actions

| Option | Meaning |
| --- | --- |
| `onUpdate` | replaces what the update button does. Receives the info and the `LaunchMode` |
| `storeLauncher` | opens the store yourself and returns whether it opened, see [Opening the store](./opening-the-store.md) |
| `onCancel` | runs when the dismiss button is tapped |
| `launchMode` | how the store URL is launched (default `LaunchMode.externalApplication`) |
| `preferStoreApp` | try the store app's deep link before the web URL (default `true`) |
| `events` | callbacks for analytics, see [Events](./events.md) |

:::info
These options apply to the Flutter UI: the dialog and page. Android's native in-app update screens
are controlled by Google Play.
:::

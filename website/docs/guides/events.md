---
id: events
title: Events
sidebar_position: 9
---

# Events

`PlayxUpdateEvents` reports what happens to the update flow, mainly for analytics. Pass it in
`PlayxUpdateUIOptions`:

```dart
PlayxUpdateUIOptions(
  events: PlayxUpdateEvents(
    onShown: (info) => analytics.log('update_shown', info.newVersion),
    onUpdateTapped: (info) => analytics.log('update_tapped'),
    onStoreOpenResult: (info, opened) => analytics.log('store_opened', opened),
    onDismissed: (info, reason) => analytics.log('update_dismissed', reason.name),
    onVersionSkipped: (info) => analytics.log('update_skipped'),
    onSuppressed: (info, reason) => analytics.log('update_suppressed', reason.name),
  ),
)
```

| Event | When |
| --- | --- |
| `onShown` | the dialog or page is on screen (reported once, and only when something was really shown) |
| `onUpdateTapped` | the user tapped the update button |
| `onStoreOpenResult` | the store opened (`true`) or failed to (`false`) after the tap. Not reported when `onUpdate` handles the tap |
| `onDismissed` | the user closed it without updating. `reason` is `button` or `system` (back button or tapping outside) |
| `onVersionSkipped` | the user chose "Skip this version" |
| `onSuppressed` | an update exists but the prompt was not shown because of "Later" or "Skip" ([reason](./later-and-skip.md): `snoozed` or `skippedVersion`) |
| `onInAppUpdateStarted` | a Google Play in-app update is about to start (Android) |
| `onInAppUpdateResult` | a Google Play in-app update finished, with its result |

Only the first outcome of a shown UI (update, skip or dismiss) is reported, so closing the dialog after
tapping a button is not counted twice.

For `showInAppUpdateDialog` you can also pass `events:` directly, which also covers Android.

## Errors in your callbacks

An error thrown by a callback you pass (an event, `onUpdate`, `onCancel` or `storeLauncher`) is reported
to `FlutterError.onError` and does **not** break the update flow: the dialog still closes and the
"Later" choice is still saved.

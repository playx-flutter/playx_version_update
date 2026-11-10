---
id: later-and-skip
title: Later and Skip
sidebar_position: 8
---

# Later and Skip

Without any setup, a prompt the user dismissed comes back on the next check. Pass `reminderOptions` so
"Later" and "Skip this version" are remembered:

```dart
await PlayxVersionUpdate.showUpdateDialog(
  context: context,
  reminderOptions: PlayxUpdateReminderOptions(
    snoozeDuration: Duration(days: 3), // null: prompt again next time
    allowSkipVersion: true,            // adds a "Skip this version" button
    storage: PrefsUpdateStorage(prefs), // keeps the choice across launches
  ),
);
```

## Rules

- **Later**: dismissing hides the prompt for that version until `snoozeDuration` (default one day) ends.
- **Skip**: hides that version for good.
- **A newer version** is prompted right away, even while another is snoozed.
- **Forced updates** are never hidden or recorded.
- `showUpdateDialog` returns `success(false)` when the prompt was suppressed, and
  `PlayxUpdateEvents.onSuppressed` fires.

For `showInAppUpdateDialog` use `iosReminderOptions`. Google Play's own in-app update screens are not
affected.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `storage` | in memory | where the choice is stored |
| `snoozeDuration` | 1 day | how long "Later" hides the prompt. `null` disables snoozing |
| `allowSkipVersion` | `false` | show the "Skip this version" button |
| `skipButtonText` | "Skip this version" | the button label |

## Storage

The package adds no storage dependency. The default `PlayxInMemoryUpdateStorage` forgets everything
when the app restarts. To keep the choice, implement `PlayxUpdateStorage` with the storage you already
use, for example `shared_preferences`:

```dart
class PrefsUpdateStorage implements PlayxUpdateStorage {
  PrefsUpdateStorage(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}
```

A storage that throws never blocks an update: the prompt is shown.

## Use it directly

`PlayxUpdateReminder` can be used for your own UI:

```dart
final reminder = PlayxUpdateReminder(PlayxUpdateReminderOptions(storage: storage));

if (await reminder.shouldPrompt(info)) {
  // show your prompt
}
await reminder.snooze(info);      // user chose "Later"
await reminder.skipVersion(info); // user chose "Skip"
await reminder.reset();           // forget everything
```

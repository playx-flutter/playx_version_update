import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';

PlayxVersionUpdateInfo _info(String newVersion, {bool force = false}) =>
    PlayxVersionUpdateInfo(
      localVersion: '1.0.0',
      newVersion: newVersion,
      country: 'us',
      storeUrl: 'https://store',
      canUpdate: true,
      forceUpdate: force,
    );

void main() {
  late DateTime now;
  late PlayxInMemoryUpdateStorage storage;

  PlayxUpdateReminder reminder({
    Duration? snooze = const Duration(days: 1),
    PlayxUpdateStorage? customStorage,
  }) => PlayxUpdateReminder(
    PlayxUpdateReminderOptions(
      storage: customStorage ?? storage,
      snoozeDuration: snooze,
    ),
    () => now,
  );

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    storage = PlayxInMemoryUpdateStorage();
  });

  test('prompts when nothing was stored', () async {
    expect(await reminder().shouldPrompt(_info('2.0.0')), isTrue);
  });

  test('snooze hides the prompt until the duration ends', () async {
    final r = reminder();
    await r.snooze(_info('2.0.0'));

    expect(
      await r.suppressionReason(_info('2.0.0')),
      PlayxPromptSuppressedReason.snoozed,
    );

    now = now.add(const Duration(hours: 23));
    expect(await r.shouldPrompt(_info('2.0.0')), isFalse);

    now = now.add(const Duration(hours: 2));
    expect(await r.shouldPrompt(_info('2.0.0')), isTrue);
  });

  test('a newer version is prompted even while snoozed', () async {
    final r = reminder();
    await r.snooze(_info('2.0.0'));
    expect(await r.shouldPrompt(_info('2.1.0')), isTrue);
  });

  test('skipping a version hides it forever but not newer ones', () async {
    final r = reminder();
    await r.skipVersion(_info('2.0.0'));

    now = now.add(const Duration(days: 365));
    expect(
      await r.suppressionReason(_info('2.0.0')),
      PlayxPromptSuppressedReason.skippedVersion,
    );
    expect(await r.shouldPrompt(_info('2.0.1')), isTrue);
  });

  test('null snoozeDuration disables snoozing', () async {
    final r = reminder(snooze: null);
    await r.snooze(_info('2.0.0'));
    expect(await r.shouldPrompt(_info('2.0.0')), isTrue);
  });

  test('forced updates are never suppressed or recorded', () async {
    final r = reminder();
    await r.skipVersion(_info('2.0.0', force: true));
    await r.snooze(_info('2.0.0', force: true));
    expect(await r.shouldPrompt(_info('2.0.0')), isTrue);

    await r.skipVersion(_info('2.0.0'));
    expect(await r.shouldPrompt(_info('2.0.0', force: true)), isTrue);
  });

  test('reset forgets everything', () async {
    final r = reminder();
    await r.skipVersion(_info('2.0.0'));
    await r.snooze(_info('3.0.0'));
    await r.reset();
    expect(await r.shouldPrompt(_info('2.0.0')), isTrue);
    expect(await r.shouldPrompt(_info('3.0.0')), isTrue);
  });

  test('storage failures never block the prompt', () async {
    final r = reminder(customStorage: _ThrowingStorage());
    await r.snooze(_info('2.0.0'));
    await r.skipVersion(_info('2.0.0'));
    await r.reset();
    expect(await r.shouldPrompt(_info('2.0.0')), isTrue);
  });
}

class _ThrowingStorage implements PlayxUpdateStorage {
  @override
  Future<String?> read(String key) => throw StateError('read');
  @override
  Future<void> write(String key, String value) => throw StateError('write');
  @override
  Future<void> remove(String key) => throw StateError('remove');
}

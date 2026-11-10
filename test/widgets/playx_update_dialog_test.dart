import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';

// The dialog renders on Android, iOS and macOS only, so these tests run when
// the tests are run on one of those hosts.
final _skipReason = Platform.isAndroid || Platform.isIOS || Platform.isMacOS
    ? null
    : 'The dialog is not rendered on ${Platform.operatingSystem}';

PlayxVersionUpdateInfo _info({bool force = false}) => PlayxVersionUpdateInfo(
  localVersion: '1.0.0',
  newVersion: '2.0.0',
  country: 'us',
  storeUrl: 'https://store',
  canUpdate: true,
  forceUpdate: force,
);

void main() {
  late List<String> log;
  late PlayxInMemoryUpdateStorage storage;

  Future<void> pump(
    WidgetTester tester, {
    bool force = false,
    bool allowSkip = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlayxUpdateDialog(
          versionUpdateInfo: _info(force: force),
          uiOptions: PlayxUpdateUIOptions(
            storeLauncher: (_) async {
              log.add('launcher');
              return true;
            },
            events: PlayxUpdateEvents(
              onShown: (_) => log.add('shown'),
              onUpdateTapped: (_) => log.add('update'),
              onStoreOpenResult: (_, opened) => log.add('opened:$opened'),
              onDismissed: (_, reason) => log.add('dismissed:${reason.name}'),
              onVersionSkipped: (_) => log.add('skipped'),
            ),
          ),
          reminder: PlayxUpdateReminder(
            PlayxUpdateReminderOptions(
              storage: storage,
              allowSkipVersion: allowSkip,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    log = [];
    storage = PlayxInMemoryUpdateStorage();
  });

  testWidgets('reports shown, then update and the store result', (
    tester,
  ) async {
    await pump(tester);
    expect(log, ['shown']);

    await tester.tap(find.text('Update'));
    await tester.pump();
    expect(log, ['shown', 'update', 'launcher', 'opened:true']);
  }, skip: _skipReason != null);

  testWidgets('dismissing reports it and snoozes the version', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Later'));
    await tester.pump();

    expect(log, ['shown', 'dismissed:button']);
    final reminder = PlayxUpdateReminder(
      PlayxUpdateReminderOptions(storage: storage),
    );
    expect(
      await reminder.suppressionReason(_info()),
      PlayxPromptSuppressedReason.snoozed,
    );
  }, skip: _skipReason != null);

  testWidgets('skip button reports it and remembers the version', (
    tester,
  ) async {
    await pump(tester, allowSkip: true);
    await tester.tap(find.text('Skip this version'));
    await tester.pump();

    expect(log, ['shown', 'skipped']);
    final reminder = PlayxUpdateReminder(
      PlayxUpdateReminderOptions(storage: storage),
    );
    expect(
      await reminder.suppressionReason(_info()),
      PlayxPromptSuppressedReason.skippedVersion,
    );
  }, skip: _skipReason != null);

  testWidgets('no skip button unless allowed, and never on a forced update', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Skip this version'), findsNothing);

    await pump(tester, force: true, allowSkip: true);
    expect(find.text('Skip this version'), findsNothing);
  }, skip: _skipReason != null);
}

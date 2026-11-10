import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';

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

  PlayxUpdateEvents events() => PlayxUpdateEvents(
    onShown: (_) => log.add('shown'),
    onUpdateTapped: (_) => log.add('update'),
    onDismissed: (_, reason) => log.add('dismissed:${reason.name}'),
    onVersionSkipped: (_) => log.add('skipped'),
  );

  Future<void> pump(
    WidgetTester tester, {
    bool force = false,
    bool allowSkip = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PlayxUpdatePage(
                  versionUpdateInfo: _info(force: force),
                  uiOptions: PlayxUpdateUIOptions(
                    events: events(),
                    onUpdate: (_, _) => log.add('onUpdate'),
                  ),
                  reminder: PlayxUpdateReminder(
                    PlayxUpdateReminderOptions(
                      storage: storage,
                      allowSkipVersion: allowSkip,
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    log = [];
    storage = PlayxInMemoryUpdateStorage();
  });

  testWidgets('reports shown and update tapped', (tester) async {
    await pump(tester);
    expect(log, ['shown']);

    await tester.tap(find.text('Update'));
    await tester.pump();
    expect(log.where((e) => e == 'update'), hasLength(1));
    expect(log.where((e) => e == 'onUpdate'), hasLength(1));
  });

  testWidgets('dismissing reports the event and snoozes the version', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Not Now'));
    await tester.pump();

    expect(log, ['shown', 'dismissed:button']);
    final reminder = PlayxUpdateReminder(
      PlayxUpdateReminderOptions(storage: storage),
    );
    expect(
      await reminder.suppressionReason(_info()),
      PlayxPromptSuppressedReason.snoozed,
    );
  });

  testWidgets('skip button is shown only when allowed', (tester) async {
    await pump(tester);
    expect(find.text('Skip this version'), findsNothing);
  });

  testWidgets('skipping reports the event and remembers the version', (
    tester,
  ) async {
    await pump(tester, allowSkip: true);
    await tester.tap(find.text('Skip this version'));
    await tester.pumpAndSettle();

    expect(log, ['shown', 'skipped']);
    final reminder = PlayxUpdateReminder(
      PlayxUpdateReminderOptions(storage: storage),
    );
    expect(
      await reminder.suppressionReason(_info()),
      PlayxPromptSuppressedReason.skippedVersion,
    );
    // The skip is not additionally reported as a dismissal.
    expect(log.any((e) => e.startsWith('dismissed')), isFalse);
  });

  testWidgets('no skip button on a forced update', (tester) async {
    await pump(tester, force: true, allowSkip: true);
    expect(find.text('Skip this version'), findsNothing);
  });
}

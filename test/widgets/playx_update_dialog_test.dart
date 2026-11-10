import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';

PlayxVersionUpdateInfo _info({bool force = false, bool canUpdate = true}) =>
    PlayxVersionUpdateInfo(
      localVersion: '1.0.0',
      newVersion: '2.0.0',
      country: 'us',
      storeUrl: 'https://store',
      canUpdate: canUpdate,
      forceUpdate: force,
      releaseNotes: 'Fixes',
    );

void main() {
  late List<String> log;
  late PlayxInMemoryUpdateStorage storage;

  Future<void> pump(
    WidgetTester tester, {
    bool force = false,
    bool canUpdate = true,
    bool allowSkip = false,
    PlayxUpdateUIOptions? uiOptions,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PlayxUpdateDialog(
                  versionUpdateInfo: _info(force: force, canUpdate: canUpdate),
                  uiOptions:
                      uiOptions ??
                      PlayxUpdateUIOptions(
                        showReleaseNotes: true,
                        storeLauncher: (_) async {
                          log.add('launcher');
                          return true;
                        },
                        events: PlayxUpdateEvents(
                          onShown: (_) => log.add('shown'),
                          onUpdateTapped: (_) => log.add('update'),
                          onStoreOpenResult: (_, opened) =>
                              log.add('opened:$opened'),
                          onDismissed: (_, reason) =>
                              log.add('dismissed:${reason.name}'),
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
              child: const Text('open'),
            ),
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

  tearDown(PlayxPlatform.debugResetCurrent);

  for (final platform in [
    PlayxPlatform.android,
    PlayxPlatform.ios,
    PlayxPlatform.macos,
  ]) {
    group(platform.name, () {
      setUp(() => PlayxPlatform.debugSetCurrent(platform));

      testWidgets('uses the dialog style of the platform', (tester) async {
        await pump(tester);

        expect(
          find.byType(AlertDialog),
          platform == PlayxPlatform.android ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(CupertinoAlertDialog),
          platform == PlayxPlatform.android ? findsNothing : findsOneWidget,
        );
        expect(find.text('New version available.'), findsOneWidget);
        expect(find.text('Fixes'), findsOneWidget);
      });

      testWidgets('reports shown, then update and the store result', (
        tester,
      ) async {
        await pump(tester);
        expect(log, ['shown']);

        await tester.tap(find.text('Update'));
        await tester.pumpAndSettle();
        expect(log, ['shown', 'update', 'launcher', 'opened:true']);
        // A dismissible dialog closes once the update is tapped.
        expect(find.text('Update'), findsNothing);
      });

      testWidgets('dismissing reports it and snoozes the version', (
        tester,
      ) async {
        await pump(tester);
        await tester.tap(find.text('Later'));
        await tester.pumpAndSettle();

        expect(log, ['shown', 'dismissed:button']);
        final reminder = PlayxUpdateReminder(
          PlayxUpdateReminderOptions(storage: storage),
        );
        expect(
          await reminder.suppressionReason(_info()),
          PlayxPromptSuppressedReason.snoozed,
        );
      });

      testWidgets('tapping outside reports a system dismissal', (tester) async {
        await pump(tester);
        await tester.tapAt(const Offset(2, 2));
        await tester.pumpAndSettle();

        expect(log, ['shown', 'dismissed:system']);
      });

      testWidgets('skip button reports it and remembers the version', (
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
      });

      testWidgets('no skip button unless allowed, never on a forced update', (
        tester,
      ) async {
        await pump(tester);
        expect(find.text('Skip this version'), findsNothing);

        Navigator.of(tester.element(find.byType(PlayxUpdateDialog))).pop();
        await tester.pumpAndSettle();

        await pump(tester, force: true, allowSkip: true);
        expect(find.text('Skip this version'), findsNothing);
      });

      testWidgets('a forced update has a "Close App" button and no barrier', (
        tester,
      ) async {
        await pump(tester, force: true);
        expect(find.text('Close App'), findsOneWidget);

        await tester.tapAt(const Offset(2, 2));
        await tester.pumpAndSettle();
        expect(find.text('Update'), findsOneWidget);
      });

      testWidgets('custom texts replace the defaults', (tester) async {
        await pump(
          tester,
          uiOptions: PlayxUpdateUIOptions(
            title: (info) => 'Hello ${info.newVersion}',
            description: (info) => 'Please update',
            updateButtonText: 'Go',
            dismissButtonText: 'Nope',
            releaseNotesTitle: (_) => 'News',
            showReleaseNotes: true,
          ),
        );

        expect(find.text('Hello 2.0.0'), findsOneWidget);
        expect(find.text('Please update'), findsOneWidget);
        expect(find.text('Go'), findsOneWidget);
        expect(find.text('Nope'), findsOneWidget);
        expect(find.text('News'), findsOneWidget);
      });

      testWidgets('shows nothing when no update can be installed', (
        tester,
      ) async {
        await pump(tester, canUpdate: false);
        expect(find.text('Update'), findsNothing);
        expect(log, isEmpty, reason: 'nothing was shown, nothing is reported');
      });
    });
  }

  for (final platform in [PlayxPlatform.windows, PlayxPlatform.linux, null]) {
    testWidgets('renders nothing on ${platform?.name ?? 'the web'}', (
      tester,
    ) async {
      PlayxPlatform.debugSetCurrent(platform);
      await pump(tester);
      expect(find.text('Update'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(log, isEmpty);
    });
  }
}

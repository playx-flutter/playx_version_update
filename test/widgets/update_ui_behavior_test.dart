import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late int exits;
  late List<String> log;

  setUp(() {
    exits = 0;
    log = [];
    PlayxPlatform.debugSetCurrent(PlayxPlatform.android);
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') exits++;
      return null;
    });
  });

  tearDown(() {
    PlayxPlatform.debugResetCurrent();
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Pushes a page (or shows a dialog) on top of a "home" route.
  Future<void> open(
    WidgetTester tester, {
    required bool page,
    bool force = false,
    PlayxUpdateUIOptions uiOptions = const PlayxUpdateUIOptions(),
    PlayxUpdateReminder? reminder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                final info = _info(force: force);
                if (page) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PlayxUpdatePage(
                        versionUpdateInfo: info,
                        uiOptions: uiOptions,
                        reminder: reminder,
                      ),
                    ),
                  );
                } else {
                  showDialog<void>(
                    context: context,
                    builder: (_) => PlayxUpdateDialog(
                      versionUpdateInfo: info,
                      uiOptions: uiOptions,
                      reminder: reminder,
                    ),
                  );
                }
              },
              child: const Text('home'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }

  final dismissLabel = {false: 'Later', true: 'Close App'};

  for (final page in [false, true]) {
    final name = page ? 'page' : 'dialog';
    final later = page ? 'Not Now' : 'Later';

    group(name, () {
      testWidgets('a dismissible $name closes and runs onCancel', (
        tester,
      ) async {
        await open(
          tester,
          page: page,
          uiOptions: PlayxUpdateUIOptions(onCancel: (_) => log.add('cancel')),
        );
        await tester.tap(find.text(later));
        await tester.pumpAndSettle();

        expect(log, ['cancel']);
        expect(find.text('Update'), findsNothing);
        expect(find.text('home'), findsOneWidget);
        expect(exits, 0);
      });

      testWidgets('a dismissible $name closes without an onCancel', (
        tester,
      ) async {
        await open(tester, page: page);
        await tester.tap(find.text(later));
        await tester.pumpAndSettle();

        expect(find.text('Update'), findsNothing);
        expect(exits, 0);
      });

      testWidgets('a forced $name with its own onCancel does not exit', (
        tester,
      ) async {
        await open(
          tester,
          page: page,
          force: true,
          uiOptions: PlayxUpdateUIOptions(onCancel: (_) => log.add('cancel')),
        );
        await tester.tap(find.text(dismissLabel[true]!));
        await tester.pumpAndSettle();

        expect(log, ['cancel']);
        expect(exits, 0, reason: 'onCancel replaces the default exit');
        expect(find.text('Update'), findsOneWidget, reason: 'still gated');
      });

      testWidgets('a forced $name without onCancel exits the app', (
        tester,
      ) async {
        await open(tester, page: page, force: true);
        await tester.tap(find.text(dismissLabel[true]!));
        await tester.pumpAndSettle();

        expect(exits, 1);
        expect(find.text('Update'), findsOneWidget, reason: 'still gated');
      });

      testWidgets('the back button cannot leave a forced $name', (
        tester,
      ) async {
        await open(tester, page: page, force: true);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Update'), findsOneWidget);
      });

      testWidgets('the back button dismisses a dismissible $name', (
        tester,
      ) async {
        await open(
          tester,
          page: page,
          uiOptions: PlayxUpdateUIOptions(
            events: PlayxUpdateEvents(
              onDismissed: (_, reason) => log.add(reason.name),
            ),
          ),
          reminder: PlayxUpdateReminder(
            PlayxUpdateReminderOptions(storage: PlayxInMemoryUpdateStorage()),
          ),
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(log, ['system']);
        expect(find.text('Update'), findsNothing);
      });

      testWidgets('a double tap on dismiss pops only the $name', (
        tester,
      ) async {
        await open(tester, page: page);
        await tester.tap(find.text(later));
        await tester.tap(find.text(later), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(
          find.text('home'),
          findsOneWidget,
          reason: 'home is still there',
        );
      });

      testWidgets('throwing callbacks do not break the flow', (tester) async {
        final reported = <Object>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) => reported.add(details.exception);
        addTearDown(() => FlutterError.onError = previous);

        final storage = PlayxInMemoryUpdateStorage();
        await open(
          tester,
          page: page,
          uiOptions: PlayxUpdateUIOptions(
            onCancel: (_) => throw StateError('cancel'),
            events: PlayxUpdateEvents(
              onShown: (_) => throw StateError('shown'),
              onDismissed: (_, _) => throw StateError('dismissed'),
            ),
          ),
          reminder: PlayxUpdateReminder(
            PlayxUpdateReminderOptions(storage: storage),
          ),
        );
        await tester.tap(find.text(later));
        await tester.pumpAndSettle();

        // The $name closed and the version was still snoozed.
        expect(find.text('Update'), findsNothing);
        final reminder = PlayxUpdateReminder(
          PlayxUpdateReminderOptions(storage: storage),
        );
        expect(
          await reminder.suppressionReason(_info()),
          PlayxPromptSuppressedReason.snoozed,
        );
        // Every error reached the app: shown, dismissed and onCancel.
        expect(
          reported.map((e) => (e as StateError).message),
          unorderedEquals(['shown', 'dismissed', 'cancel']),
        );
      });
    });
  }

  testWidgets('a throwing onUpdate is reported and the dialog still closes', (
    tester,
  ) async {
    await open(
      tester,
      page: false,
      uiOptions: PlayxUpdateUIOptions(
        onUpdate: (_, _) => throw StateError('update'),
      ),
    );
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Update'), findsNothing);
    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('tapping update twice quickly launches the store once', (
    tester,
  ) async {
    var launches = 0;
    await open(
      tester,
      page: true,
      uiOptions: PlayxUpdateUIOptions(
        storeLauncher: (_) async {
          launches++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return true;
        },
      ),
    );

    await tester.tap(find.text('Update'));
    await tester.tap(find.text('Update'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(launches, 1);
  });
}

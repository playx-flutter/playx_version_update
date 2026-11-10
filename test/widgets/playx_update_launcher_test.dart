import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/playx_version_update.dart';

const _info = PlayxVersionUpdateInfo(
  localVersion: '1.0.0',
  newVersion: '2.0.0',
  country: 'us',
  storeUrl: 'https://store',
  canUpdate: true,
  forceUpdate: false,
);

void main() {
  late List<String> log;

  Future<void> pumpPage(
    WidgetTester tester, {
    UpdatePressedCallback? onUpdate,
    StoreLauncherCallback? storeLauncher,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlayxUpdatePage(
          versionUpdateInfo: _info,
          uiOptions: PlayxUpdateUIOptions(
            onUpdate: onUpdate,
            storeLauncher: storeLauncher,
            events: PlayxUpdateEvents(
              onUpdateTapped: (_) => log.add('tapped'),
              onStoreOpenResult: (_, opened) => log.add('opened:$opened'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Update'));
    await tester.pump();
  }

  setUp(() => log = []);

  testWidgets('storeLauncher receives the info and its result is reported', (
    tester,
  ) async {
    PlayxVersionUpdateInfo? received;
    await pumpPage(
      tester,
      storeLauncher: (info) async {
        received = info;
        return true;
      },
    );

    expect(received, _info);
    expect(log, ['tapped', 'opened:true']);
  });

  testWidgets('a storeLauncher returning false reports opened:false', (
    tester,
  ) async {
    await pumpPage(tester, storeLauncher: (_) async => false);
    expect(log, ['tapped', 'opened:false']);
  });

  testWidgets('a throwing storeLauncher reports opened:false', (tester) async {
    await pumpPage(tester, storeLauncher: (_) async => throw StateError('x'));
    expect(log, ['tapped', 'opened:false']);
    // The error is reported to the app instead of being swallowed.
    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('onUpdate wins over storeLauncher and reports no result', (
    tester,
  ) async {
    var launcherCalled = false;
    var onUpdateCalled = false;
    await pumpPage(
      tester,
      onUpdate: (_, _) => onUpdateCalled = true,
      storeLauncher: (_) async {
        launcherCalled = true;
        return true;
      },
    );

    expect(onUpdateCalled, isTrue);
    expect(launcherCalled, isFalse);
    expect(log, ['tapped']);
  });

  testWidgets('the default launcher reports a failure when nothing can open', (
    tester,
  ) async {
    // The (mocked) platform cannot open any link.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async => false,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      ),
    );

    await pumpPage(tester);
    await tester.pump();
    expect(log, ['tapped', 'opened:false']);
  });
}

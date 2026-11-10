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

  PlayxUpdateEvents events() => PlayxUpdateEvents(
    onShown: (_) => log.add('shown'),
    onUpdateTapped: (_) => log.add('update'),
    onDismissed: (_, reason) => log.add('dismissed:${reason.name}'),
  );

  Future<void> pump(WidgetTester tester, {bool force = false}) async {
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

  setUp(() => log = []);

  testWidgets('reports shown and update tapped', (tester) async {
    await pump(tester);
    expect(log, ['shown']);

    await tester.tap(find.text('Update'));
    await tester.pump();
    expect(log.where((e) => e == 'update'), hasLength(1));
    expect(log.where((e) => e == 'onUpdate'), hasLength(1));
  });

  testWidgets('dismissing reports the event', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Not Now'));
    await tester.pump();

    expect(log, ['shown', 'dismissed:button']);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update_example/main.dart';

/// Pumps the example at [size] and fails on any layout error (overflow, ...).
Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const MyApp(),
    ),
  );
}

void main() {
  for (final size in const [Size(360, 640), Size(1200, 800)]) {
    group('${size.width.toInt()}x${size.height.toInt()}', () {
      testWidgets('main screen lists the sections', (tester) async {
        await _pumpApp(tester, size);

        expect(find.text('Tap an action to see its result here.'), findsOne);
        expect(find.text('Check for updates'), findsOne);
        expect(find.text('Show update dialog'), findsOne);
        expect(tester.takeException(), isNull);
      });

      testWidgets('opens the features screen', (tester) async {
        await _pumpApp(tester, size);

        await tester.scrollUntilVisible(
          find.text('More features'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('More features'));
        await tester.pumpAndSettle();

        expect(find.text('Event log'), findsOne);
        expect(find.text('Events + Later + Skip'), findsOne);
        expect(find.text('Events and results appear here.'), findsOne);
        expect(tester.takeException(), isNull);
      });
    });
  }
}

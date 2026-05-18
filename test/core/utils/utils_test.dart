import 'package:flutter_test/flutter_test.dart';
import 'package:playx_version_update/src/core/utils/utils.dart';

void main() {
  group('getFormattedHtmlText', () {
    test('returns null when input is null', () {
      expect(getFormattedHtmlText(null), isNull);
    });

    test('decodes unicode escapes and common html entities', () {
      expect(
        getFormattedHtmlText(r'Hello \u0041 &quot;World&quot; &apos;test&#39;'),
        'Hello A "World" \'test\'',
      );
    });

    test('converts paragraph and line-break tags into newlines', () {
      expect(
        getFormattedHtmlText('<p>Line 1</p><br>Line 2'),
        'Line 1\n\n\nLine 2',
      );
    });

    test('preserves lt and gt direction correctly', () {
      expect(
        getFormattedHtmlText('Use &lt;tag&gt; here'),
        'Use <tag> here',
      );
    });

    test('strips remaining tags and unknown entities', () {
      expect(
        getFormattedHtmlText('<div>Hello&nbsp;<strong>world</strong></div>'),
        'Hello  world',
      );
    });
  });
}

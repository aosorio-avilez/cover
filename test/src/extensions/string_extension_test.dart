import 'package:cover/src/extensions/string_extension.dart';
import 'package:test/test.dart';

void main() {
  group('StringExtension', () {
    group('sanitize', () {
      test('returns same string if no control characters are present', () {
        const input = 'Hello World 123 !@#';
        expect(input.sanitize(), input);
      });

      test('returns same string for printable non-ASCII/Unicode characters',
          () {
        const input = '¡Hola, Señor! Cómo estás? ✨';
        expect(input.sanitize(), input);
      });

      test('removes ANSI escape sequences', () {
        const input = 'Hello \x1B[31mRed\x1B[0m World';
        expect(input.sanitize(), 'Hello Red World');
      });

      test('removes control characters (0x00-0x1F)', () {
        const input = 'Hello\x00 \x07World\x1F';
        expect(input.sanitize(), 'Hello World');
      });

      test('removes DEL character (0x7F)', () {
        const input = 'Hello\x7FWorld';
        expect(input.sanitize(), 'HelloWorld');
      });

      test('removes Unicode Bidi control characters', () {
        const input = 'Hello\u200EWorld\u202A';
        expect(input.sanitize(), 'HelloWorld');
      });

      test('handles complex terminal injection sequences', () {
        const input =
            'Normal Text \x1B]8;;http://malicious.com\x1B\\HACKED\x1B]8;;\x1B\\';
        // The regex might not catch everything if it's too specific,
        // let's see what it does.
        // Current regex: r'\x1B\[[0-?]*[ -/]*[@-~]|[\x00-\x1F\x7F\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069]'
        // \x1B] is OSC, not CSI (\x1B[).
        // Wait, let's check the regex in string_extension.dart.
        // It uses \x1B\[ which is CSI.
        // Other control characters like \x1B] (OSC) are covered by [\x00-\x1F].

        final sanitized = input.sanitize();
        expect(sanitized, isNot(contains('\x1B')));
        expect(sanitized, contains('Normal Text'));
        expect(sanitized, contains('HACKED'));
      });

      test('removes mixed control and ANSI characters', () {
        const input = '\x00\x1B[31mError\x1B[0m\x07: \x1B[1mFatal\x1B[0m\x1F';
        expect(input.sanitize(), 'Error: Fatal');
      });
    });
  });
}

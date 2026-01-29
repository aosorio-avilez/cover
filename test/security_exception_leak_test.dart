import 'dart:io';
import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

void main() {
  test('Gracefully handle malformed LCOV file without crashing', () async {
    final console = MockConsole();
    final runner = CoverCommandRunner(console: console);

    // Create a garbage file that triggers StateError in lcov_parser
    final file = File('malformed.lcov');
    await file.writeAsString('GARBAGE CONTENT');

    try {
      // This should NOT throw an exception. It should catch it internally and return an exit code.
      final exitCode = await runner.run(['check', '--path', 'malformed.lcov']);

      // Verify it returned a failure code (likely usage error mapped from FormatException)
      expect(exitCode, equals(ExitCode.usage.code));

      // Verify error message was printed
      final captured = verify(() => console.writeErrorLine(captureAny())).captured;
      final message = captured.first as String;

      // Verify the message indicates a parsing failure and NOT a raw internal error
      expect(message, contains('Failed to parse coverage file'));

    } finally {
      if (await file.exists()) await file.delete();
    }
  });
}

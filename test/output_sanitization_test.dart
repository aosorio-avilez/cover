import 'dart:io';

import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/console_mock.dart';

void main() {
  late Console console;
  late CoverCommandRunner runner;
  late Directory tempDir;
  late File lcovFile;
  late Directory originalCwd;

  setUpAll(() {
    registerFallbackValue(Table());
  });

  setUp(() async {
    console = ConsoleMock();
    runner = CoverCommandRunner(console: console);
    originalCwd = Directory.current;
    tempDir = await Directory.systemTemp.createTemp('cover_sanitization_test');
    Directory.current = tempDir;
    lcovFile = File('lcov.info');
  });

  tearDown(() async {
    Directory.current = originalCwd;
    await tempDir.delete(recursive: true);
  });

  test(
      'Output Sanitization: verify filename with ANSI codes is displayed (reproduction)',
      () async {
    // \x1b[31m is Red color in ANSI.
    const maliciousFilename = 'malicious\x1b[31m.dart';
    const escapedFilename = 'malicious.dart'; // We expect this after fix

    // Create an lcov file with a malicious filename
    // Note: lcov_parser might need the file to exist?
    // Usually lcov files point to source files.
    // If the tool checks if source file exists, we might need to create it.
    // Based on code reading, it does NOT check source file existence, only lcov parsing.

    await lcovFile.writeAsString('''
TN:
SF:$maliciousFilename
DA:1,1
LF:1
LH:1
end_of_record
''');

    // Run the command
    final exitCode =
        await runner.run(['check', '--path', lcovFile.path, '--display-files']);

    expect(exitCode, ExitCode.success.code);

    // Capture the Table object passed to console.write
    final captured = verify(() => console.write(captureAny())).captured;
    expect(captured.length, greaterThanOrEqualTo(1));

    // The table is usually the first write
    final table = captured.first as Table;

    // Convert table to string to inspect content
    final tableString = table.toString();

    // AFTER FIX: The table string should NOT contain the ANSI code inside the filename cell.
    // It should contain the sanitized filename.

    // Check coverage command:
    // '$color$file'

    // If we look for the filename in the output.
    expect(tableString, isNot(contains(maliciousFilename)));
    expect(tableString, contains(escapedFilename));
  });
}

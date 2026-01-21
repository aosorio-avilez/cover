import 'dart:io';

import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/console_mock.dart';

void main() {
  late Console console;
  late CoverCommandRunner runner;
  late Directory tempDir;
  late File lcovFile;

  setUpAll(() {
    registerFallbackValue(Table());
  });

  setUp(() async {
    console = ConsoleMock();
    tempDir = await Directory.systemTemp.createTemp('cover_sanitization_test');
    final service = CoverageService(currentDirectory: tempDir);
    runner = CoverCommandRunner(console: console, service: service);
    lcovFile = File('${tempDir.path}/lcov.info');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test(
      'Output Sanitization: verify filename with ANSI codes is displayed (reproduction)',
      () async {
    // \x1b[31m is Red color in ANSI.
    const maliciousFilename = 'malicious\x1b[31m.dart';
    const escapedFilename = 'malicious.dart'; // We expect this after fix

    await lcovFile.writeAsString('''
TN:
SF:$maliciousFilename
DA:1,1
LF:1
LH:1
end_of_record
''');

    // Run the command. Path is relative to tempDir because CoverageService knows its CWD.
    final exitCode =
        await runner.run(['check', '--path', 'lcov.info', '--display-files']);

    expect(exitCode, ExitCode.success.code);

    final captured = verify(() => console.write(captureAny())).captured;
    expect(captured.length, greaterThanOrEqualTo(1));

    final table = captured.first as Table;
    final tableString = table.toString();

    expect(tableString, isNot(contains(maliciousFilename)));
    expect(tableString, contains(escapedFilename));
  });
}

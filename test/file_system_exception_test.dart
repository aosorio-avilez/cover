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

  setUpAll(() {
    registerFallbackValue(Table());
  });

  setUp(() async {
    console = ConsoleMock();
    tempDir = await Directory.systemTemp.createTemp('cover_crash_test');
    final service = CoverageService(currentDirectory: tempDir);
    runner = CoverCommandRunner(console: console, service: service);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('FileSystemException Handling: verify FileSystemException is caught and handled gracefully', () async {
    // Passing '.' (current directory) as path.
    // This should cause FileSystemException: Is a directory.
    // We expect it to be caught and return ExitCode.osFile.code.
    // But currently it crashes.

    // We use try-catch to assert the crash if it happens, or check exit code if fixed.
    try {
      final exitCode = await runner.run(['check', '--path', '.']);
      expect(exitCode, ExitCode.osFile.code);

      // Verify error message is printed
      final captured = verify(() => console.writeErrorLine(captureAny())).captured;
      expect(captured.isNotEmpty, isTrue);
      expect(captured.first, contains('Is a directory'));

    } catch (e) {
      // If it crashes, it throws.
      expect(e, isA<FileSystemException>());
      // Fail the test explicitly to show it crashes (reproduction)
      fail('Crashed with FileSystemException: $e');
    }
  });
}

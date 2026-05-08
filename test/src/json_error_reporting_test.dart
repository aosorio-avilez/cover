import 'dart:convert';
import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class ConsoleMock extends Mock implements Console {}

void main() {
  late Console console;
  late CoverCommandRunner runner;

  setUpAll(() {
    registerFallbackValue(TextAlignment.left);
  });

  setUp(() {
    console = ConsoleMock();
    runner = CoverCommandRunner(console: console);
  });

  group('CheckCoverageCommand JSON errors', () {
    test(
        'should return JSON error when --json is provided and --min-coverage is invalid',
        () async {
      final exitCode = await runner.run([
        'check',
        '--json',
        '--min-coverage',
        'invalid',
      ]);

      expect(exitCode, ExitCode.usage.code);

      final captured =
          verify(() => console.writeLine(captureAny(), any())).captured;
      final output = captured.first as String;

      final decoded = jsonDecode(output) as Map<String, dynamic>;
      expect(decoded['error'], contains('Invalid value for --min-coverage'));
      expect(decoded['exit_code'], 64);
    });
  });

  group('CoverCommandRunner JSON errors', () {
    test(
        'should return JSON error when top-level --json is provided and command is missing',
        () async {
      final exitCode = await runner.run([
        '--json',
      ]);

      expect(exitCode, ExitCode.usage.code);

      final captured =
          verify(() => console.writeLine(captureAny(), any())).captured;
      final output = captured.first as String;

      final decoded = jsonDecode(output) as Map<String, dynamic>;
      expect(decoded['error'], contains('Missing subcommand'));
      expect(decoded['exit_code'], 64);
    });

    test('should return JSON error when -j is provided and command is invalid',
        () async {
      final exitCode = await runner.run([
        '-j',
        'invalid_command',
      ]);

      expect(exitCode, ExitCode.usage.code);

      final captured =
          verify(() => console.writeLine(captureAny(), any())).captured;
      final output = captured.first as String;

      final decoded = jsonDecode(output) as Map<String, dynamic>;
      expect(
        decoded['error'],
        contains('Could not find a command named "invalid_command"'),
      );
      expect(decoded['exit_code'], 64);
    });
  });
}

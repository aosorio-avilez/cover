import 'dart:convert';
import 'package:args/args.dart';
import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import '../mocks/coverage_service_mock.dart';

class ConsoleMock extends Mock implements Console {}

class _CrashingCoverCommandRunner extends CoverCommandRunner {
  _CrashingCoverCommandRunner({super.console});

  @override
  ArgResults parse(Iterable<String> args) {
    throw Exception('Unexpected parse error');
  }
}

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

    test(
        'should return JSON error when an unexpected error occurs and --json is provided',
        () async {
      final service = CoverageServiceMock();
      final runner = CoverCommandRunner(console: console, service: service);

      when(() => service.checkCoverage(
            filePath: any(named: 'filePath'),
            minCoverage: any(named: 'minCoverage'),
            excludePaths: any(named: 'excludePaths'),
            excludeGenerated: any(named: 'excludeGenerated'),
          )).thenThrow(Exception('Unexpected error'));

      final exitCode = await runner.run([
        'check',
        '--json',
      ]);

      expect(exitCode, ExitCode.software.code);

      final captured =
          verify(() => console.writeLine(captureAny(), any())).captured;
      final output = captured.first as String;

      final decoded = jsonDecode(output) as Map<String, dynamic>;
      expect(decoded['error'], contains('An unexpected error occurred'));
      expect(decoded['exit_code'], 70);
      expect(decoded['status'], 'software');
    });

    test(
        'should return JSON error when a truly unexpected error occurs and --json is provided',
        () async {
      final runner = _CrashingCoverCommandRunner(console: console);

      final exitCode = await runner.run([
        '--json',
      ]);

      expect(exitCode, ExitCode.software.code);

      final captured =
          verify(() => console.writeLine(captureAny())).captured;
      final output = captured.first as String;

      final decoded = jsonDecode(output) as Map<String, dynamic>;
      expect(decoded['error'], contains('An unexpected error occurred'));
      expect(decoded['error'], contains('Unexpected parse error'));
      expect(decoded['exit_code'], 70);
      expect(decoded['status'], 'software');
    });

    test(
        'should return error line when a truly unexpected error occurs and --json is NOT provided',
        () async {
      final runner = _CrashingCoverCommandRunner(console: console);

      final exitCode = await runner.run([]);

      expect(exitCode, ExitCode.software.code);
      verify(() => console.writeErrorLine(any())).called(1);
    });
  });
}

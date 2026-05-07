import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks/console_mock.dart';
import '../mocks/coverage_service_mock.dart';

class MockExceptionCommand extends Command<int> {
  MockExceptionCommand({required this.name, required this.exception});

  @override
  final String name;

  @override
  String get description => 'Mock command';

  final Object exception;

  @override
  Future<int> run() async {
    final exc = exception;
    if (exc is Exception) {
      throw exc;
    }
    if (exc is Error) {
      throw exc;
    }
    throw Exception(exc.toString());
  }
}

void main() {
  late Console console;
  late CoverCommandRunner runner;

  setUp(() {
    console = ConsoleMock();
    runner = CoverCommandRunner(console: console);
  });

  group('Robustness Tests', () {
    test(
        'verify check coverage command fails with invalid min-coverage (too high)',
        () async {
      final exitCode = await runner.run(['check', '--min-coverage', '101']);
      expect(exitCode, ExitCode.usage.code);
      verify(
        () => console.writeErrorLine(
          any(that: contains('Expected a number between 0 and 100')),
        ),
      ).called(1);
    });

    test(
        'verify check coverage command fails with invalid min-coverage (too low)',
        () async {
      final exitCode = await runner.run(['check', '--min-coverage', '-1']);
      expect(exitCode, ExitCode.usage.code);
      verify(
        () => console.writeErrorLine(
          any(that: contains('Expected a number between 0 and 100')),
        ),
      ).called(1);
    });

    test('verify check coverage command JSON error reporting', () async {
      final service = CoverageServiceMock();
      final runnerWithMock =
          CoverCommandRunner(console: console, service: service);

      when(
        () => service.checkCoverage(
          filePath: any(named: 'filePath'),
          minCoverage: any(named: 'minCoverage'),
          excludePaths: any(named: 'excludePaths'),
          excludeGenerated: any(named: 'excludeGenerated'),
        ),
      ).thenThrow(const FormatException('Invalid format'));

      final exitCode = await runnerWithMock.run(['check', '--json']);

      expect(exitCode, ExitCode.usage.code);
      verify(
        () => console.writeLine(
          any(that: contains('"error":"Invalid format"')),
        ),
      ).called(1);
    });

    test('verify runner handles UsageException', () async {
      final exitCode = await runner.run(['--invalid-flag']);
      expect(exitCode, ExitCode.usage.code);
      verify(() => console.writeErrorLine(any())).called(1);
    });

    test('verify runner handles FormatException from ArgParser', () async {
      final exitCode = await runner.run(['check', '--min-coverage']);
      expect(exitCode, ExitCode.usage.code);
      verify(() => console.writeErrorLine(any())).called(1);
    });

    test('verify runner handles PathNotFoundException', () async {
      runner.addCommand(
        MockExceptionCommand(
          name: 'error-path',
          exception: const PathNotFoundException('path', OSError('msg', 2)),
        ),
      );
      final exitCode = await runner.run(['error-path']);
      expect(exitCode, ExitCode.osFile.code);
    });

    test('verify runner handles FileSystemException', () async {
      runner.addCommand(
        MockExceptionCommand(
          name: 'error-fs',
          exception: const FileSystemException('msg'),
        ),
      );
      final exitCode = await runner.run(['error-fs']);
      expect(exitCode, ExitCode.osFile.code);
    });

    test('verify runner handles unexpected exceptions (catch-all)', () async {
      runner.addCommand(
        MockExceptionCommand(
          name: 'error-generic',
          exception: StateError('Runner unexpected state'),
        ),
      );
      final exitCode = await runner.run(['error-generic']);
      expect(exitCode, ExitCode.software.code);
      verify(
        () => console.writeErrorLine(
          any(that: contains('An unexpected error occurred')),
        ),
      ).called(1);
    });

    test('verify global exception handler catches unexpected errors', () async {
      final service = CoverageServiceMock();
      final runnerWithMock =
          CoverCommandRunner(console: console, service: service);

      when(
        () => service.checkCoverage(
          filePath: any(named: 'filePath'),
          minCoverage: any(named: 'minCoverage'),
          excludePaths: any(named: 'excludePaths'),
          excludeGenerated: any(named: 'excludeGenerated'),
        ),
      ).thenThrow(StateError('Unexpected state'));

      final exitCode = await runnerWithMock.run(['check']);

      expect(exitCode, ExitCode.software.code);
      verify(
        () => console.writeErrorLine(
          any(that: contains('An unexpected error occurred')),
        ),
      ).called(1);
    });
  });
}

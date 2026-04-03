import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks/console_mock.dart';
import '../mocks/coverage_service_mock.dart';

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
          contains('Expected a number between 0 and 100'),
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
          contains('Expected a number between 0 and 100'),
        ),
      ).called(1);
    });

    test(
        'verify check coverage command fails with invalid min-coverage (not a number)',
        () async {
      final exitCode = await runner.run(['check', '--min-coverage', 'abc']);
      expect(exitCode, ExitCode.usage.code);
      verify(
        () => console.writeErrorLine(
          contains('Expected a number between 0 and 100'),
        ),
      ).called(1);
    });

    test('verify check coverage command fails with invalid min-coverage (NaN)',
        () async {
      final exitCode = await runner.run(['check', '--min-coverage', 'NaN']);
      expect(exitCode, ExitCode.usage.code);
      verify(
        () => console.writeErrorLine(
          contains('Expected a number between 0 and 100'),
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
        ),
      ).thenThrow(StateError('Unexpected state'));

      final exitCode = await runnerWithMock.run(['check']);

      expect(exitCode, ExitCode.software.code);
      verify(
        () => console.writeErrorLine(
          contains(
            'An unexpected error occurred: Bad state: Unexpected state',
          ),
        ),
      ).called(1);
    });
  });
}

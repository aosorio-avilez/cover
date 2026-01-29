import 'package:cli_completion/cli_completion.dart';
import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks/console_mock.dart';
import '../mocks/coverage_service_mock.dart';

void main() {
  late Console console;
  late CoverCommandRunner commandRunner;

  setUp(() {
    console = ConsoleMock();
    commandRunner = CoverCommandRunner(console: console);
  });

  test('verify can be instantiated without an explicit console instance', () {
    final commandRunner = CoverCommandRunner();
    expect(commandRunner, isNotNull);
    expect(commandRunner, isA<CompletionCommandRunner<int>>());
  });

  test('verify cover command runner catch FileMustBeProvided', () async {
    final exitCode = await commandRunner.run(['check', '--path', '']);

    expect(exitCode, ExitCode.osFile.code);
    verifyConsoleWrites(console);
  });

  test('verify cover command runner catch UsageException', () async {
    final exitCode = await commandRunner.run(['check', '--min-']);

    expect(exitCode, ExitCode.usage.code);
    verifyConsoleWrites(console);
  });

  test('''verify cover command runner catch FormatException''', () async {
    final exitCode = await commandRunner.run([
      'check',
      '--path',
      'test/stubs/lcov_empty.info',
    ]);

    expect(exitCode, ExitCode.usage.code);
    verifyConsoleWrites(console);
  });

  test('''verify cover command runner catch PathNotFoundException''', () async {
    final exitCode = await commandRunner.run([
      'check',
      '--path',
      'coverage/path-not-found.info',
    ]);

    expect(exitCode, ExitCode.osFile.code);
    verifyConsoleWrites(console);
  });

  test('verify cover command runner catch FileMustBeProvided', () async {
    final service = CoverageServiceMock();
    final commandRunner = CoverCommandRunner(
      console: console,
      service: service,
    );

    when(
      () => service.checkCoverage(
        filePath: any(named: 'filePath'),
        minCoverage: any(named: 'minCoverage'),
      ),
    ).thenThrow(FileMustBeProvided());

    final exitCode = await commandRunner.run([
      'check',
      '--path',
      'coverage/lcov.info',
    ]);

    expect(exitCode, ExitCode.osFile.code);
    verifyConsoleWrites(console);
  });

  test('verify version', () async {
    final exitCode = await commandRunner.run(['--version']);

    expect(exitCode, ExitCode.success.code);
    verify(() => console.writeLine(any()));
  });
}

void verifyConsoleWrites(Console console) {
  verify(() => console.writeErrorLine(any())).called(1);
  verify(() => console.writeLine(any())).called(2);
}

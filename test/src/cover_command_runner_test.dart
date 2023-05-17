import 'package:cli_completion/cli_completion.dart';
import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks/console_mock.dart';

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

  test('''verify cover command runner catch FileMustBeProvided''', () async {
    final exitCode = await commandRunner.run(['check', '--path', '']);

    expect(exitCode, ExitCode.osFile.code);
  });

  test('''verify cover command runner catch UsageException''', () async {
    final exitCode = await commandRunner.run(['check', '--min-']);

    expect(exitCode, ExitCode.usage.code);
    verify(() => console.writeErrorLine(any())).called(2);
    verify(() => console.writeLine(any())).called(2);
  });

  test('''verify cover command runner catch FormatException''', () async {
    final exitCode = await commandRunner
        .run(['check', '--path', 'test/stubs/lcov_empty.info']);

    expect(exitCode, ExitCode.usage.code);
    verify(() => console.writeErrorLine(any())).called(2);
    verify(() => console.writeLine(any())).called(1);
  });

  test('''verify cover command runner catch PathNotFoundException''', () async {
    final exitCode = await commandRunner
        .run(['check', '--path', 'coverage/path-not-found.info']);

    expect(exitCode, ExitCode.osFile.code);
    verify(() => console.writeErrorLine(any())).called(2);
    verify(() => console.writeLine(any())).called(1);
  });
}

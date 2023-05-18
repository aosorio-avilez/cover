import 'package:cover/src/commands/check_coverage_command.dart';
import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../mocks/console_mock.dart';

void main() {
  late Console console;
  late CoverCommandRunner runner;

  setUp(() {
    console = ConsoleMock();
    runner = CoverCommandRunner(console: console);
  });

  test('verify check description', () async {
    final command = CheckCoverageCommand(console);

    expect(command.description, commandDescription);
  });

  test('verify check coverage command return success exit code', () async {
    final exitCode =
        await runner.run(['check', '--path', 'test/stubs/lcov_complete.info']);

    expect(exitCode, ExitCode.success.code);
    verify(() => console.write(any())).called(1);
    verify(() => console.writeLine(any())).called(2);
    verify(() => console.resetColorAttributes()).called(1);
  });

  test('verify check coverage command return fail exit code', () async {
    final exitCode = await runner
        .run(['check', '--path', 'test/stubs/lcov_incomplete.info']);

    expect(exitCode, ExitCode.fail.code);
    verify(() => console.write(any())).called(1);
    verify(() => console.writeLine(any())).called(2);
    verify(() => console.resetColorAttributes()).called(1);
  });

  test('verify check coverage command return os file exit code', () async {
    final exitCode =
        await runner.run(['check', '--path', 'test/stubs/file_not_found.info']);

    expect(exitCode, ExitCode.osFile.code);
    verifyNever(() => console.write(any()));
    verifyNever(() => console.resetColorAttributes());
  });

  test('verify check coverage command return usage exit code', () async {
    final exitCode = await runner.run(['check', '--path']);

    expect(exitCode, ExitCode.usage.code);
    verifyNever(() => console.write(any()));
    verifyNever(() => console.resetColorAttributes());
  });

  test(
      '''verify check coverage command return fail exit code when file is empty''',
      () async {
    final exitCode =
        await runner.run(['check', '--path', 'test/stubs/lcov_empty.info']);

    expect(exitCode, ExitCode.usage.code);
    verifyNever(() => console.write(any()));
    verifyNever(() => console.resetColorAttributes());
  });

  test('''verify check command no display table with --no-display-files flag''',
      () async {
    final exitCode = await runner.run([
      'check',
      '--path',
      'test/stubs/lcov_complete.info',
      '--no-display-files'
    ]);

    expect(exitCode, ExitCode.success.code);
    verifyNever(() => console.write(any()));
    verify(() => console.writeLine(any())).called(2);
    verify(() => console.resetColorAttributes()).called(1);
  });
}

import 'dart:convert';

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

  setUpAll(() {
    registerFallbackValue(TextAlignment.left);
  });

  setUp(() {
    console = ConsoleMock();
    runner = CoverCommandRunner(console: console);
  });

  test('verify check description', () async {
    final command = CheckCoverageCommand(console);

    expect(command.description, commandDescription);
  });

  test('verify check coverage command return success exit code', () async {
    final exitCode = await runner.run([
      'check',
      '--path',
      'test/stubs/lcov_complete.info',
    ]);

    expect(exitCode, ExitCode.success.code);
    verify(() => console.write(any())).called(1);
    verify(() => console.writeLine(any(), any())).called(2);
    verify(() => console.resetColorAttributes()).called(1);
  });

  test('verify check coverage command return fail exit code', () async {
    final exitCode = await runner.run([
      'check',
      '--path',
      'test/stubs/lcov_incomplete.info',
    ]);

    expect(exitCode, ExitCode.fail.code);
    verify(() => console.write(any())).called(1);
    verify(() => console.writeLine(any(), any())).called(2);
    verify(() => console.resetColorAttributes()).called(1);
  });

  test('verify check coverage command return os file exit code', () async {
    final exitCode = await runner.run([
      'check',
      '--path',
      'test/stubs/file_not_found.info',
    ]);

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
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_empty.info',
      ]);

      expect(exitCode, ExitCode.usage.code);
      verifyNever(() => console.write(any()));
      verifyNever(() => console.resetColorAttributes());
    },
  );

  test(
    '''verify check command no display table with --no-display-files flag''',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_complete.info',
        '--no-display-files',
      ]);

      expect(exitCode, ExitCode.success.code);
      verifyNever(() => console.write(any()));
      verify(() => console.writeLine(any(), any())).called(2);
      verify(() => console.resetColorAttributes()).called(1);
    },
  );

  test(
    'verify check coverage command exclude paths with --excluded-files flag',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_uncovered.info',
        '--excluded-paths',
        '/datasources',
      ]);

      expect(exitCode, ExitCode.success.code);
      verify(() => console.write(any())).called(1);
      verify(() => console.writeLine(any(), any())).called(2);
      verify(() => console.resetColorAttributes()).called(1);
    },
  );

  test(
    'verify check coverage command return json with --json flag',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_complete.info',
        '--json',
      ]);

      expect(exitCode, ExitCode.success.code);
      final captured = verify(() => console.writeLine(captureAny(), any())).captured;
      final jsonOutput = captured.first as String;
      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;

      expect(decoded['coverage'], 100.0);
      expect(decoded['min_coverage'], 100.0);
      expect(decoded['passed'], isTrue);
      expect(decoded['timestamp'], isA<String>());
      expect(decoded['files_count'], 17);
      expect(decoded['files'], isA<List<dynamic>>());
      expect((decoded['files'] as List<dynamic>).length, 17);

      final firstFile =
          (decoded['files'] as List<dynamic>).first as Map<String, dynamic>;
      expect(firstFile['file'], isA<String>());
      expect(firstFile['coverage'], isA<num>());
      expect(firstFile['lines_found'], isA<int>());
      expect(firstFile['lines_hit'], isA<int>());

      verifyNever(() => console.write(any()));
      verifyNever(() => console.resetColorAttributes());
    },
  );

  test(
    'verify check coverage command exclude generated files with --exclude-generated flag',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_with_generated.info',
        '--exclude-generated',
        '--min-coverage',
        '100',
      ]);

      expect(exitCode, ExitCode.success.code);
      verify(() => console.write(any())).called(1);
      verify(() => console.writeLine(any(), any())).called(2);
      verify(() => console.resetColorAttributes()).called(1);
    },
  );

  test(
    'verify check coverage command JSON includes exclude_generated state',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_complete.info',
        '--json',
        '--exclude-generated',
      ]);

      expect(exitCode, ExitCode.success.code);
      final captured = verify(() => console.writeLine(captureAny(), any())).captured;
      final jsonOutput = captured.first as String;
      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;

      expect(decoded['exclude_generated'], isTrue);
      verifyNever(() => console.write(any()));
      verifyNever(() => console.resetColorAttributes());
    },
  );
}

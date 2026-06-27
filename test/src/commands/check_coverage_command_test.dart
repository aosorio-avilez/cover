import 'dart:convert';

import 'package:cover/src/commands/check_coverage_command.dart';
import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../mocks/console_mock.dart';

class MockCoverageService extends Mock implements CoverageService {}

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
      final captured =
          verify(() => console.writeLine(captureAny(), any())).captured;
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
      final captured =
          verify(() => console.writeLine(captureAny(), any())).captured;
      final jsonOutput = captured.first as String;
      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;

      expect(decoded['exclude_generated'], isTrue);
      verifyNever(() => console.write(any()));
      verifyNever(() => console.resetColorAttributes());
    },
  );

  test(
    'verify check coverage command shows uncovered lines with --show-uncovered flag',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info',
        '--show-uncovered',
      ]);

      expect(exitCode, ExitCode.fail.code);
      final captured = verify(() => console.write(captureAny())).captured;
      final table = captured.first as Table;
      expect(table.columns, 5);

      verify(() => console.writeLine(any(), any())).called(2);
      verify(() => console.resetColorAttributes()).called(1);
    },
  );

  test(
    'verify check coverage command JSON includes uncovered_lines in files',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info',
        '--json',
      ]);

      expect(exitCode, ExitCode.fail.code);
      final captured =
          verify(() => console.writeLine(captureAny(), any())).captured;
      final jsonOutput = captured.first as String;
      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;

      final files = List<Map<String, dynamic>>.from(decoded['files'] as List);
      final apiFile = files.firstWhere(
        (f) => f['file'] == 'lib/src/api/auth_api_impl.dart',
      );

      expect(apiFile['uncovered_lines'], containsAll([20, 22]));
      verifyNever(() => console.write(any()));
      verifyNever(() => console.resetColorAttributes());
    },
  );

  test(
      'verify check coverage command fails when coverage regresses from baseline',
      () async {
    final exitCode = await runner.run([
      'check',
      '--path',
      'test/stubs/lcov_incomplete.info', // 94.52%
      '--baseline',
      'test/stubs/lcov_complete.info', // 100%
      '--min-coverage',
      '0',
    ]);

    expect(exitCode, ExitCode.fail.code);
    verify(() => console.writeLine(any(), any()))
        .called(3); // min, baseline, current
  });

  test(
      'verify check coverage command succeeds when coverage is higher than baseline',
      () async {
    final exitCode = await runner.run([
      'check',
      '--path',
      'test/stubs/lcov_complete.info', // 100%
      '--baseline',
      'test/stubs/lcov_incomplete.info', // 94.52%
    ]);

    expect(exitCode, ExitCode.success.code);
  });

  test('verify check coverage command JSON includes baseline and delta',
      () async {
    final exitCode = await runner.run([
      'check',
      '--path',
      'test/stubs/lcov_incomplete.info', // 94.52%
      '--baseline',
      'test/stubs/lcov_complete.info', // 100%
      '--json',
    ]);

    expect(exitCode, ExitCode.fail.code);
    final captured =
        verify(() => console.writeLine(captureAny(), any())).captured;
    final jsonOutput = captured.first as String;
    final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;

    expect(decoded['baseline_coverage'], 100.0);
    expect(decoded['delta'], -5.48);
    expect(decoded['passed'], isFalse);
  });

  test('verify check coverage command catches ArgumentError gracefully',
      () async {
    final mockService = MockCoverageService();
    final customRunner =
        CoverCommandRunner(console: console, service: mockService);

    when(
      () => mockService.checkCoverage(
        filePath: any(named: 'filePath'),
        minCoverage: any(named: 'minCoverage'),
        excludePaths: any(named: 'excludePaths'),
        excludeGenerated: any(named: 'excludeGenerated'),
        baselinePath: any(named: 'baselinePath'),
      ),
    ).thenThrow(ArgumentError('Mock invalid argument'));

    final exitCode = await customRunner.run([
      'check',
      '--path',
      'test/stubs/lcov_complete.info',
    ]);

    expect(exitCode, ExitCode.usage.code);
    final captured =
        verify(() => console.writeErrorLine(captureAny())).captured;
    final message = captured.first as String;
    expect(message, contains('Mock invalid argument'));
  });

  test(
    'verify check coverage command filters table with --failures-only flag',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info',
        '--min-coverage',
        '90',
        '--failures-only',
      ]);

      expect(exitCode, ExitCode.success.code);
      final captured = verify(() => console.write(captureAny())).captured;
      final table = captured.first as Table;
      final tableString = table.toString();

      // Passing file (100% coverage >= 90%) must be filtered out
      expect(
        tableString,
        isNot(contains('lib/src/datasources/auth_data_source.dart')),
      );
      // Failing file (87.5% coverage < 90%) must be included
      expect(tableString, contains('lib/src/api/auth_api_impl.dart'));
    },
  );

  test(
    'verify check coverage command does not filter passing files when --failures-only is not set',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info',
        '--min-coverage',
        '90',
      ]);

      expect(exitCode, ExitCode.success.code);
      final captured = verify(() => console.write(captureAny())).captured;
      final table = captured.first as Table;
      final tableString = table.toString();

      // Both passing and failing files must be included
      expect(
        tableString,
        contains('lib/src/datasources/auth_data_source.dart'),
      );
      expect(tableString, contains('lib/src/api/auth_api_impl.dart'));
    },
  );

  test(
    'verify check coverage command JSON filters files with --failures-only flag',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info',
        '--min-coverage',
        '90',
        '--failures-only',
        '--json',
      ]);

      expect(exitCode, ExitCode.success.code);
      final captured =
          verify(() => console.writeLine(captureAny(), any())).captured;
      final jsonOutput = captured.first as String;
      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;

      expect(decoded['failures_only'], isTrue);
      final files = List<Map<String, dynamic>>.from(decoded['files'] as List);

      // Passing file (100% coverage >= 90%) must be filtered out
      final hasPassing = files.any(
        (f) => f['file'] == 'lib/src/datasources/auth_data_source.dart',
      );
      expect(hasPassing, isFalse);

      // Failing file (87.5% coverage < 90%) must be included
      final hasFailing = files.any(
        (f) => f['file'] == 'lib/src/api/auth_api_impl.dart',
      );
      expect(hasFailing, isTrue);
    },
  );

  group('file-min-coverage tests', () {
    test(
      'verify check coverage command fails when a file is below file-min-coverage',
      () async {
        final exitCode = await runner.run([
          'check',
          '--path',
          'test/stubs/lcov_incomplete.info', // overall 94.52%
          '--min-coverage',
          '90',
          '--file-min-coverage',
          '60', // forgot_password_page has 51.85%
        ]);

        expect(exitCode, ExitCode.fail.code);
        verify(() => console.writeLine(any(), any())).called(3); // min, min file, current
      },
    );

    test(
      'verify check coverage command succeeds when all files are above file-min-coverage',
      () async {
        final exitCode = await runner.run([
          'check',
          '--path',
          'test/stubs/lcov_incomplete.info', // overall 94.52%
          '--min-coverage',
          '90',
          '--file-min-coverage',
          '50', // lowest is forgot_password_page at 51.85%
        ]);

        expect(exitCode, ExitCode.success.code);
      },
    );

    test(
      'verify check coverage command returns usage error for invalid file-min-coverage',
      () async {
        final exitCode = await runner.run([
          'check',
          '--path',
          'test/stubs/lcov_complete.info',
          '--file-min-coverage',
          'invalid',
        ]);

        expect(exitCode, ExitCode.usage.code);
      },
    );

    test(
      'verify check coverage command returns usage error for out-of-range file-min-coverage',
      () async {
        final exitCode = await runner.run([
          'check',
          '--path',
          'test/stubs/lcov_complete.info',
          '--file-min-coverage',
          '105',
        ]);

        expect(exitCode, ExitCode.usage.code);
      },
    );

    test(
      'verify check coverage command returns usage error for negative file-min-coverage',
      () async {
        final exitCode = await runner.run([
          'check',
          '--path',
          'test/stubs/lcov_complete.info',
          '--file-min-coverage',
          '-5',
        ]);

        expect(exitCode, ExitCode.usage.code);
      },
    );

    test(
      'verify check coverage command returns usage error for NaN file-min-coverage',
      () async {
        final exitCode = await runner.run([
          'check',
          '--path',
          'test/stubs/lcov_complete.info',
          '--file-min-coverage',
          'NaN',
        ]);

        expect(exitCode, ExitCode.usage.code);
      },
    );

    test(
      'verify check coverage command JSON includes file_min_coverage state',
      () async {
        final exitCode = await runner.run([
          'check',
          '--path',
          'test/stubs/lcov_incomplete.info',
          '--json',
          '--min-coverage',
          '90',
          '--file-min-coverage',
          '50',
        ]);

        expect(exitCode, ExitCode.success.code);
        final captured =
            verify(() => console.writeLine(captureAny(), any())).captured;
        final jsonOutput = captured.first as String;
        final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;

        expect(decoded['file_min_coverage'], 50.0);
        expect(decoded['passed'], isTrue);
      },
    );

    test(
      'verify check coverage command JSON fails passed state when below file_min_coverage',
      () async {
        final exitCode = await runner.run([
          'check',
          '--path',
          'test/stubs/lcov_incomplete.info',
          '--json',
          '--min-coverage',
          '90',
          '--file-min-coverage',
          '60',
        ]);

        expect(exitCode, ExitCode.fail.code);
        final captured =
            verify(() => console.writeLine(captureAny(), any())).captured;
        final jsonOutput = captured.first as String;
        final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;

        expect(decoded['file_min_coverage'], 60.0);
        expect(decoded['passed'], isFalse);
      },
    );
  });
}

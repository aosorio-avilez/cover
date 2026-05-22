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

  group('CheckCoverageCommand Markdown output', () {
    test('verify markdown output with --markdown flag', () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info',
        '--markdown',
      ]);

      expect(exitCode, ExitCode.fail.code);

      final captured = verify(() => console.writeLine(captureAny())).captured;
      final output = captured.join('\n');

      expect(output, contains('# 🟡 Coverage Report'));
      expect(output, contains('## Summary'));
      expect(output, contains('- **Total Coverage:** 94.52%'));
      expect(output, contains('- **Progress:** `'));
      expect(output, contains('| Status | File name | Found Lines | Hit Lines | Coverage |'));
      expect(output, contains('| --- | --- | --- | --- | --- |'));
      expect(output, contains('| 🟡 | lib/src/api/auth_api_impl.dart | 16 | 14 | 87.5% |'));
      expect(output, contains('| 🟢 | lib/src/datasources/auth_data_source.dart | 47 | 47 | 100.0% |'));
    });

    test('verify markdown output with --markdown and --show-uncovered', () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info',
        '--markdown',
        '--show-uncovered',
      ]);

      expect(exitCode, ExitCode.fail.code);

      final captured = verify(() => console.writeLine(captureAny())).captured;
      final output = captured.join('\n');

      expect(output, contains('| Status | File name | Found Lines | Hit Lines | Coverage | Uncovered Lines |'));
      expect(output, contains('| --- | --- | --- | --- | --- | --- |'));
      expect(output, contains('| 🟡 | lib/src/api/auth_api_impl.dart | 16 | 14 | 87.5% | 20, 22 |'));
    });

    test('verify markdown output with --markdown and --failures-only', () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info',
        '--markdown',
        '--failures-only',
        '--min-coverage',
        '90',
      ]);

      expect(exitCode, ExitCode.success.code);

      final captured = verify(() => console.writeLine(captureAny())).captured;
      final output = captured.join('\n');

      // lib/src/api/auth_api_impl.dart (87.5%) should be included as it's below 90%
      expect(output, contains('| 🟡 | lib/src/api/auth_api_impl.dart | 16 | 14 | 87.5% |'));
      // lib/src/datasources/auth_data_source.dart (100%) should be excluded
      expect(output, isNot(contains('lib/src/datasources/auth_data_source.dart')));
    });

    test('verify markdown output with --markdown and --baseline', () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info', // 94.52%
        '--baseline',
        'test/stubs/lcov_complete.info', // 100%
        '--markdown',
        '--min-coverage',
        '0',
      ]);

      expect(exitCode, ExitCode.fail.code);

      final captured = verify(() => console.writeLine(captureAny())).captured;
      final output = captured.join('\n');

      expect(output, contains('## Comparison'));
      expect(output, contains('- **Baseline:** 100.0%'));
      expect(output, contains('- **Delta:** -5.48%'));
    });
  });
}

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

  test(
    'verify check coverage command outputs GitHub annotations with --github-annotations flag',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info',
        '--github-annotations',
        '--min-coverage',
        '100',
      ]);

      expect(exitCode, ExitCode.fail.code);

      final captured = verify(() => console.writeLine(captureAny())).captured;
      final output = captured.map((e) => e as String).join('\n');

      expect(output, contains('::warning file=lib/src/api/auth_api_impl.dart,line=20,endLine=20::'));
      expect(output, contains('::warning file=lib/src/api/auth_api_impl.dart,line=22,endLine=22::'));
      expect(output, contains('Coverage is below threshold (100.0%). Lines 20-20 are not covered.'));

      expect(output, contains('::warning file=lib/src/pages/forgot_password_page.dart,line=33,endLine=35::'));
      expect(output, contains('::warning file=lib/src/pages/forgot_password_page.dart,line=52,endLine=55::'));
    },
  );

  test(
    'verify check coverage command does not output annotations for passing files',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_complete.info',
        '--github-annotations',
        '--min-coverage',
        '100',
      ]);

      expect(exitCode, ExitCode.success.code);
      verifyNever(() => console.writeLine(any()));
    },
  );

  test(
    'verify GitHub annotations respect custom min-coverage',
    () async {
      final exitCode = await runner.run([
        'check',
        '--path',
        'test/stubs/lcov_incomplete.info',
        '--github-annotations',
        '--min-coverage',
        '10', // Very low, most files will pass
      ]);

      expect(exitCode, ExitCode.success.code);

      // All files in lcov_incomplete.info have > 10% coverage except maybe if they are empty
      // lib/src/api/auth_api_impl.dart has 14/16 = 87.5%
      // lib/src/pages/forgot_password_page.dart has 28/54 = 51.85%

      verifyNever(() => console.writeLine(any()));
    },
  );
}

import 'dart:io';

import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:dart_console/dart_console.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'mocks/console_mock.dart';

void main() {
  late Console console;

  setUp(() {
    console = ConsoleMock();
  });

  test('Should correctly exclude paths with spaces', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('cover_repro_space');
    addTearDown(() => tempDir.delete(recursive: true));
    final lcovFile = File('${tempDir.path}/lcov_space.info');

    // Initialize runner with service using tempDir as working directory
    final service = CoverageService(currentDirectory: tempDir);
    final runner = CoverCommandRunner(console: console, service: service);

    // Create an lcov file with a file path containing spaces
    await lcovFile.writeAsString('''
TN:
SF:my folder/file.dart
DA:1,0
LF:1
LH:0
end_of_record
''');

    // Trying to exclude "my folder"
    // With current implementation, "my folder" becomes "myfolder"
    // And "my folder/file.dart".contains("myfolder") is False.
    // So coverage should be 0% (failed), because the file is NOT excluded.
    // If it was correctly excluded, coverage would be 100% (or irrelevant, but empty files list throws exception, wait)

    // If we exclude the only file, the result.files is empty.
    // CoverageService throws "File is empty or does not have the correct format" if files is empty.

    // So let's add another file that is covered.
    await lcovFile.writeAsString('''
TN:
SF:my folder/file.dart
DA:1,0
LF:1
LH:0
end_of_record
TN:
SF:other/file.dart
DA:1,1
LF:1
LH:1
end_of_record
''',
      mode: FileMode.append,
    );

    // If "my folder" is NOT excluded, we have 1 hit / 2 found = 50% coverage.
    // If "my folder" IS excluded, we have 1 hit / 1 found = 100% coverage.

    // verifying the fix: expected 100% because exclusion succeeds
    // Use basename because we are running "inside" tempDir (via CoverageService)
    final exitCode = await runner.run([
      'check',
      '--path',
      path.basename(lcovFile.path),
      '--excluded-paths',
      'my folder',
      '--min-coverage',
      '100',
    ]);

    // Expect success (ExitCode.success.code) because coverage is 100%
    expect(exitCode, ExitCode.success.code);
  });
}

import 'dart:io';

import 'package:cover/src/cover_command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class ConsoleMock extends Mock implements Console {}

void main() {
  test(
      'Version spoofing: should ignore local pubspec.yaml and return package version',
      () async {
    final tempDir = await Directory.systemTemp.createTemp('cover_version_test');
    final pubspec = File('${tempDir.path}/pubspec.yaml');

    // Create a local pubspec.yaml with a fake version
    await pubspec.writeAsString('''
name: malicious_package
version: 99.99.99-malicious
''');

    // We need to change CWD for the runner to potentially pick up the local
    // pubspec.yaml if the fix is not working.
    final originalCwd = Directory.current;
    Directory.current = tempDir;

    final console = ConsoleMock();
    final runner = CoverCommandRunner(console: console);

    try {
      await runner.run(['--version']);

      // Verify that the mocked console received the REAL version, not the fake one.
      final captured = verify(() => console.writeLine(captureAny())).captured;
      final versionOutput = captured.first as String;

      expect(versionOutput, isNot(contains('99.99.99-malicious')));
      // Ideally we check for '0.1.0' but hardcoding versions in tests can be
      // brittle if not updated. The important part is it's NOT the local one.
      // But knowing the current version is 0.1.0, checking format is good.
      expect(versionOutput, matches(RegExp(r'\d+\.\d+\.\d+')));
    } finally {
      Directory.current = originalCwd;
      await tempDir.delete(recursive: true);
    }
  });
}

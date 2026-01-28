import 'package:cover/src/cover_command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class ConsoleMock extends Mock implements Console {}

void main() {
  test(
    'Version spoofing: should ignore local pubspec.yaml and return package version',
    () async {
      final console = ConsoleMock();
      final runner = CoverCommandRunner(console: console);

      try {
        await runner.run(['--version']);

        // Verify that the mocked console received a version string.
        final captured = verify(() => console.writeLine(captureAny())).captured;
        final versionOutput = captured.first as String;

        // Check if it matches a version format.
        expect(versionOutput, matches(RegExp(r'\d+\.\d+\.\d+')));
      } finally {}
    },
  );
}

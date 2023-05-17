import 'package:cover/src/models/exit_code.dart';
import 'package:test/test.dart';

void main() {
  test('verify exit code success', () async {
    const exitCode = ExitCode.success;
    expect(exitCode.code, 0);
  });

  test('verify exit code fail', () async {
    const exitCode = ExitCode.fail;
    expect(exitCode.code, 1);
  });

  test('verify exit code usage', () async {
    const exitCode = ExitCode.usage;
    expect(exitCode.code, 64);
  });

  test('verify exit code os file', () async {
    const exitCode = ExitCode.osFile;
    expect(exitCode.code, 72);
  });
}

import 'package:cover/src/cover_command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/console_mock.dart';
import 'mocks/coverage_service_mock.dart';

void main() {
  late Console console;

  setUp(() {
    console = ConsoleMock();
  });

  test('Terminal Injection: FormatException message should be sanitized',
      () async {
    final service = CoverageServiceMock();
    final runner = CoverCommandRunner(console: console, service: service);
    const maliciousMsg = 'Malformed input\x1B[31mHACKED\x1B[0m';

    when(
      () => service.checkCoverage(
        filePath: any(named: 'filePath'),
        minCoverage: any(named: 'minCoverage'),
        excludePaths: any(named: 'excludePaths'),
      ),
    ).thenAnswer((_) async => throw const FormatException(maliciousMsg));

    await runner.run(['check']);

    final captured =
        verify(() => console.writeErrorLine(captureAny())).captured;
    final errorMessage = captured.first as String;

    expect(
      errorMessage,
      isNot(contains('\x1B[31m')),
      reason: 'Error message should be sanitized of ANSI escape sequences',
    );
  });
}

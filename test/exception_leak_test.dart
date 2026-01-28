import 'dart:io';

import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mocks/console_mock.dart';

class MockCoverageService extends Mock implements CoverageService {}

void main() {
  late Console console;
  late CoverCommandRunner runner;
  late CoverageService service;

  setUp(() {
    console = ConsoleMock();
    service = MockCoverageService();
    runner = CoverCommandRunner(console: console, service: service);
  });

  test('Exception Leakage: should catch FileSystemException and exit gracefully',
      () async {
    // Arrange
    when(() => service.checkCoverage(
          filePath: any(named: 'filePath'),
          minCoverage: any(named: 'minCoverage'),
          excludePaths: any(named: 'excludePaths'),
        )).thenThrow(
      const FileSystemException('Access denied', 'coverage/lcov.info'),
    );

    // Act
    // If not caught, this will throw and fail the test
    final exitCode = await runner.run(['check']);

    // Assert
    expect(exitCode, ExitCode.osFile.code);
    verify(() => console.writeErrorLine(any(that: contains('Access denied'))))
        .called(1);
  });
}

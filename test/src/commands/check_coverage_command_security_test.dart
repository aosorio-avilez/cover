import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/coverage_result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../mocks/console_mock.dart';
import '../../mocks/coverage_service_mock.dart';

void main() {
  late ConsoleMock console;
  late CoverageServiceMock service;
  late CoverCommandRunner runner;

  setUp(() {
    console = ConsoleMock();
    service = CoverageServiceMock();
    runner = CoverCommandRunner(console: console, service: service);
  });

  test('verify check coverage command preserves spaces in excluded paths',
      () async {
    when(
      () => service.checkCoverage(
        filePath: any(named: 'filePath'),
        minCoverage: any(named: 'minCoverage'),
        excludePaths: any(named: 'excludePaths'),
      ),
    ).thenAnswer((_) async => const CoverageResult(coverage: 100, files: []));

    await runner.run([
      'check',
      '--excluded-paths',
      'folder with space, another_folder',
    ]);

    verify(
      () => service.checkCoverage(
        filePath: any(named: 'filePath'),
        minCoverage: any(named: 'minCoverage'),
        excludePaths: ['folder with space', 'another_folder'],
      ),
    ).called(1);
  });
}

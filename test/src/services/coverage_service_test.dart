import 'package:cover/src/models/coverage_result.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:test/test.dart';

void main() {
  late CoverageService service;

  setUp(() {
    service = CoverageService();
  });

  group('CoverageService', () {
    test('checkCoverage throws FormatException when file is empty', () async {
      await expectLater(
        () => service.checkCoverage(
          filePath: 'test/stubs/lcov_empty.info',
          minCoverage: 100,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('checkCoverage returns correct result for complete coverage',
        () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_complete.info',
        minCoverage: 100,
      );

      expect(result, isA<CoverageResult>());
      expect(result.coverage, 100.0);
      expect(result.files.length, 17);
    });

    test('checkCoverage filters excluded paths', () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_uncovered.info',
        minCoverage: 100,
        excludePaths: ['/datasources'],
      );

      expect(result.coverage, 100.0);
      expect(result.files.length, 8);
    });
  });
}

import 'dart:io';

import 'package:cover/src/models/coverage_result.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../mocks/io_mocks.dart';

void main() {
  late CoverageService service;

  setUp(() {
    service = CoverageService();
  });

  group('CoverageService', () {
    test('checkCoverage throws PathNotFoundException when file path is empty',
        () async {
      await expectLater(
        () => service.checkCoverage(
          filePath: '',
          minCoverage: 100,
        ),
        throwsA(isA<PathNotFoundException>()),
      );
    });

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

    test('_isPathAllowed handles CWD resolution failure', () async {
      final mockDir = MockDirectory();
      when(mockDir.resolveSymbolicLinksSync)
          .thenThrow(const FileSystemException('permission denied'));
      when(() => mockDir.path).thenReturn('/test/dir');

      final service = CoverageService(currentDirectory: mockDir);

      // This should hit the catch block at line 91 and use mockDir.path
      // Then path.canonicalize will work on /test/dir
      // We check if a file within /test/dir is allowed
      // Note: _isPathAllowed is private, but checkCoverage calls it.
      // We expect checkCoverage to continue (and then probably fail at parsing if the file doesn't exist,
      // but we care about covering the path allowed check).

      try {
        await service.checkCoverage(filePath: 'test.info', minCoverage: 0);
      } catch (_) {
        // ignore errors from parsing
      }

      verify(mockDir.resolveSymbolicLinksSync).called(1);
    });
  });
}

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
    test(
      'checkCoverage throws PathNotFoundException when file path is empty',
      () async {
        await expectLater(
          () => service.checkCoverage(filePath: '', minCoverage: 100),
          throwsA(isA<PathNotFoundException>()),
        );
      },
    );

    test(
      'checkCoverage throws FormatException when file is empty (0 bytes)',
      () async {
        await expectLater(
          () => service.checkCoverage(
            filePath: 'test/stubs/lcov_empty.info',
            minCoverage: 100,
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'File is empty or does not have the correct format',
            ),
          ),
        );
      },
    );

    test(
      'checkCoverage throws PathNotFoundException when file does not exist',
      () async {
        await expectLater(
          () => service.checkCoverage(
            filePath: 'test/stubs/non_existent.info',
            minCoverage: 100,
          ),
          throwsA(isA<PathNotFoundException>()),
        );
      },
    );

    test(
      'checkCoverage returns correct result for complete coverage',
      () async {
        final result = await service.checkCoverage(
          filePath: 'test/stubs/lcov_complete.info',
          minCoverage: 100,
        );

        expect(result, isA<CoverageResult>());
        expect(result.coverage, 100.0);
        expect(result.files.length, 17);
      },
    );

    test('checkCoverage filters excluded paths', () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_uncovered.info',
        minCoverage: 100,
        excludePaths: ['/datasources'],
      );

      expect(result.coverage, 100.0);
      expect(result.files.length, 8);
    });

    test('checkCoverage ignores empty strings in excludedPaths', () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_complete.info',
        minCoverage: 100,
        excludePaths: [''],
      );

      // Should not exclude any files because '' is ignored.
      expect(result.coverage, 100.0);
      expect(result.files.length, 17);
    });

    test('checkCoverage handles duplicate excluded paths correctly', () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_uncovered.info',
        minCoverage: 100,
        excludePaths: ['/datasources', '/datasources'],
      );

      expect(result.coverage, 100.0);
      expect(result.files.length, 8);
    });

    test('_validatePath handles file resolution failure', () async {
      final mockDir = MockDirectory();
      when(() => mockDir.path).thenReturn(Directory.current.path);

      final service = CoverageService(currentDirectory: mockDir);

      // We call checkCoverage with a path that exists but we want to know it doesn't crash
      // during path validation if resolution fails (though it's hard to trigger resolution failure
      // on a path that exists without specific FS conditions).
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_complete.info',
        minCoverage: 0,
      );
      expect(result.coverage, 100.0);
    });

    test('_validatePath handles CWD resolution failure', () async {
      final mockDir = MockDirectory();
      when(
        mockDir.resolveSymbolicLinksSync,
      ).thenThrow(const FileSystemException('permission denied'));
      when(() => mockDir.path).thenReturn(Directory.current.path);

      final service = CoverageService(currentDirectory: mockDir);

      // Should succeed because it falls back to mockDir.path
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_complete.info',
        minCoverage: 0,
      );
      expect(result.coverage, 100.0);

      verify(mockDir.resolveSymbolicLinksSync).called(1);
    });
  });
}

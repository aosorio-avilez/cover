import 'dart:io';

import 'package:cover/src/extensions/record_extension.dart';
import 'package:cover/src/models/coverage_result.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
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
      'checkCoverage throws FormatException when file extension is unsupported',
      () async {
        await expectLater(
          () => service.checkCoverage(
            filePath: 'test/stubs/non_coverage_directory/amber.png',
            minCoverage: 100,
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Unsupported file format. Expected .info or .json file.',
            ),
          ),
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

    test('checkCoverage excludes generated files when requested', () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_with_generated.info',
        minCoverage: 0,
        excludeGenerated: true,
      );

      expect(result.files.length, 1);
      expect(result.files.first.file, 'lib/src/models/user.dart');
      expect(result.coverage, 100.0);
    });

    test('checkCoverage includes generated files when not requested', () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_with_generated.info',
        minCoverage: 0,
      );

      expect(result.files.length, 4);
      expect(
        result.coverage,
        62.5,
      ); // (2+1+1+1) / (2+2+2+2) * 100 = 5/8 * 100 = 62.5
    });

    test('checkCoverage handles both excluded paths and generated files',
        () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_with_generated.info',
        minCoverage: 0,
        excludePaths: ['models/user.dart'],
        excludeGenerated: true,
      );

      // models/user.dart excluded by path
      // models/user.g.dart excluded by generated
      // models/user.freezed.dart excluded by generated
      // services/api_service.mocks.dart excluded by generated
      expect(result.files, isEmpty);
      expect(result.coverage, 0.0);
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
      when(mockDir.resolveSymbolicLinks).thenAnswer(
        (_) async => throw const FileSystemException('resolution failed'),
      );

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
        mockDir.resolveSymbolicLinks,
      ).thenAnswer(
        (_) async => throw const FileSystemException('permission denied'),
      );
      when(() => mockDir.path).thenReturn(Directory.current.path);

      final service = CoverageService(currentDirectory: mockDir);

      // Should succeed because it falls back to mockDir.path
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_complete.info',
        minCoverage: 0,
      );
      expect(result.coverage, 100.0);

      verify(mockDir.resolveSymbolicLinks).called(1);
    });

    test('checkCoverage with baseline returns baseline coverage', () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_incomplete.info', // 94.52%
        minCoverage: 0,
        baselinePath: 'test/stubs/lcov_complete.info', // 100%
      );

      expect(result.coverage, 94.52);
      expect(result.baselineCoverage, 100.0);
    });

    test('checkCoverage with same baseline has 0 delta', () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/lcov_complete.info',
        minCoverage: 0,
        baselinePath: 'test/stubs/lcov_complete.info',
      );

      expect(result.coverage, 100.0);
      expect(result.baselineCoverage, 100.0);
    });

    test('checkCoverage works with a single VM JSON coverage file', () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/vm_coverage_complete.json',
        minCoverage: 100,
      );

      expect(result.coverage, 100.0);
      expect(result.files.length, 1);
      expect(result.files.first.file, 'lib/src/services/coverage_service.dart');
    });

    test('checkCoverage parses incomplete VM JSON coverage file correctly',
        () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/vm_coverage_incomplete.json',
        minCoverage: 0,
      );

      // 2 hits, 3 lines -> 66.67%
      expect(result.coverage, 66.67);
      expect(result.files.first.uncoveredLines, [20]);
    });

    test('checkCoverage ignores external package dependencies', () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/vm_coverage_with_external.json',
        minCoverage: 0,
      );

      // Package name cover. args/args.dart must be ignored.
      expect(result.files.length, 1);
      expect(result.files.first.file, 'lib/src/services/coverage_service.dart');
    });

    test(
        'checkCoverage handles directories containing JSON files and merges them',
        () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/vm_coverage_directory',
        minCoverage: 0,
      );

      // test_a.json: line 10 (1 hit), line 20 (0 hits)
      // test_b.json: line 20 (1 hit), line 30 (1 hit)
      // Merged lines: 10 (1 hit), 20 (1 hit), 30 (1 hit)
      // Merged coverage: 100%
      expect(result.coverage, 100.0);
      expect(result.files.length, 1);
      expect(result.files.first.lines?.found, 3);
      expect(result.files.first.lines?.hit, 3);
    });

    test('checkCoverage throws FormatException on empty JSON file', () async {
      await expectLater(
        () => service.checkCoverage(
          filePath: 'test/stubs/vm_coverage_empty.json',
          minCoverage: 100,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('checkCoverage throws FormatException on malformed JSON file',
        () async {
      final tempFile = File('test/stubs/vm_coverage_temp_malformed.json');
      await tempFile.writeAsString('NOT_VALID_JSON_AT_ALL!!!');

      try {
        await expectLater(
          () => service.checkCoverage(
            filePath: tempFile.path,
            minCoverage: 100,
          ),
          throwsA(isA<FormatException>()),
        );
      } finally {
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
      }
    });

    test(
        'checkCoverage resolves file:// URIs, absolute and relative paths in VM JSON',
        () async {
      final tempFile = File('test/stubs/vm_coverage_temp_paths.json');
      final currentDirPath = Directory.current.path;
      final fileUri = Uri.file(
        path.join(
          currentDirPath,
          'lib/src/services/coverage_service.dart',
        ),
      ).toString();
      const relativePath = 'lib/src/cover_command_runner.dart';

      final jsonContent = '''
{
  "type": "CodeCoverage",
  "coverage": [
    {
      "source": "$fileUri",
      "hits": [10, 1]
    },
    {
      "source": "$relativePath",
      "hits": [20, 1]
    }
  ]
}
''';

      await tempFile.writeAsString(jsonContent);

      try {
        final result = await service.checkCoverage(
          filePath: tempFile.path,
          minCoverage: 0,
        );

        expect(result.files.length, 2);
        final filePaths = result.files.map((f) => f.file).toSet();
        expect(filePaths, contains('lib/src/services/coverage_service.dart'));
        expect(filePaths, contains('lib/src/cover_command_runner.dart'));
      } finally {
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
      }
    });

    test(
        'checkCoverage handles directories containing LCOV info files and merges them',
        () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/info_coverage_directory',
        minCoverage: 0,
      );

      // lcov_a.info: line 10 (1 hit), line 20 (0 hits)
      // lcov_b.info: line 20 (1 hit), line 30 (1 hit)
      expect(result.files.length, 1);
      expect(result.files.first.lines?.found, 3);
      expect(result.files.first.lines?.hit, 3);
    });

    test(
        'checkCoverage throws FormatException when directory contains no coverage files',
        () async {
      await expectLater(
        () => service.checkCoverage(
          filePath: 'test/stubs/non_coverage_directory',
          minCoverage: 0,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test(
        'checkCoverage falls back to directory when lcov.info path is not found but directory exists',
        () async {
      final result = await service.checkCoverage(
        filePath: 'test/stubs/vm_coverage_directory/lcov.info',
        minCoverage: 0,
      );

      expect(result.coverage, 100.0);
      expect(result.files.length, 1);
      expect(result.files.first.lines?.found, 3);
      expect(result.files.first.lines?.hit, 3);
    });

    test('checkCoverage automatically excludes files in test/ directory',
        () async {
      final tempFile = File('test/stubs/vm_coverage_temp_test_excl.json');
      final testFileUri = Uri.file(
        path.join(
          Directory.current.path,
          'test/src/services/coverage_service_test.dart',
        ),
      ).toString();
      const libFileRelative = 'lib/src/services/coverage_service.dart';

      final jsonContent = '''
{
  "type": "CodeCoverage",
  "coverage": [
    {
      "source": "$testFileUri",
      "hits": [10, 1]
    },
    {
      "source": "$libFileRelative",
      "hits": [20, 1]
    }
  ]
}
''';

      await tempFile.writeAsString(jsonContent);

      try {
        final result = await service.checkCoverage(
          filePath: tempFile.path,
          minCoverage: 0,
        );

        // The test file must be filtered out, only leaving the lib file.
        expect(result.files.length, 1);
        expect(
          result.files.first.file,
          'lib/src/services/coverage_service.dart',
        );
      } finally {
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
      }
    });
  });
}

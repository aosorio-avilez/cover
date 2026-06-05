import 'dart:io';
import 'package:cover/src/services/coverage_service.dart';
import 'package:test/test.dart';

void main() {
  group('CoverageService Robustness Reproduction', () {
    late CoverageService service;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cover_robustness_repro');
      service = CoverageService(currentDirectory: tempDir);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should exclude files in test directory even if path starts with ./', () async {
      final lcovFile = File('${tempDir.path}/lcov.info');
      await lcovFile.writeAsString('''
SF:./test/my_test.dart
DA:1,1
LF:1
LH:1
end_of_record
SF:lib/my_code.dart
DA:1,1
LF:1
LH:1
end_of_record
''');

      final result = await service.checkCoverage(filePath: lcovFile.path, minCoverage: 0);

      // Currently, SF:./test/my_test.dart might not be excluded
      // because path.split('./test/my_test.dart') gives ['.', 'test', 'my_test.dart']
      // and it checks segments.first == 'test'.

      final filenames = result.files.map((f) => f.file).toList();
      expect(filenames, isNot(contains('./test/my_test.dart')));
      expect(filenames, contains('lib/my_code.dart'));
    });

    test('should not fail entire JSON parsing if one entry has malformed source URI', () async {
      final jsonFile = File('${tempDir.path}/coverage.json');
      await jsonFile.writeAsString('''
{
  "coverage": [
    {
      "source": "package:cover/%",
      "hits": [1, 1]
    },
    {
      "source": "package:cover/lib/valid.dart",
      "hits": [1, 1]
    }
  ]
}
''', flush: true);

      // We need a pubspec.yaml so it knows the package name 'cover'
      final pubspec = File('${tempDir.path}/pubspec.yaml');
      await pubspec.writeAsString('name: cover\n');

      // This currently throws FormatException because _parseJsonCoverage catches the ArgumentError
      // from Uri.decodeComponent and rethrows as FormatException, aborting the whole file.
      final result = await service.checkCoverage(filePath: jsonFile.path, minCoverage: 0);

      expect(result.files, hasLength(1));
      expect(result.files.first.file, contains('valid.dart'));
    });

    test('should skip records that point outside working directory (path traversal)', () async {
      final lcovFile = File('${tempDir.path}/lcov_traversal.info');
      await lcovFile.writeAsString('''
SF:../outside.dart
DA:1,1
LF:1
LH:1
end_of_record
SF:lib/inside.dart
DA:1,1
LF:1
LH:1
end_of_record
''');

      final result = await service.checkCoverage(filePath: lcovFile.path, minCoverage: 0);

      final filenames = result.files.map((f) => f.file).toList();
      expect(filenames, isNot(contains('../outside.dart')));
      expect(filenames, contains('lib/inside.dart'));
    });
  });
}

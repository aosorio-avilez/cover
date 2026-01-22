import 'dart:io';

import 'package:cover/src/services/coverage_service.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Security', () {
    test(
        '''Path Traversal: should throw when accessing file outside working directory''',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('cover_security_outside');
      final outsideFile = File('${tempDir.path}/outside.info');
      await outsideFile
          .writeAsString('TN:\nSF:/path/to/file\nDA:1,1\nend_of_record');

      final innerTemp =
          await Directory.systemTemp.createTemp('cover_security_inner');

      final service = CoverageService(currentDirectory: innerTemp);

      try {
        await expectLater(
          service.checkCoverage(filePath: outsideFile.path, minCoverage: 0),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains(
                'File path must be within the current working directory.',
              ),
            ),
          ),
        );
      } finally {
        await tempDir.delete(recursive: true);
        await innerTemp.delete(recursive: true);
      }
    });

    test('Path Traversal: should allow accessing file within working directory',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('cover_security_inside');
      final insideFile = File('${tempDir.path}/coverage_inside.info');

      try {
        await insideFile.writeAsString(
          'TN:\nSF:/path/to/file\nDA:1,1\nLF:1\nLH:1\nend_of_record',
        );

        final service = CoverageService(currentDirectory: tempDir);
        final result = await service.checkCoverage(
          filePath: path.basename(insideFile.path),
          minCoverage: 0,
        );
        expect(result.coverage, 100.0);
      } finally {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test(
        'Path Traversal: should throw when accessing symlink pointing outside '
        'working directory', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('cover_security_symlink');
      final targetFile = File('${tempDir.path}/lcov.info')
        ..writeAsStringSync('TN:\nSF:file.dart\nDA:1,1\nend_of_record\n');

      final testDir =
          await Directory.systemTemp.createTemp('cover_security_test_dir');
      final linkPath = path.join(testDir.path, 'link_to_outside.info');
      final link = Link(linkPath);

      try {
        await link.create(targetFile.path);

        final service = CoverageService(currentDirectory: testDir);

        await expectLater(
          service.checkCoverage(
            filePath: path.basename(linkPath),
            minCoverage: 0,
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains(
                'File path must be within the current working directory.',
              ),
            ),
          ),
        );
      } finally {
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
        if (testDir.existsSync()) await testDir.delete(recursive: true);
      }
    });

    test(
        'Path Traversal: should allow accessing symlink pointing WITHIN working '
        'directory', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('cover_security_symlink_inner');
      final realFile = File('${tempDir.path}/real.info');
      await realFile.writeAsString(
        'TN:\nSF:/path/to/file\nDA:1,1\nLF:1\nLH:1\nend_of_record',
      );

      final linkPath = path.join(tempDir.path, 'link.info');
      // Create a relative link
      await Link(linkPath).create('real.info');

      final service = CoverageService(currentDirectory: tempDir);

      try {
        final result = await service.checkCoverage(
          filePath: 'link.info',
          minCoverage: 0,
        );
        expect(result.coverage, 100.0);
      } finally {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}

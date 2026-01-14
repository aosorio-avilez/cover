import 'dart:io';
import 'package:cover/src/services/coverage_service.dart';
import 'package:test/test.dart';

void main() {
  group('Security', () {
    test('Path Traversal: should throw when accessing file outside working directory', () async {
      final tempDir = await Directory.systemTemp.createTemp('cover_security_test');
      final outsideFile = File('${tempDir.path}/outside.info');
      await outsideFile.writeAsString('TN:\nSF:/path/to/file\nDA:1,1\nend_of_record');

      final service = CoverageService();

      try {
        await expectLater(
          service.checkCoverage(filePath: outsideFile.path, minCoverage: 0),
          throwsA(isA<Exception>()),
          reason: 'Should throw exception when accessing file outside CWD'
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('Path Traversal: should allow accessing file within working directory', () async {
      final insideFile = File('coverage_inside.info');
      await insideFile.writeAsString('TN:\nSF:/path/to/file\nDA:1,1\nLF:1\nLH:1\nend_of_record');

      final service = CoverageService();

      try {
        final result = await service.checkCoverage(filePath: insideFile.path, minCoverage: 0);
        expect(result.coverage, 100.0);
      } finally {
        if (await insideFile.exists()) {
          await insideFile.delete();
        }
      }
    });
  });
}

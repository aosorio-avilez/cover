
import 'dart:io';
import 'package:cover/src/services/coverage_service.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Security Path Traversal', () {
    late Directory tempDir;
    late Directory outsideDir;
    late File secretFile;
    late Link symlink;
    late CoverageService coverageService;

    setUp(() async {
      // Create a temporary directory for the test environment
      tempDir = await Directory.systemTemp.createTemp('cover_test_env');

      // Create a directory "outside" the "current working directory"
      outsideDir = await Directory(path.join(tempDir.path, 'outside')).create();

      // Create a secret file in the outside directory
      secretFile = File(path.join(outsideDir.path, 'secret.info'));
      await secretFile.writeAsString('''
SF:lib/secret.dart
DA:1,1
LF:1
LH:1
end_of_record
''');

      // Create a "current working directory"
      final cwd = await Directory(path.join(tempDir.path, 'cwd')).create();

      // Create a symlink in the "current working directory" pointing to the secret file
      symlink = Link(path.join(cwd.path, 'innocent.info'));
      await symlink.create(secretFile.path);

      // Change directory to the simulated CWD
      Directory.current = cwd;

      coverageService = CoverageService();
    });

    tearDown(() {
       if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('should NOT allow accessing file outside working directory via symlink', () async {
      expect(
        () async => await coverageService.checkCoverage(
          filePath: 'innocent.info',
          minCoverage: 0,
        ),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('File path must be within the current working directory'),
        )),
      );
    });
  });
}

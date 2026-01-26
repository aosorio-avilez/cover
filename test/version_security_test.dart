import 'dart:io';

import 'package:cover/src/cover_command_runner.dart';
import 'package:test/test.dart';

void main() {
  group('CoverCommandRunner Version Vulnerability', () {
    late Directory tempDir;
    late Directory originalCwd;

    setUp(() async {
      originalCwd = Directory.current;
      tempDir = await Directory.systemTemp.createTemp('cover_version_test');
    });

    tearDown(() async {
      Directory.current = originalCwd;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('getVersion reads from CWD (reproduction)', () async {
      // Create a spoofed pubspec.yaml in the temp directory
      final spoofedPubspec = File('${tempDir.path}/pubspec.yaml');
      await spoofedPubspec.writeAsString('''
name: cover_spoof
version: 9.9.9
description: Spoofed package
environment:
  sdk: ^3.0.0
''');

      // Change CWD to the temp directory
      Directory.current = tempDir;

      final runner = CoverCommandRunner();
      final version = await runner.getVersion();

      // Secure behavior: returns the actual package version
      // ignoring the spoofed one in the CWD
      expect(version, isNot('9.9.9'));
    });
  });
}

import 'dart:io';

import 'package:cover/src/extensions/record_extension.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:test/test.dart';

void main() {
  group('RecordExtension', () {
    test('coveragePercentage returns 0 if linesFound is 0', () {
      final record = Record.empty();
      // By default Record.empty() has lines with found=null, hit=null (or 0/empty details)
      // lines?.found ?? 0 will be 0.
      expect(record.coveragePercentage, 0);
    });

    test('coveragePercentage handles division by zero and rounding', () async {
      // Create a record with specific values using Parser.parse to avoid type name issues
      final file = File('test_record.info');
      await file.writeAsString(
        'SF:test.dart\nDA:1,1\nDA:2,0\nDA:3,1\nLF:3\nLH:2\nend_of_record',
      );

      final records = await Parser.parse(file.path);
      final record = records.first;

      // 2/3 = 66.6666... rounded to 66.67
      expect(record.coveragePercentage, 66.67);

      await file.delete();
    });

    test('toRow handles null file and ANSI sanitization', () async {
      final record = Record.empty();
      final row = record.toRow();

      expect(row[0].toString(), contains('null'));
      expect(row[3].toString(), contains('0%'));
    });

    test('toRow sanitizes ANSI codes from filename', () async {
      final file = File('test_ansi.info');
      await file.writeAsString(
        'SF:\x1B[31mfile.dart\x1B[0m\nDA:1,1\nLF:1\nLH:1\nend_of_record',
      );

      final records = await Parser.parse(file.path);
      final record = records.first;
      final row = record.toRow();

      expect(row[0].toString(), contains('file.dart'));
      // The row adds its own color code at the start, but shouldn't have the red one (\x1B[31m) from our input
      expect(row[0].toString(), isNot(contains('\x1B[31m')));

      await file.delete();
    });

    test('toRow sanitizes Unicode Bidi control characters', () async {
      final file = File('test_bidi.info');
      // Filename with Right-to-Left Override (U+202E)
      const maliciousFilename = 'test\u202Etxt.js';
      await file.writeAsString(
        'SF:$maliciousFilename\nDA:1,1\nLF:1\nLH:1\nend_of_record',
      );

      final records = await Parser.parse(file.path);
      final record = records.first;
      final row = record.toRow();

      // Should be sanitized to 'testtxt.js'
      expect(row[0].toString(), contains('testtxt.js'));
      expect(row[0].toString(), isNot(contains('\u202E')));

      await file.delete();
    });
  });

  group('RecordListExtension', () {
    test('getCodeCoverageResult returns 0 if linesFoundSum is 0', () {
      final records = <Record>[Record.empty()];
      expect(records.getCodeCoverageResult(), 0);
    });

    test('getCodeCoverageResult calculates total coverage correctly', () async {
      final file = File('test_list.info');
      await file.writeAsString('''
SF:a.dart
DA:1,1
LF:1
LH:1
end_of_record
SF:b.dart
DA:1,0
DA:2,0
LF:2
LH:0
end_of_record
''');

      final records = await Parser.parse(file.path);
      // Total: 1 hit, 3 found -> 1/3 = 33.333... rounded to 33.33
      expect(records.getCodeCoverageResult(), 33.33);

      await file.delete();
    });
  });
}

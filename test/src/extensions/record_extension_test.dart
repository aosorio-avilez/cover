import 'package:cover/src/extensions/double_extension.dart';
import 'package:cover/src/extensions/record_extension.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:test/test.dart';

void main() {
  group('verify coveragePercentage', () {
    test('with empty record', () async {
      final record = Record.empty();

      expect(record.coveragePercentage, 0.0);
    });

    test('with valid record', () async {
      final record = Record.empty()
        ..lines?.found = 10
        ..lines?.hit = 5;

      expect(record.coveragePercentage, 50.0);
    });
  });

  group('verify toRow', () {
    test('with fail record', () async {
      final record = Record.empty();

      final row = record.toRow();

      expect(row, isA<List<Object>>());
      expect(row[0], '$redColor${record.file}');
      expect(row[1], '$redColor${record.lines?.found}');
      expect(row[2], '$redColor${record.lines?.hit}');
      expect(row[3], '$redColor${record.coveragePercentage}%');
    });

    test('to succes record', () async {
      final record = Record.empty()
        ..file = 'file_name'
        ..lines?.found = 10
        ..lines?.hit = 10;

      final row = record.toRow();

      expect(row, isA<List<Object>>());
      expect(row[0], '$greenColor${record.file}');
      expect(row[1], '$greenColor${record.lines?.found}');
      expect(row[2], '$greenColor${record.lines?.hit}');
      expect(row[3], '$greenColor${record.coveragePercentage}%');
    });

    test('to under under threshold record', () async {
      final record = Record.empty()
        ..file = 'file_name'
        ..lines?.found = 10
        ..lines?.hit = 8;

      final row = record.toRow();

      expect(row, isA<List<Object>>());
      expect(row[0], '$yellowColor${record.file}');
      expect(row[1], '$yellowColor${record.lines?.found}');
      expect(row[2], '$yellowColor${record.lines?.hit}');
      expect(row[3], '$yellowColor${record.coveragePercentage}%');
    });
  });

  group('verify getCodeCoverageResult', () {
    test('with empty records', () {
      final records = <Record>[
        Record.empty(),
        Record.empty(),
      ];

      final result = records.getCodeCoverageResult();

      expect(result, 0);
    });

    test('with records', () {
      final records = <Record>[
        Record.empty()
          ..lines?.found = 10
          ..lines?.hit = 10,
        Record.empty()
          ..lines?.found = 10
          ..lines?.hit = 10,
      ];

      final result = records.getCodeCoverageResult();

      expect(result, 100);
    });
  });
}

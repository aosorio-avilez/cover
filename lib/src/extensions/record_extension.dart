import 'package:cover/src/extensions/double_extension.dart';
import 'package:lcov_parser/lcov_parser.dart';

extension RecordExtension on Record {
  double get coveragePercentage {
    final linesHit = lines?.hit ?? 0;
    final linesFound = lines?.found ?? 0;
    final coveragePercentage = linesHit * 100 / linesFound;
    final coveragePercentageFixed = coveragePercentage.isNaN
        ? '0.00'
        : coveragePercentage.toStringAsFixed(2);
    return double.parse(coveragePercentageFixed);
  }

  List<Object> toRow() {
    final percentage = coveragePercentage;
    final color = percentage.getCoverageColorAnsi();
    return <Object>[
      '$color$file',
      '$color${lines?.found}',
      '$color${lines?.hit}',
      '$color$percentage%',
    ];
  }
}

extension RecordListExtension on List<Record> {
  double getCodeCoverageResult() {
    final linesFoundSum =
        map((record) => record.lines?.found ?? 0).reduce((r1, r2) => r1 + r2);
    final linesHitSum =
        map((record) => record.lines?.hit ?? 0).reduce((r1, r2) => r1 + r2);
    final coveragePercentage = linesHitSum * 100 / linesFoundSum;
    final coveragePercentageFixed = coveragePercentage.isNaN
        ? '0.00'
        : coveragePercentage.toStringAsFixed(2);
    return double.parse(coveragePercentageFixed);
  }
}

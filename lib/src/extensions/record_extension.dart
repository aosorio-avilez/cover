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
    final coveragePercentageSum =
        map((record) => record.coveragePercentage).reduce((r1, r2) => r1 + r2);
    final coveragePercentageFixed =
        (coveragePercentageSum / length).toStringAsFixed(2);
    return double.parse(coveragePercentageFixed);
  }
}

import 'package:cover/src/extensions/double_extension.dart';
import 'package:lcov_parser/lcov_parser.dart';

final _ansiEscapeRegExp = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');
final _controlCharRegExp = RegExp(r'[\x00-\x1F\x7F]');

extension RecordExtension on Record {
  double get coveragePercentage {
    final linesHit = lines?.hit ?? 0;
    final linesFound = lines?.found ?? 0;
    if (linesFound == 0) return 0;
    final coveragePercentage = linesHit * 100 / linesFound;
    // Optimization: avoid string allocation and parsing for rounding.
    return (coveragePercentage * 100).roundToDouble() / 100;
  }

  List<Object> toRow() {
    final percentage = coveragePercentage;
    final color = percentage.getCoverageColorAnsi();
    final sanitizedFile = (file ?? 'null')
        .replaceAll(_ansiEscapeRegExp, '')
        .replaceAll(_controlCharRegExp, '');
    return <Object>[
      '$color$sanitizedFile',
      '$color${lines?.found}',
      '$color${lines?.hit}',
      '$color$percentage%',
    ];
  }
}

extension RecordListExtension on List<Record> {
  double getCodeCoverageResult() {
    var linesFoundSum = 0;
    var linesHitSum = 0;
    for (final record in this) {
      linesFoundSum += record.lines?.found ?? 0;
      linesHitSum += record.lines?.hit ?? 0;
    }
    if (linesFoundSum == 0) return 0;
    final coveragePercentage = linesHitSum * 100 / linesFoundSum;
    // Optimization: avoid string allocation and parsing for rounding.
    return (coveragePercentage * 100).roundToDouble() / 100;
  }
}

import 'package:lcov_parser/lcov_parser.dart';
import 'double_extension.dart';

final _ansiAndControlRegExp = RegExp(
  r'\x1B\[[0-?]*[ -/]*[@-~]|[\x00-\x1F\x7F]',
);

extension RecordExtension on Record {
  /// Returns the coverage percentage for the record, rounded to 2 decimal places.
  double get coveragePercentage {
    final currentLines = lines;
    final linesHit = currentLines?.hit ?? 0;
    final linesFound = currentLines?.found ?? 0;
    if (linesFound == 0) return 0;
    final percentage = linesHit * 100 / linesFound;
    // Optimization: avoid string allocation and parsing for rounding.
    return (percentage * 100).roundToDouble() / 100;
  }

  /// Returns a row for the coverage table.
  List<Object> toRow() {
    final percentage = coveragePercentage;
    final fileName = file ?? 'null';

    // Optimization: check for control characters before using `replaceAll`
    // to avoid regex overhead on clean strings (which is the common case).
    final sanitizedFile = _hasAnsiOrControlChars(fileName)
        ? fileName.replaceAll(_ansiAndControlRegExp, '')
        : fileName;

    // Fast-path for 100% coverage which is a very common case.
    // Uses pre-resolved `green100` from DoubleExtension.
    if (percentage == 100.0) {
      return <Object>[
        '$greenColor$sanitizedFile',
        '$greenColor${lines?.found}',
        '$greenColor${lines?.hit}',
        green100,
      ];
    }

    final color = percentage.getCoverageColorAnsi();

    return <Object>[
      '$color$sanitizedFile',
      '$color${lines?.found}',
      '$color${lines?.hit}',
      '$color$percentage%',
    ];
  }
}

bool _hasAnsiOrControlChars(String s) {
  for (var i = 0; i < s.length; i++) {
    final code = s.codeUnitAt(i);
    // 0x00-0x1F (control chars including \x1B) and 0x7F (DEL)
    if (code <= 0x1F || code == 0x7F) {
      return true;
    }
  }
  return false;
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

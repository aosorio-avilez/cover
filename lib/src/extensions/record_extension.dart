import 'package:cover/src/extensions/double_extension.dart';
import 'package:lcov_parser/lcov_parser.dart';

final _unsafeCharsRegExp = RegExp(
  r'\x1B\[[0-?]*[ -/]*[@-~]|[\x00-\x1F\x7F]|[\u202A-\u202E\u2066-\u2069\u200E\u200F\u061C]',
);

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
    final fileName = file ?? 'null';
    // Optimization: check for control characters before using `replaceAll`
    // to avoid regex overhead on clean strings (which is the common case).
    final sanitizedFile = _hasUnsafeChars(fileName)
        ? fileName.replaceAll(_unsafeCharsRegExp, '')
        : fileName;
    return <Object>[
      '$color$sanitizedFile',
      '$color${lines?.found}',
      '$color${lines?.hit}',
      '$color$percentage%',
    ];
  }
}

bool _hasUnsafeChars(String s) {
  for (var i = 0; i < s.length; i++) {
    final code = s.codeUnitAt(i);
    // 0x00-0x1F (control chars including \x1B) and 0x7F (DEL)
    // 0x202A-0x202E (Embedding/Override), 0x2066-0x2069 (Isolates)
    // 0x200E (LRM), 0x200F (RLM), 0x061C (ALM)
    if (code <= 0x1F ||
        code == 0x7F ||
        (code >= 0x202A && code <= 0x202E) ||
        (code >= 0x2066 && code <= 0x2069) ||
        code == 0x200E ||
        code == 0x200F ||
        code == 0x061C) {
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

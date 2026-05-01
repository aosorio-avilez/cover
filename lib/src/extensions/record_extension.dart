import 'package:cover/src/extensions/double_extension.dart';
import 'package:lcov_parser/lcov_parser.dart';

final _ansiAndControlRegExp = RegExp(
  r'\x1B\[[0-?]*[ -/]*[@-~]|[\x00-\x1F\x7F\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069]',
);

extension RecordExtension on Record {
  List<int> get uncoveredLines {
    final details = lines?.details;
    if (details == null) return [];
    return details
        .where((detail) => (detail.hit ?? 0) == 0)
        .map((detail) => detail.line ?? 0)
        .where((line) => line != 0)
        .toList();
  }

  String _formatUncoveredLines(List<int> lines) {
    if (lines.isEmpty) return '';
    lines.sort();
    final ranges = <String>[];
    var start = lines[0];
    var end = lines[0];

    for (var i = 1; i < lines.length; i++) {
      if (lines[i] == end + 1) {
        end = lines[i];
      } else {
        ranges.add(start == end ? '$start' : '$start-$end');
        start = lines[i];
        end = lines[i];
      }
    }
    ranges.add(start == end ? '$start' : '$start-$end');
    return ranges.join(', ');
  }

  double get coveragePercentage {
    final lines = this.lines;
    final linesHit = lines?.hit ?? 0;
    final linesFound = lines?.found ?? 0;
    if (linesFound == 0) return 0;
    final coveragePercentage = linesHit * 100 / linesFound;
    // Optimization: avoid string allocation and parsing for rounding.
    return (coveragePercentage * 100).roundToDouble() / 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'coverage': coveragePercentage,
      'lines_found': lines?.found ?? 0,
      'lines_hit': lines?.hit ?? 0,
      'uncovered_lines': uncoveredLines,
    };
  }

  List<Object> toRow({bool showUncovered = false}) {
    final percentage = coveragePercentage;
    final color = percentage.getCoverageColorAnsi();
    final lines = this.lines;

    // Optimization: Use a fast-path for 100% coverage by using the `green100`
    // constant (a pre-interpolated string from `DoubleExtension`), which
    // eliminates redundant string allocations and interpolations.
    final formattedPercentage =
        percentage == 100 ? green100 : '$color$percentage%';

    final fileName = file ?? 'null';
    // Optimization: check for control characters before using `replaceAll`
    // to avoid regex overhead on clean strings (which is the common case).
    final sanitizedFile = _hasAnsiOrControlChars(fileName)
        ? fileName.replaceAll(_ansiAndControlRegExp, '')
        : fileName;

    final row = <Object>[
      '$color$sanitizedFile',
      '$color${lines?.found}',
      '$color${lines?.hit}',
      formattedPercentage,
    ];

    if (showUncovered) {
      row.add('$color${_formatUncoveredLines(uncoveredLines)}');
    }

    return row;
  }
}

bool _hasAnsiOrControlChars(String s) {
  for (var i = 0; i < s.length; i++) {
    final code = s.codeUnitAt(i);
    // 0x00-0x1F (control chars including \x1B) and 0x7F (DEL)
    // Also include Unicode Bidi control characters.
    if (code <= 0x1F ||
        code == 0x7F ||
        code == 0x061C ||
        code == 0x200E ||
        code == 0x200F ||
        (code >= 0x202A && code <= 0x202E) ||
        (code >= 0x2066 && code <= 0x2069)) {
      return true;
    }
  }
  return false;
}

extension RecordListExtension on List<Record> {
  double getCodeCoverageResult() {
    var linesFoundSum = 0;
    var linesHitSum = 0;
    final len = length;
    for (var i = 0; i < len; i++) {
      final lines = this[i].lines;
      if (lines != null) {
        linesFoundSum += lines.found ?? 0;
        linesHitSum += lines.hit ?? 0;
      }
    }
    if (linesFoundSum == 0) return 0;
    final coveragePercentage = linesHitSum * 100 / linesFoundSum;
    // Optimization: avoid string allocation and parsing for rounding.
    return (coveragePercentage * 100).roundToDouble() / 100;
  }
}

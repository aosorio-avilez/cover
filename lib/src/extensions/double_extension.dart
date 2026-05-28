import 'package:dart_console/dart_console.dart';

final greenColor = ConsoleColor.brightGreen.ansiSetForegroundColorSequence;
final yellowColor = ConsoleColor.brightYellow.ansiSetForegroundColorSequence;
final redColor = ConsoleColor.brightRed.ansiSetForegroundColorSequence;

final green100 = '${greenColor}100.0%';

extension DoubleExtension on double {
  double roundToDoubleWithPrecision(int fractionDigits) {
    var mod = 1.0;
    for (var i = 0; i < fractionDigits; i++) {
      mod *= 10;
    }
    return (this * mod).roundToDouble() / mod;
  }

  String getCoverageColorAnsi({double minCoverage = 100.0}) {
    if (this >= minCoverage) {
      return greenColor;
    }
    if (this >= minCoverage * 0.8) {
      return yellowColor;
    }
    return redColor;
  }

  String getCoverageEmoji({double minCoverage = 100.0}) {
    if (this >= minCoverage) {
      return '🟢';
    }
    if (this >= minCoverage * 0.8) {
      return '🟡';
    }
    return '🔴';
  }

  String getProgressBar({double minCoverage = 100.0}) {
    final emoji = getCoverageEmoji(minCoverage: minCoverage);
    final coloredBlock = switch (emoji) {
      '🟢' => '🟩',
      '🟡' => '🟨',
      '🔴' || _ => '🟥',
    };

    final filledCount = (this / 10).clamp(0, 10).floor();
    final emptyCount = 10 - filledCount;

    return (coloredBlock * filledCount) + ('⬜' * emptyCount);
  }
}

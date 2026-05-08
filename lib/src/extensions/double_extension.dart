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

  String getCoverageColorAnsi() {
    return switch (this) {
      100 => greenColor,
      >= 80 && < 100 => yellowColor,
      _ => redColor,
    };
  }
}

import 'package:dart_console/dart_console.dart';

final passColor = ConsoleColor.brightGreen.ansiSetForegroundColorSequence;
final underThresholdColor =
    ConsoleColor.brightYellow.ansiSetForegroundColorSequence;
final failColor = ConsoleColor.brightRed.ansiSetForegroundColorSequence;

extension DoubleExtension on double {
  String getCoverageColorAnsi() {
    return switch (this) {
      100 => passColor,
      >= 80 && < 100 => underThresholdColor,
      _ => failColor,
    };
  }
}

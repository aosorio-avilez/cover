import 'package:dart_console/dart_console.dart';

final greenColor = ConsoleColor.brightGreen.ansiSetForegroundColorSequence;
final yellowColor = ConsoleColor.brightYellow.ansiSetForegroundColorSequence;
final redColor = ConsoleColor.brightRed.ansiSetForegroundColorSequence;

/// Pre-resolved colorized string for 100% coverage to avoid repeated
/// interpolation in loops.
final green100 = '${greenColor}100.0%';

extension DoubleExtension on double {
  String getCoverageColorAnsi() {
    return switch (this) {
      100 => greenColor,
      >= 80 && < 100 => yellowColor,
      _ => redColor,
    };
  }
}

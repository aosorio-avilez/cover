import 'package:lcov_parser/lcov_parser.dart';

void main() {
  final record = Record();
  print('Fields:');
  // Record usually has: file, lines, functions, branches
  print('file: ${record.file}');
  print('lines: ${record.lines}');
  if (record.lines != null) {
    print('lines.found: ${record.lines?.found}');
    print('lines.hit: ${record.lines?.hit}');
  }
}

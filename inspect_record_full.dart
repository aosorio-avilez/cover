import 'package:lcov_parser/lcov_parser.dart';

void main() {
  final record = Record();
  print('file: ${record.file}');
  print('lines: ${record.lines}');
  try {
    print('functions: ${(record as dynamic).functions}');
  } catch (_) {
    print('functions: N/A');
  }
  try {
    print('branches: ${(record as dynamic).branches}');
  } catch (_) {
    print('branches: N/A');
  }
}

import 'package:lcov_parser/lcov_parser.dart';

void main() {
  final record = Record();
  if (record.lines != null) {
     print('Lines hit: ${record.lines!.hit}');
     print('Lines found: ${record.lines!.found}');
  }

  // Checking for functions and branches
  print('Has functions: ${(record as dynamic).functions != null}');
  print('Has branches: ${(record as dynamic).branches != null}');
}

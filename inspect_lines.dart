import 'package:lcov_parser/lcov_parser.dart';

void main() async {
  final records = await Parser.parse('test/stubs/lcov_complete.info');
  final record = records.first;
  print('Details: ${record.lines?.details}');
  if (record.lines?.details != null) {
    for (var detail in record.lines!.details!) {
      print('Line ${detail.line}: ${detail.hit}');
    }
  }
}

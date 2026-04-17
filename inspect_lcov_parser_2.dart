import 'package:lcov_parser/lcov_parser.dart';

void main() async {
  final records = await Parser.parse('test/stubs/lcov_complete.info');
  if (records.isNotEmpty) {
    final record = records.first;
    print('Record for ${record.file}');
    print('Lines: ${record.lines?.hit}/${record.lines?.found}');
    try {
      final functions = (record as dynamic).functions;
      print('Functions: ${functions?.hit}/${functions?.found}');
    } catch (e) {
      print('Functions: N/A ($e)');
    }
    try {
      final branches = (record as dynamic).branches;
      print('Branches: ${branches?.hit}/${branches?.found}');
    } catch (e) {
      print('Branches: N/A ($e)');
    }
  }
}

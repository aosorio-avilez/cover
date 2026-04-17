import 'package:lcov_parser/lcov_parser.dart';

void main() {
  final record = Record();
  try {
    // ignore: avoid_dynamic_calls
    print((record as dynamic).toJson());
  } catch (e) {
    print('No toJson method');
  }
}

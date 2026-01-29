import 'package:lcov_parser/lcov_parser.dart';

class CoverageResult {
  const CoverageResult({required this.coverage, required this.files});

  final double coverage;
  final List<Record> files;
}

import 'package:cover/src/extensions/record_extension.dart';
import 'package:lcov_parser/lcov_parser.dart';

class CoverageResult {
  const CoverageResult({required this.coverage, required this.files});

  final double coverage;
  final List<Record> files;

  Map<String, dynamic> toJson() {
    return {
      'coverage': coverage,
      'files': files.map((file) => file.toJson()).toList(),
    };
  }
}

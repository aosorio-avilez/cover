import 'package:cover/src/extensions/record_extension.dart';
import 'package:lcov_parser/lcov_parser.dart';

class CoverageResult {
  const CoverageResult({required this.coverage, required this.files});

  final double coverage;
  final List<Record> files;

  Map<String, dynamic> toJson({
    required double minCoverage,
    List<String> excludePaths = const [],
    bool excludeGenerated = false,
  }) {
    return {
      'coverage': coverage,
      'min_coverage': minCoverage,
      'passed': coverage >= minCoverage,
      'timestamp': DateTime.now().toIso8601String(),
      'files_count': files.length,
      'exclude_generated': excludeGenerated,
      'excluded_paths': excludePaths,
      'files': files.map((file) => file.toJson()).toList(),
    };
  }
}

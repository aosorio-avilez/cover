import 'package:cover/src/extensions/double_extension.dart';
import 'package:cover/src/extensions/record_extension.dart';
import 'package:lcov_parser/lcov_parser.dart';

class CoverageResult {
  const CoverageResult({
    required this.coverage,
    required this.files,
    this.baselineCoverage,
  });

  final double coverage;
  final List<Record> files;
  final double? baselineCoverage;

  Map<String, dynamic> toJson({
    required double minCoverage,
    List<String> excludePaths = const [],
    bool excludeGenerated = false,
    bool failuresOnly = false,
  }) {
    final delta = baselineCoverage != null
        ? (coverage - baselineCoverage!).roundToDoubleWithPrecision(2)
        : null;

    final filesToSerialize = failuresOnly
        ? files.where((f) => f.coveragePercentage < minCoverage).toList()
        : files;

    return {
      'coverage': coverage,
      'min_coverage': minCoverage,
      'baseline_coverage': baselineCoverage,
      'delta': delta,
      'passed': coverage >= minCoverage &&
          (baselineCoverage == null || coverage >= baselineCoverage!),
      'timestamp': DateTime.now().toIso8601String(),
      'files_count': files.length,
      'exclude_generated': excludeGenerated,
      'excluded_paths': excludePaths,
      'failures_only': failuresOnly,
      'files': filesToSerialize.map((file) => file.toJson()).toList(),
    };
  }
}

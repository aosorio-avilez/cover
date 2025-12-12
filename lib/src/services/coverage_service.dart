import 'package:cover/src/extensions/record_extension.dart';
import 'package:cover/src/models/coverage_result.dart';
import 'package:lcov_parser/lcov_parser.dart';

class CoverageService {
  Future<CoverageResult> checkCoverage({
    required String filePath,
    required double minCoverage,
    List<String> excludePaths = const [],
  }) async {
    final files = await _parseCoverageFile(filePath, excludePaths);

    if (files.isEmpty) {
      throw const FormatException(
        'File is empty or does not have the correct format',
      );
    }

    final currentCoverage = files.getCodeCoverageResult();

    return CoverageResult(
      coverage: currentCoverage,
      files: files,
    );
  }

  Future<List<Record>> _parseCoverageFile(
    String filePath,
    List<String> excludedPaths,
  ) async {
    final files = await Parser.parse(filePath);

    if (excludedPaths.isEmpty) {
      return files;
    }

    final filteredFiles = files.toList();
    for (final excludedPath in excludedPaths) {
      final excludePattern = RegExp(excludedPath);
      filteredFiles.removeWhere(
        (record) => excludePattern.hasMatch(record.file ?? ''),
      );
    }

    return filteredFiles;
  }
}

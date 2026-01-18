import 'dart:io';

import 'package:cover/src/extensions/record_extension.dart';
import 'package:cover/src/models/coverage_result.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:path/path.dart' as path;

class CoverageService {
  Future<CoverageResult> checkCoverage({
    required String filePath,
    required double minCoverage,
    List<String> excludePaths = const [],
  }) async {
    if (!_isPathAllowed(filePath)) {
      throw const FormatException(
        'File path must be within the current working directory.',
      );
    }

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

    // Optimization: Use `String.contains` instead of `RegExp` to avoid compilation overhead
    // and iterate the list only once for better performance.
    return files.where((record) {
      final file = record.file ?? '';
      return !excludedPaths.any(file.contains);
    }).toList();
  }

  bool _isPathAllowed(String filePath) {
    try {
      final canonicalPath = File(filePath).resolveSymbolicLinksSync();
      final currentPath =
          File(Directory.current.path).resolveSymbolicLinksSync();
      return path.isWithin(currentPath, canonicalPath) ||
          canonicalPath == currentPath;
    } catch (e) {
      // If resolving the symbolic link fails (e.g. file doesn't exist),
      // we fallback to simple canonicalization but this might be safer to just return false
      // or rethrow. However, for consistency with previous behavior for non-existent files:
      final canonicalPath = path.canonicalize(filePath);
      final currentPath = path.canonicalize(Directory.current.path);
      return path.isWithin(currentPath, canonicalPath) ||
          canonicalPath == currentPath;
    }
  }
}

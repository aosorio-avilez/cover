import 'dart:io';

import 'package:cover/src/extensions/record_extension.dart';
import 'package:cover/src/models/coverage_result.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:path/path.dart' as path;

class CoverageService {
  CoverageService({Directory? currentDirectory})
      : _currentDirectory = currentDirectory ?? Directory.current;

  final Directory _currentDirectory;

  Future<CoverageResult> checkCoverage({
    required String filePath,
    required double minCoverage,
    List<String> excludePaths = const [],
  }) async {
    if (filePath.isEmpty) {
      throw const PathNotFoundException(
        '',
        OSError('File path cannot be empty', 2),
      );
    }

    final resolvedPath = _validatePath(filePath);

    final files = await _parseCoverageFile(resolvedPath, excludePaths);

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
    // Note: filePath is now expected to be a validated, absolute path.
    final files = await Parser.parse(filePath);

    // Optimization: Filter out empty strings to avoid matching all files and
    // ensure correctness.
    final validExcludedPaths =
        excludedPaths.where((e) => e.isNotEmpty).toList();

    if (validExcludedPaths.isEmpty) {
      return files;
    }

    // Optimization: Use `String.contains` instead of `RegExp` to avoid
    // compilation overhead. Use `retainWhere` to modify the list in-place,
    // avoiding extra list allocation and copying.
    // Note: `files` is a fresh list from `Parser.parse`, so we can mutate it
    // safely.
    files.retainWhere((record) {
      final file = record.file ?? '';
      // Optimization: use explicit loop to avoid allocating a bound method
      // (tear-off) for `file.contains` for every record.
      for (final excluded in validExcludedPaths) {
        if (file.contains(excluded)) {
          return false;
        }
      }
      return true;
    });
    return files;
  }

  String _validatePath(String filePath) {
    final absolutePath = path.isAbsolute(filePath)
        ? filePath
        : path.join(_currentDirectory.path, filePath);

    String resolvedPath;
    try {
      resolvedPath = File(absolutePath).resolveSymbolicLinksSync();
    } catch (_) {
      resolvedPath = absolutePath;
    }

    final canonicalPath = path.canonicalize(resolvedPath);

    String currentResolvedPath;
    try {
      currentResolvedPath = _currentDirectory.resolveSymbolicLinksSync();
    } catch (_) {
      currentResolvedPath = _currentDirectory.path;
    }
    final currentPath = path.canonicalize(currentResolvedPath);

    if (path.isWithin(currentPath, canonicalPath) ||
        canonicalPath == currentPath) {
      return canonicalPath;
    }

    throw const FormatException(
      'File path must be within the current working directory.',
    );
  }
}

import 'dart:io';

import 'package:cover/src/extensions/record_extension.dart';
import 'package:cover/src/models/coverage_result.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:path/path.dart' as path;

class CoverageService {
  CoverageService({Directory? currentDirectory})
      : _currentDirectory = currentDirectory ?? Directory.current;

  final Directory _currentDirectory;
  Future<String>? _resolvedCurrentDirectoryPath;

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

    final resolvedPath = await _validatePath(filePath);

    final file = File(resolvedPath);
    if (!await file.exists()) {
      throw PathNotFoundException(
        resolvedPath,
        const OSError('File not found', 2),
      );
    }

    if (await file.length() == 0) {
      throw const FormatException(
        'File is empty or does not have the correct format',
      );
    }

    final files = await _parseCoverageFile(resolvedPath, excludePaths);

    if (files.isEmpty) {
      throw const FormatException(
        'File is empty or does not have the correct format',
      );
    }

    final currentCoverage = files.getCodeCoverageResult();

    return CoverageResult(coverage: currentCoverage, files: files);
  }

  Future<List<Record>> _parseCoverageFile(
    String filePath,
    List<String> excludedPaths,
  ) async {
    // Note: filePath is now expected to be a validated, absolute path.
    List<Record> files;
    try {
      files = await Parser.parse(filePath);
    } catch (e) {
      throw FormatException('Failed to parse coverage file: $e');
    }

    // Optimization: Filter out empty strings to avoid matching all files and
    // ensure correctness.
    if (excludedPaths.isEmpty) {
      return files;
    }

    final validExcludedPaths = excludedPaths.where((e) => e.isNotEmpty).toSet();

    if (validExcludedPaths.isEmpty) {
      return files;
    }

    // Optimization: Using a single RegExp with alternation is significantly
    // faster than iterating through the list with String.contains for larger
    // sets of excluded paths.
    final pattern = validExcludedPaths.map(RegExp.escape).join('|');
    final regExp = RegExp(pattern);

    // Note: `files` is a fresh list from `Parser.parse`, so we can mutate it
    // safely.
    files.retainWhere((record) {
      final file = record.file ?? '';
      return !regExp.hasMatch(file);
    });
    return files;
  }

  Future<String> _validatePath(String filePath) async {
    final absolutePath = path.isAbsolute(filePath)
        ? filePath
        : path.join(_currentDirectory.path, filePath);

    String resolvedPath;
    try {
      resolvedPath = await File(absolutePath).resolveSymbolicLinks();
    } catch (_) {
      resolvedPath = absolutePath;
    }

    final canonicalPath = path.canonicalize(resolvedPath);

    // Optimization: Cache the resolved symbolic link path of the current
    // directory to avoid redundant asynchronous I/O operations.
    _resolvedCurrentDirectoryPath ??= _currentDirectory.resolveSymbolicLinks();

    String currentResolvedPath;
    try {
      currentResolvedPath = await _resolvedCurrentDirectoryPath!;
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

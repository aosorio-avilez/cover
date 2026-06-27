import 'dart:convert';
import 'dart:io';

import 'package:cover/src/extensions/record_extension.dart';
import 'package:cover/src/models/coverage_result.dart';
import 'package:lcov_parser/lcov_parser.dart';
// Lines and LcovLinesDetails are part of the effective public API
// of lcov_parser (they are field types of the exported Record class)
// but are not yet exported from lib/lcov_parser.dart.
// Tracked at: https://github.com/eliasreis54/lcov_parser/issues/17
// ignore: implementation_imports
import 'package:lcov_parser/src/models/lines.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

class CoverageService {
  CoverageService({Directory? currentDirectory})
      : _currentDirectory = currentDirectory ?? Directory.current;

  static const _generatedPattern =
      r'\.(g|freezed|mocks|template|reflectable|config|pigeon|gr|pb|graphql|mapper)\.dart$';

  static final _generatedRegExp = RegExp(
    _generatedPattern,
    caseSensitive: false,
  );

  final Directory _currentDirectory;
  Future<String>? _resolvedCurrentDirectoryPath;
  String? _packageName;

  Future<String> _getPackageName() async {
    if (_packageName != null) return _packageName!;

    try {
      final pubspecFile =
          File(path.join(_currentDirectory.path, 'pubspec.yaml'));
      if (pubspecFile.existsSync()) {
        final content = pubspecFile.readAsStringSync();
        final pubspec = Pubspec.parse(content);
        _packageName = pubspec.name;
      }
    } catch (_) {
      // Fallback if pubspec.yaml can't be parsed
    }
    _packageName ??= 'unknown';
    return _packageName!;
  }

  Future<CoverageResult> checkCoverage({
    required String filePath,
    required double minCoverage,
    List<String> excludePaths = const [],
    bool excludeGenerated = false,
    String? baselinePath,
  }) async {
    final files = await _getCoverageData(
      filePath: filePath,
      excludePaths: excludePaths,
      excludeGenerated: excludeGenerated,
    );

    final currentCoverage = files.getCodeCoverageResult();

    double? baselineCoverage;
    if (baselinePath != null && baselinePath.isNotEmpty) {
      final baselineFiles = await _getCoverageData(
        filePath: baselinePath,
        excludePaths: excludePaths,
        excludeGenerated: excludeGenerated,
      );
      baselineCoverage = baselineFiles.getCodeCoverageResult();
    }

    return CoverageResult(
      coverage: currentCoverage,
      files: files,
      baselineCoverage: baselineCoverage,
    );
  }

  Future<List<Record>> _getCoverageData({
    required String filePath,
    required List<String> excludePaths,
    required bool excludeGenerated,
  }) async {
    if (filePath.isEmpty) {
      throw const PathNotFoundException(
        '',
        OSError('File path cannot be empty', 2),
      );
    }

    var targetPath = filePath;
    final absolutePath = path.isAbsolute(targetPath)
        ? targetPath
        : path.join(_currentDirectory.path, targetPath);

    if (path.basename(absolutePath) == 'lcov.info') {
      final file = File(absolutePath);
      if (!file.existsSync()) {
        final parentDir = Directory(path.dirname(absolutePath));
        if (parentDir.existsSync()) {
          targetPath = path.dirname(targetPath);
        }
      }
    }

    final resolvedPath = await _validatePath(targetPath);
    final stat = await FileStat.stat(resolvedPath);

    if (stat.type == FileSystemEntityType.notFound) {
      throw PathNotFoundException(
        resolvedPath,
        const OSError('Path not found', 2),
      );
    }

    List<Record> files;

    if (stat.type == FileSystemEntityType.directory) {
      files = await _parseDirectory(
        Directory(resolvedPath),
        excludePaths,
        excludeGenerated: excludeGenerated,
      );
    } else {
      if (stat.size == 0) {
        throw const FormatException(
          'File is empty or does not have the correct format',
        );
      }

      if (resolvedPath.endsWith('.json')) {
        files = await _parseJsonCoverage(
          File(resolvedPath),
          excludePaths,
          excludeGenerated: excludeGenerated,
        );
      } else if (resolvedPath.endsWith('.info')) {
        files = await _parseCoverageFile(
          resolvedPath,
          excludePaths,
          excludeGenerated: excludeGenerated,
        );
      } else {
        throw const FormatException(
          'Unsupported file format. Expected .info or .json file.',
        );
      }
    }

    if (files.isEmpty && !excludeGenerated && excludePaths.isEmpty) {
      throw const FormatException(
        'File is empty or does not have the correct format',
      );
    }

    return files;
  }

  Future<List<Record>> _parseJsonCoverage(
    File file,
    List<String> excludedPaths, {
    bool excludeGenerated = false,
  }) async {
    final packageName = await _getPackageName();
    final mergedHits = <String, Map<int, int>>{};

    try {
      await _parseJsonCoverageFile(file, packageName, mergedHits);
    } catch (e) {
      throw FormatException('Failed to parse coverage file: $e');
    }

    final files =
        mergedHits.entries.map((e) => _createRecord(e.key, e.value)).toList();

    return _filterRecords(
      files,
      excludedPaths,
      excludeGenerated: excludeGenerated,
    );
  }

  Future<List<Record>> _parseDirectory(
    Directory directory,
    List<String> excludedPaths, {
    bool excludeGenerated = false,
  }) async {
    final filesList = <File>[];
    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        filesList.add(entity);
      }
    }

    final recordsLists = <List<Record>>[];

    final jsonFiles = filesList.where((f) => f.path.endsWith('.json')).toList();
    if (jsonFiles.isNotEmpty) {
      final packageName = await _getPackageName();
      final mergedHits = <String, Map<int, int>>{};

      for (final jsonFile in jsonFiles) {
        try {
          await _parseJsonCoverageFile(jsonFile, packageName, mergedHits);
        } catch (_) {
          // Ignore malformed JSON files during directory scan
        }
      }

      if (mergedHits.isNotEmpty) {
        final files = mergedHits.entries
            .map((e) => _createRecord(e.key, e.value))
            .toList();

        final filteredFiles = _filterRecords(
          files,
          excludedPaths,
          excludeGenerated: excludeGenerated,
        );
        if (filteredFiles.isNotEmpty) {
          recordsLists.add(filteredFiles);
        }
      }
    }

    final infoFiles = filesList.where((f) => f.path.endsWith('.info')).toList();
    if (infoFiles.isNotEmpty) {
      for (final infoFile in infoFiles) {
        try {
          final records = await _parseCoverageFile(
            infoFile.path,
            excludedPaths,
            excludeGenerated: excludeGenerated,
          );
          if (records.isNotEmpty) {
            recordsLists.add(records);
          }
        } catch (_) {
          // Ignore malformed info files during directory scan
        }
      }
    }

    if (recordsLists.isEmpty) {
      throw FormatException(
        'No coverage files found in directory: ${directory.path}',
      );
    }

    return _mergeRecords(recordsLists);
  }

  List<Record> _mergeRecords(List<List<Record>> recordsLists) {
    final defaultHits = <String, Record>{};
    final mergedHits = <String, Map<int, int>>{};

    for (final list in recordsLists) {
      for (final record in list) {
        final file = record.file;
        if (file == null) continue;

        if (!defaultHits.containsKey(file) && !mergedHits.containsKey(file)) {
          defaultHits[file] = record;
        } else {
          final lineHits = mergedHits.putIfAbsent(file, () {
            final existing = defaultHits.remove(file)!;
            final hits = <int, int>{};
            final existingDetails = existing.lines?.details;
            if (existingDetails != null) {
              final len = existingDetails.length;
              for (var i = 0; i < len; i++) {
                final d = existingDetails[i];
                if (d.line != null) {
                  hits[d.line!] = (hits[d.line!] ?? 0) + (d.hit ?? 0);
                }
              }
            }
            return hits;
          });

          final incomingDetails = record.lines?.details;
          if (incomingDetails != null) {
            final len = incomingDetails.length;
            for (var i = 0; i < len; i++) {
              final d = incomingDetails[i];
              if (d.line != null) {
                lineHits[d.line!] = (lineHits[d.line!] ?? 0) + (d.hit ?? 0);
              }
            }
          }
        }
      }
    }

    final result = defaultHits.values.toList();
    for (final entry in mergedHits.entries) {
      result.add(_createRecord(entry.key, entry.value));
    }
    return result;
  }

  Future<void> _parseJsonCoverageFile(
    File file,
    String packageName,
    Map<String, Map<int, int>> mergedHits,
  ) async {
    final content = await file.readAsString();
    if (content.trim().isEmpty) return;

    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) return;

    final coverage = decoded['coverage'];
    if (coverage is! List) return;

    for (final entry in coverage) {
      if (entry is! Map<String, dynamic>) continue;

      final source = entry['source'] as String?;
      if (source == null || source.isEmpty) continue;

      final resolvedPath = await _resolveSourcePath(source, packageName);
      if (resolvedPath == null) continue;

      final hits = entry['hits'];
      if (hits is! List) continue;

      final lineHits = mergedHits.putIfAbsent(resolvedPath, () => <int, int>{});
      final len = hits.length;
      for (var i = 0; i < len - 1; i += 2) {
        final line = hits[i];
        final hit = hits[i + 1];
        if (line is int && hit is int) {
          lineHits[line] = (lineHits[line] ?? 0) + hit;
        }
      }
    }
  }

  Future<String?> _resolveSourcePath(String source, String packageName) async {
    final decodedSource = Uri.decodeComponent(source);

    if (decodedSource.startsWith('package:')) {
      final packagePrefix = 'package:$packageName/';
      if (decodedSource.startsWith(packagePrefix)) {
        final relativePath = decodedSource.substring(packagePrefix.length);
        return path.join('lib', relativePath);
      } else {
        // Belongs to another package (dependency)
        return null;
      }
    }

    // Handle file URIs
    if (decodedSource.startsWith('file://')) {
      final uri = Uri.tryParse(decodedSource);
      if (uri != null) {
        final filePath = uri.toFilePath();
        final relative = path.relative(filePath, from: _currentDirectory.path);
        if (!relative.startsWith('..') && !path.isAbsolute(relative)) {
          return relative;
        }
      }
      return null;
    }

    // Handle relative/absolute paths
    final absolutePath = path.isAbsolute(decodedSource)
        ? decodedSource
        : path.join(_currentDirectory.path, decodedSource);
    final relative = path.relative(absolutePath, from: _currentDirectory.path);
    if (!relative.startsWith('..') && !path.isAbsolute(relative)) {
      return relative;
    }

    return null;
  }

  Record _createRecord(String resolvedPath, Map<int, int> lineHits) {
    final details = <Lines>[];
    var hitCount = 0;

    final sortedLines = lineHits.keys.toList()..sort();

    for (final line in sortedLines) {
      final hit = lineHits[line]!;
      if (hit > 0) {
        hitCount++;
      }
      details.add(Lines(line: line, hit: hit));
    }

    return Record(
      file: resolvedPath,
      lines: LcovLinesDetails(
        found: lineHits.length,
        hit: hitCount,
        details: details,
      ),
    );
  }

  Future<List<Record>> _parseCoverageFile(
    String filePath,
    List<String> excludedPaths, {
    bool excludeGenerated = false,
  }) async {
    List<Record> files;
    try {
      files = await Parser.parse(filePath);
    } on FileSystemException {
      rethrow;
    } on FileMustBeProvided {
      rethrow;
    } catch (e) {
      throw FormatException('Failed to parse coverage file: $e');
    }

    return _filterRecords(
      files,
      excludedPaths,
      excludeGenerated: excludeGenerated,
    );
  }

  List<Record> _filterRecords(
    List<Record> files,
    List<String> excludedPaths, {
    bool excludeGenerated = false,
  }) {
    files.retainWhere((record) {
      final file = record.file;
      if (file == null || file.isEmpty) return false;

      final relativePath = path.isAbsolute(file)
          ? path.relative(file, from: _currentDirectory.path)
          : file;

      final segments = path.split(relativePath);
      if (segments.isNotEmpty && segments.first == 'test') {
        return false;
      }
      return true;
    });

    final validExcludedPaths = excludedPaths.where((e) => e.isNotEmpty).toSet();

    if (validExcludedPaths.isEmpty && !excludeGenerated) {
      return files;
    }

    RegExp regExp;

    if (validExcludedPaths.isEmpty && excludeGenerated) {
      regExp = _generatedRegExp;
    } else {
      final patterns = validExcludedPaths.map(RegExp.escape).toList();

      if (excludeGenerated) {
        patterns.add(_generatedPattern);
      }

      regExp = RegExp(patterns.join('|'), caseSensitive: false);
    }

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

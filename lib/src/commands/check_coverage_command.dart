import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/extensions/double_extension.dart';
import 'package:cover/src/extensions/record_extension.dart';
import 'package:cover/src/extensions/string_extension.dart';
import 'package:cover/src/models/coverage_result.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:dart_console/dart_console.dart';
import 'package:lcov_parser/lcov_parser.dart';

const filePathArgumentName = 'path';
const defaultFilePath = 'coverage/lcov.info';
const filePathHelp = 'Specify the coverage file path.';

const minCoverageArgumentName = 'min-coverage';
const defaultMinCoverage = 100.00;
const minCoverageHelp = 'Enforce a minimum coverage percentage.';

const displayFilesArgumentName = 'display-files';
const defaultDisplayFiles = true;
const displayFilesHelp = 'Print coverage files';

const excludeGeneratedArgumentName = 'exclude-generated';
const defaultExcludeGenerated = false;
const excludeGeneratedHelp =
    'Exclude common generated files (e.g., .g.dart, .freezed.dart)';

const excludePathsArgumentName = 'excluded-paths';
const defaultExcludePaths = '';
const excludePathsHelp =
    'Specify paths separate by comma to exclude from coverage';

const showUncoveredArgumentName = 'show-uncovered';
const defaultShowUncovered = false;
const showUncoveredHelp = 'Display uncovered line numbers';

const baselineArgumentName = 'baseline';
const baselineHelp = 'Specify a baseline coverage file to compare with.';

const commandDescription = 'Check code coverage';
const commandName = 'check';

class CheckCoverageCommand extends Command<int> {
  CheckCoverageCommand(this.console, {CoverageService? service})
      : _service = service ?? CoverageService();

  final Console console;
  final CoverageService _service;

  @override
  String get description => commandDescription;

  @override
  String get name => commandName;

  @override
  FutureOr<int>? run() async {
    final isJson = getJsonArgument();

    try {
      final isMarkdown = getMarkdownArgument();
      final filePath = getPathArgument();
      final minCoverage = getMinCoverageArgument();
      final displayFiles = getDisplayFilesArgument();
      final excludePaths = getExcludePathsArgument();
      final excludeGenerated = getExcludeGeneratedArgument();
      final showUncovered = getShowUncoveredArgument();
      final baselinePath = getBaselineArgument();
      final failuresOnly = getFailuresOnlyArgument();

      final result = await _service.checkCoverage(
        filePath: filePath,
        minCoverage: minCoverage,
        excludePaths: excludePaths,
        excludeGenerated: excludeGenerated,
        baselinePath: baselinePath,
      );

      _displayResult(
        result,
        isJson: isJson,
        isMarkdown: isMarkdown,
        minCoverage: minCoverage,
        excludePaths: excludePaths,
        excludeGenerated: excludeGenerated,
        displayFiles: displayFiles,
        showUncovered: showUncovered,
        failuresOnly: failuresOnly,
      );

      final passedMinCoverage = result.coverage >= minCoverage;
      final passedBaseline = result.baselineCoverage == null ||
          result.coverage >= result.baselineCoverage!;

      return passedMinCoverage && passedBaseline
          ? ExitCode.success.code
          : ExitCode.fail.code;
      // ignore: avoid_catching_errors
    } on ArgumentError catch (e) {
      return _handleError(
        e.message?.toString() ?? '',
        isJson: isJson,
        code: ExitCode.usage,
      );
    } on UsageException catch (e) {
      return _handleError(e.message, isJson: isJson, code: ExitCode.usage);
    } on PathNotFoundException catch (e) {
      return _handleError(
        e.osError?.message ?? e.message,
        isJson: isJson,
        code: ExitCode.osFile,
      );
    } on FileSystemException catch (e) {
      return _handleError(e.message, isJson: isJson, code: ExitCode.osFile);
    } on FileMustBeProvided catch (e) {
      return _handleError(e.errMsg(), isJson: isJson, code: ExitCode.osFile);
    } on FormatException catch (e) {
      return _handleError(e.message, isJson: isJson, code: ExitCode.usage);
    } catch (e) {
      return _handleError(
        'An unexpected error occurred: $e',
        isJson: isJson,
        code: ExitCode.software,
      );
    }
  }

  void _displayResult(
    CoverageResult result, {
    required bool isJson,
    required bool isMarkdown,
    required double minCoverage,
    required List<String> excludePaths,
    required bool excludeGenerated,
    required bool displayFiles,
    required bool showUncovered,
    required bool failuresOnly,
  }) {
    final currentCoverage = result.coverage;

    if (isJson) {
      final jsonOutput = const JsonEncoder.withIndent('  ').convert(
        result.toJson(
          minCoverage: minCoverage,
          excludePaths: excludePaths,
          excludeGenerated: excludeGenerated,
          failuresOnly: failuresOnly,
        ),
      );
      console.writeLine(jsonOutput);
    } else if (isMarkdown) {
      _displayMarkdownResult(
        result,
        minCoverage: minCoverage,
        displayFiles: displayFiles,
        showUncovered: showUncovered,
        failuresOnly: failuresOnly,
      );
    } else {
      final color =
          currentCoverage.getCoverageColorAnsi(minCoverage: minCoverage);

      if (displayFiles) {
        final table = buildCoverageFileTable(showUncovered: showUncovered);
        for (final record in result.files) {
          if (failuresOnly && record.coveragePercentage >= minCoverage) {
            continue;
          }
          table.insertRow(
            record.toRow(
              showUncovered: showUncovered,
              minCoverage: minCoverage,
            ),
          );
        }

        console.write(table);
      }

      console
        ..writeLine('Minimum coverage: $greenColor$minCoverage%\x1B[0m')
        ..resetColorAttributes();

      if (result.baselineCoverage != null) {
        final baseline = result.baselineCoverage!;
        final delta =
            (currentCoverage - baseline).roundToDoubleWithPrecision(2);
        final deltaPrefix = delta >= 0 ? '+' : '';
        final deltaColor = delta >= 0 ? greenColor : redColor;

        console
          ..writeLine('Baseline coverage: $yellowColor$baseline%\x1B[0m')
          ..resetColorAttributes()
          ..writeLine(
            'Current coverage: $color$currentCoverage% '
            '($deltaColor$deltaPrefix$delta%)\x1B[0m',
          );
      } else {
        console.writeLine('Current coverage: $color$currentCoverage%\x1B[0m');
      }
    }
  }

  void _displayMarkdownResult(
    CoverageResult result, {
    required double minCoverage,
    required bool displayFiles,
    required bool showUncovered,
    required bool failuresOnly,
  }) {
    final currentCoverage = result.coverage;
    final emoji = currentCoverage.getCoverageEmoji(minCoverage: minCoverage);
    final progressBar =
        currentCoverage.getProgressBar(minCoverage: minCoverage);

    final buffer = StringBuffer()
      ..writeln('# $emoji Coverage Report')
      ..writeln()
      ..writeln('## Summary')
      ..writeln()
      ..writeln('- **Total Coverage:** $currentCoverage%')
      ..writeln('- **Progress:** `$progressBar`')
      ..writeln('- **Minimum Required:** $minCoverage%')
      ..writeln();

    if (result.baselineCoverage != null) {
      final baseline = result.baselineCoverage!;
      final delta = (currentCoverage - baseline).roundToDoubleWithPrecision(2);
      final deltaPrefix = delta >= 0 ? '+' : '';

      buffer
        ..writeln('## Comparison')
        ..writeln()
        ..writeln('- **Baseline:** $baseline%')
        ..writeln('- **Delta:** $deltaPrefix$delta%')
        ..writeln();
    }

    if (displayFiles) {
      buffer
        ..writeln('## Files')
        ..writeln();

      final headers = [
        'Status',
        'File name',
        'Found Lines',
        'Hit Lines',
        'Coverage',
      ];
      if (showUncovered) {
        headers.add('Uncovered Lines');
      }

      buffer
        ..writeln('| ${headers.join(' | ')} |')
        ..writeln('| ${headers.map((_) => '---').join(' | ')} |');

      for (final record in result.files) {
        if (failuresOnly && record.coveragePercentage >= minCoverage) {
          continue;
        }
        final row = record.toMarkdownRow(
          showUncovered: showUncovered,
          minCoverage: minCoverage,
        );
        buffer.writeln('| $row |');
      }
      buffer.writeln();
    }

    console.write(buffer.toString());
  }

  int _handleError(
    String message, {
    required bool isJson,
    required ExitCode code,
  }) {
    final sanitizedMessage = message.sanitize();
    if (isJson) {
      final errorJson = jsonEncode({
        'error': sanitizedMessage,
        'exit_code': code.code,
        'status': code.name,
      });
      console.writeLine(errorJson);
    } else {
      console
        ..writeErrorLine(sanitizedMessage)
        ..writeLine()
        ..writeLine(usage);
    }
    return code.code;
  }

  Table buildCoverageFileTable({bool showUncovered = false}) {
    final table = Table()
      ..insertColumn(header: 'File name')
      ..insertColumn(header: 'Found Lines', alignment: TextAlignment.center)
      ..insertColumn(header: 'Hit Lines', alignment: TextAlignment.center)
      ..insertColumn(header: 'Coverage', alignment: TextAlignment.center);

    if (showUncovered) {
      table.insertColumn(
        header: 'Uncovered Lines',
        alignment: TextAlignment.center,
      );
    }

    return table..borderColor = ConsoleColor.black;
  }

  double getMinCoverageArgument() {
    final minCoverageArg = globalResults?[minCoverageArgumentName] as String?;

    if (minCoverageArg == null || minCoverageArg.isEmpty) {
      return defaultMinCoverage;
    }

    final minCoverage = double.tryParse(minCoverageArg);

    if (minCoverage == null ||
        minCoverage.isNaN ||
        minCoverage < 0 ||
        minCoverage > 100) {
      throw UsageException(
        'Invalid value for --$minCoverageArgumentName. '
            'Expected a number between 0 and 100.',
        '--$minCoverageArgumentName $minCoverageArg',
      );
    }

    return minCoverage;
  }

  String getPathArgument() {
    return globalResults?[filePathArgumentName] as String? ?? defaultFilePath;
  }

  bool getDisplayFilesArgument() {
    return globalResults?[displayFilesArgumentName] as bool? ??
        defaultDisplayFiles;
  }

  List<String> getExcludePathsArgument() {
    final excludePathsString =
        globalResults?[excludePathsArgumentName] as String? ??
            defaultExcludePaths;

    if (excludePathsString.isEmpty) {
      return [];
    }

    return excludePathsString.split(',').map((e) => e.trim()).toList();
  }

  bool getExcludeGeneratedArgument() {
    return globalResults?[excludeGeneratedArgumentName] as bool? ??
        defaultExcludeGenerated;
  }

  bool getJsonArgument() {
    return globalResults?[jsonFlag] as bool? ?? false;
  }

  bool getMarkdownArgument() {
    return globalResults?[markdownFlag] as bool? ?? false;
  }

  bool getShowUncoveredArgument() {
    return globalResults?[showUncoveredArgumentName] as bool? ??
        defaultShowUncovered;
  }

  String? getBaselineArgument() {
    return globalResults?[baselineArgumentName] as String?;
  }

  bool getFailuresOnlyArgument() {
    return globalResults?[failuresOnlyArgumentName] as bool? ??
        defaultFailuresOnly;
  }
}

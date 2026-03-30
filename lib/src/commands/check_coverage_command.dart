import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cover/src/extensions/double_extension.dart';
import 'package:cover/src/extensions/record_extension.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:dart_console/dart_console.dart';

const filePathArgumentName = 'path';
const defaultFilePath = 'coverage/lcov.info';
const filePathHelp = 'Specify the coverage file path.';

const minCoverageArgumentName = 'min-coverage';
const defaultMinCoverage = 100.00;
const minCoverageHelp = 'Enforce a minimum coverage percentage.';

const displayFilesArgumentName = 'display-files';
const defaultDisplayFiles = true;
const displayFilesHelp = 'Print corevage files';

const excludePathsArgumentName = 'excluded-paths';
const defaultExcludePaths = '';
const excludePathsHelp =
    'Specify paths separate by comma to exclude from coverage';

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
    final filePath = getPathArgument();
    final minCoverage = getMinCoverageArgument();
    final displayFiles = getDisplayFilesArgument();
    final excludePaths = getExcludePathsArgument();

    try {
      final result = await _service.checkCoverage(
        filePath: filePath,
        minCoverage: minCoverage,
        excludePaths: excludePaths,
      );

      final table = buildCoverageFileTable();
      final currentCoverage = result.coverage;
      final color = currentCoverage.getCoverageColorAnsi();

      if (displayFiles) {
        for (final record in result.files) {
          table.insertRow(record.toRow());
        }

        console.write(table);
      }

      console
        ..writeLine('Minimun coverage: $greenColor$minCoverage%')
        ..resetColorAttributes()
        ..writeLine('Current coverage: $color$currentCoverage%');

      return currentCoverage >= minCoverage
          ? ExitCode.success.code
          : ExitCode.fail.code;
    } on FormatException catch (e) {
      throw FormatException(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Table buildCoverageFileTable() {
    return Table()
      ..insertColumn(header: 'File name')
      ..insertColumn(header: 'Found Lines', alignment: TextAlignment.center)
      ..insertColumn(header: 'Hit Lines', alignment: TextAlignment.center)
      ..insertColumn(header: 'Coverage', alignment: TextAlignment.center)
      ..borderColor = ConsoleColor.black;
  }

  double getMinCoverageArgument() {
    final minCoverageArg = globalResults?[minCoverageArgumentName] as String?;

    if (minCoverageArg == null || minCoverageArg.isEmpty) {
      return defaultMinCoverage;
    }

    final minCoverage = double.tryParse(minCoverageArg);

    if (minCoverage == null || minCoverage < 0 || minCoverage > 100) {
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
}

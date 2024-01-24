import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cover/src/extensions/double_extension.dart';
import 'package:cover/src/extensions/record_extension.dart';
import 'package:cover/src/models/exit_code.dart';
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
const displayFilesHelp = 'Print corevage files';

const excludePathsArgumentName = 'excluded-paths';
const defaultExcludePaths = '';
const excludePathsHelp =
    'Specify paths separate by comma to exclude from coverage';

const commandDescription = 'Check code coverage';
const commandName = 'check';

class CheckCoverageCommand extends Command<int> {
  CheckCoverageCommand(this.console);

  final Console console;

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
    final records = await parseCoverageFile(filePath, excludePaths);
    final table = buildCoverageFileTable();

    if (records.isEmpty) {
      throw const FormatException(
        'File is empty or does not have the correct format',
      );
    }

    final currentCoverage = records.getCodeCoverageResult();
    final color = currentCoverage.getCoverageColorAnsi();

    if (displayFiles) {
      for (final record in records) {
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
  }

  Table buildCoverageFileTable() {
    return Table()
      ..insertColumn(header: 'File name')
      ..insertColumn(header: 'Found Lines', alignment: TextAlignment.center)
      ..insertColumn(header: 'Hit Lines', alignment: TextAlignment.center)
      ..insertColumn(header: 'Coverage', alignment: TextAlignment.center)
      ..borderColor = ConsoleColor.black;
  }

  Future<List<Record>> parseCoverageFile(
    String filePath,
    List<String> excludedPaths,
  ) async {
    final files = await Parser.parse(filePath);

    if (excludedPaths.isEmpty) {
      return files;
    }

    for (final excludedPath in excludedPaths) {
      final excludePattern = RegExp(excludedPath);
      files.removeWhere((record) => excludePattern.hasMatch(record.file ?? ''));
    }

    return files.toList();
  }

  double getMinCoverageArgument() {
    final minCoverage =
        globalResults?[minCoverageArgumentName] as String? ?? '';
    return double.tryParse(minCoverage) ?? defaultMinCoverage;
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

    return excludePathsString
        .split(',')
        .map((e) => e.replaceAll(' ', ''))
        .toList();
  }
}

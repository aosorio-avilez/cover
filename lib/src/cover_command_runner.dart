import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cover/src/commands/check_coverage_command.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:lcov_parser/lcov_parser.dart';

const executableName = 'cover';
const description = 'The easy way to check code coverage';

class CoverCommandRunner extends CompletionCommandRunner<int> {
  CoverCommandRunner({Console? console})
      : _console = console ?? Console(),
        super(executableName, description) {
    argParser
      ..addOption(
        filePathArgumentName,
        defaultsTo: defaultFilePath,
        help: filePathHelp,
      )
      ..addOption(
        minCoverageArgumentName,
        defaultsTo: '$defaultMinCoverage',
        help: minCoverageHelp,
      );

    addCommand(CheckCoverageCommand(_console));
  }

  final Console _console;

  @override
  Future<int?> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      return await runCommand(topLevelResults);
    } on UsageException catch (e, stackTrace) {
      _console
        ..writeErrorLine(e.message)
        ..writeErrorLine('$stackTrace')
        ..writeLine()
        ..writeLine(e.usage);
      return ExitCode.usage.code;
    } on FormatException catch (e, stackTrace) {
      _console
        ..writeErrorLine(e.message)
        ..writeErrorLine('$stackTrace')
        ..writeLine();
      return ExitCode.usage.code;
    } on PathNotFoundException catch (e, stackTrace) {
      _console
        ..writeErrorLine(e.message)
        ..writeErrorLine('$stackTrace')
        ..writeLine();
      return ExitCode.osFile.code;
    } on FileMustBeProvided catch (e, stackTrace) {
      _console
        ..writeErrorLine(e.errMsg())
        ..writeErrorLine('$stackTrace')
        ..writeLine();
      return ExitCode.osFile.code;
    }
  }
}

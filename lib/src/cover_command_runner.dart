import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cover/src/commands/check_coverage_command.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:dart_console/dart_console.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

const executableName = 'cover';
const description = 'The easy way to check code coverage';
const versionFlag = 'version';
const versionDescription = 'Print the current version.';

class CoverCommandRunner extends CompletionCommandRunner<int> {
  CoverCommandRunner({Console? console, CoverageService? service})
      : _console = console ?? Console(),
        super(executableName, description) {
    final coverageService = service ?? CoverageService();
    argParser
      ..addFlag(
        versionFlag,
        abbr: 'v',
        negatable: false,
        help: versionDescription,
      )
      ..addFlag(
        displayFilesArgumentName,
        abbr: 'd',
        help: displayFilesHelp,
        defaultsTo: defaultDisplayFiles,
      )
      ..addOption(
        filePathArgumentName,
        defaultsTo: defaultFilePath,
        help: filePathHelp,
        abbr: 'p',
      )
      ..addOption(
        minCoverageArgumentName,
        defaultsTo: '$defaultMinCoverage',
        help: minCoverageHelp,
        abbr: 'm',
      )
      ..addOption(
        excludePathsArgumentName,
        defaultsTo: defaultExcludePaths,
        help: excludePathsHelp,
        abbr: 'e',
      );

    addCommand(CheckCoverageCommand(_console, service: coverageService));
  }

  final Console _console;

  @override
  Future<int?> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);
      return await runCommand(topLevelResults);
    } on UsageException catch (e) {
      printError(e.message);
      return ExitCode.usage.code;
    } on FormatException catch (e) {
      printError(e.message);
      return ExitCode.usage.code;
    } on PathNotFoundException catch (e) {
      printError(e.osError?.message ?? e.message);
      return ExitCode.osFile.code;
    } on FileMustBeProvided catch (e) {
      printError(e.errMsg());
      return ExitCode.osFile.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      final version = await getVersion();
      _console.writeLine(version);
      return ExitCode.success.code;
    }

    return super.runCommand(topLevelResults);
  }

  void printError(String message) {
    _console
      ..writeErrorLine(message)
      ..writeLine()
      ..writeLine(usage);
  }

  Future<String> getVersion() async {
    final packageUri = Uri.parse('package:cover/');
    final resolvedUri = await Isolate.resolvePackageUri(packageUri);

    if (resolvedUri == null) {
      throw StateError('Could not resolve package URI for package:cover');
    }

    final pubspecUri = resolvedUri.resolve('../pubspec.yaml');
    final fileContent = await File.fromUri(pubspecUri).readAsString();
    final pubspec = Pubspec.parse(fileContent);
    return pubspec.version!.toString();
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cover/src/commands/check_coverage_command.dart';
import 'package:cover/src/extensions/string_extension.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:cover/src/services/coverage_service.dart';
import 'package:dart_console/dart_console.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

const executableName = 'cover';
const description = 'The easy way to check code coverage';
const versionFlag = 'version';
const versionDescription = 'Print the current version.';
const jsonFlag = 'json';
const jsonDescription = 'Output the result in JSON format.';

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
        jsonFlag,
        abbr: 'j',
        negatable: false,
        help: jsonDescription,
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
      )
      ..addFlag(
        excludeGeneratedArgumentName,
        help: excludeGeneratedHelp,
      )
      ..addFlag(
        showUncoveredArgumentName,
        abbr: 'u',
        help: showUncoveredHelp,
      );

    addCommand(CheckCoverageCommand(_console, service: coverageService));
  }

  final Console _console;

  @override
  Future<int?> run(Iterable<String> args) async {
    var isJson = args.contains('--$jsonFlag') || args.contains('-j');

    try {
      final topLevelResults = parse(args);
      isJson = topLevelResults[jsonFlag] == true;
      final exitCode = await runCommand(topLevelResults);
      if (exitCode == null && !topLevelResults.wasParsed('help')) {
        printError('Missing subcommand.', isJson: isJson);
        return ExitCode.usage.code;
      }
      return exitCode;
    } on UsageException catch (e) {
      printError(e.message, isJson: isJson);
      return ExitCode.usage.code;
    } on FormatException catch (e) {
      printError(e.message, isJson: isJson);
      return ExitCode.usage.code;
    } on PathNotFoundException catch (e) {
      printError(
        e.osError?.message ?? e.message,
        isJson: isJson,
        code: ExitCode.osFile,
      );
      return ExitCode.osFile.code;
    } on FileSystemException catch (e) {
      printError(
        e.message,
        isJson: isJson,
        code: ExitCode.osFile,
      );
      return ExitCode.osFile.code;
    } on FileMustBeProvided catch (e) {
      printError(
        e.errMsg(),
        isJson: isJson,
        code: ExitCode.osFile,
      );
      return ExitCode.osFile.code;
    } catch (e) {
      final message = 'An unexpected error occurred: $e';
      if (isJson) {
        _console.writeLine(_formatJsonError(message.sanitize(), ExitCode.software));
      } else {
        _console.writeErrorLine(message.sanitize());
      }
      return ExitCode.software.code;
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

  void printError(
    String message, {
    bool isJson = false,
    ExitCode code = ExitCode.usage,
  }) {
    final sanitizedMessage = message.sanitize();
    if (isJson) {
      _console.writeLine(_formatJsonError(sanitizedMessage, code));
    } else {
      _console
        ..writeErrorLine(sanitizedMessage)
        ..writeLine()
        ..writeLine(usage);
    }
  }

  String _formatJsonError(String message, ExitCode code) {
    return jsonEncode({
      'error': message,
      'exit_code': code.code,
      'status': code.name,
    });
  }

  Future<String> getVersion() async {
    try {
      final packageUri = Uri.parse('package:cover/');
      final packagePath = await Isolate.resolvePackageUri(packageUri);
      if (packagePath == null) return 'unknown';

      final pubspecPath = packagePath.resolve('../pubspec.yaml');
      final pubspecFile = File.fromUri(pubspecPath);
      if (!pubspecFile.existsSync()) return 'unknown';

      final fileContent = pubspecFile.readAsStringSync();
      final pubspec = Pubspec.parse(fileContent);
      return pubspec.version?.toString() ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }
}

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cover/src/cover_command_runner.dart';
import 'package:cover/src/models/exit_code.dart';
import 'package:dart_console/dart_console.dart';
import 'package:lcov_parser/lcov_parser.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks/console_mock.dart';

class ExceptionThrowingCommand extends Command<int> {
  ExceptionThrowingCommand(this.exception);

  final Object exception;

  @override
  String get description => 'Throws an exception';

  @override
  String get name => 'throw';

  @override
  Future<int> run() async {
    final exc = exception;
    if (exc is Exception) {
      throw exc;
    }
    if (exc is Error) {
      throw exc;
    }
    throw Exception(exc.toString());
  }
}

void main() {
  late Console console;
  late CoverCommandRunner runner;

  setUp(() {
    console = ConsoleMock();
    runner = CoverCommandRunner(console: console);
  });

  group('CoverCommandRunner Exception Coverage', () {
    test('handles PathNotFoundException', () async {
      runner.addCommand(
        ExceptionThrowingCommand(
          const PathNotFoundException('path', OSError('msg', 2)),
        ),
      );
      final exitCode = await runner.run(['throw']);
      expect(exitCode, ExitCode.osFile.code);
      verify(() => console.writeErrorLine(any())).called(1);
    });

    test('handles FileSystemException', () async {
      runner.addCommand(
        ExceptionThrowingCommand(const FileSystemException('msg')),
      );
      final exitCode = await runner.run(['throw']);
      expect(exitCode, ExitCode.osFile.code);
      verify(() => console.writeErrorLine(any())).called(1);
    });

    test('handles FileMustBeProvided', () async {
      runner.addCommand(ExceptionThrowingCommand(FileMustBeProvided()));
      final exitCode = await runner.run(['throw']);
      expect(exitCode, ExitCode.osFile.code);
      verify(() => console.writeErrorLine(any())).called(1);
    });

    test('handles FormatException in runner.run', () async {
      runner.addCommand(ExceptionThrowingCommand(const FormatException('msg')));
      final exitCode = await runner.run(['throw']);
      expect(exitCode, ExitCode.usage.code);
      verify(() => console.writeErrorLine(any())).called(1);
    });
  });
}

import 'dart:io';

import 'package:cover/src/cover_command_runner.dart';

Future<void> main(List<String> args) async {
  await _flushThenExit(await CoverCommandRunner().run(args));
}

Future<void> _flushThenExit(int? status) {
  return Future.wait<void>([stdout.close(), stderr.close()])
      .then<void>((_) => exit(status ?? 1));
}

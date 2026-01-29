import 'dart:io';

import 'package:cover/cover.dart';

void main() async {
  // Initialize the CommandRunner
  final runner = CoverCommandRunner();

  // Simulate command line arguments
  final args = ['check', '--path', 'params/lcov.info'];

  // Run the command
  final exitCode = await runner.run(args);

  exit(exitCode ?? 1);
}

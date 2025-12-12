import 'dart:io';

import 'package:cover/cover.dart';

void main() async {
  print('Running cover example via CommandRunner...');

  // Initialize the CommandRunner
  final runner = CoverCommandRunner();

  // Simulate command line arguments
  final args = [
    'check',
    '--path',
    'params/lcov.info',
  ];

  print('Executing command: cover ${args.join(' ')}');

  // Run the command
  final exitCode = await runner.run(args);

  exit(exitCode ?? 1);
}

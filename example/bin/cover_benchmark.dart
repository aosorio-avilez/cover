import 'dart:io';

import 'package:cover/cover.dart';

void main() async {
  final stopwatch = Stopwatch()..start();

  // Initialize the CommandRunner
  final runner = CoverCommandRunner();

  // Path to the large benchmark file
  const benchmarkPath = 'params/benchmark_lcov.info';

  if (!File(benchmarkPath).existsSync()) {
    // ignore: avoid_print
    print('''
Benchmark file not found. Please run generate_lcov_benchmark.dart first.''');
    exit(1);
  }

  // Simulate command line arguments
  final args = ['check', '--path', benchmarkPath, '--no-display-files'];

  // ignore: avoid_print
  print('Starting benchmark with 10,000 files...');

  // Run the command
  final exitCode = await runner.run(args);

  stopwatch.stop();
  // ignore: avoid_print
  print('-----------------------------------------');
  // ignore: avoid_print
  print('Benchmark completed in ${stopwatch.elapsedMilliseconds}ms');
  // ignore: avoid_print
  print('Exit code: $exitCode');

  exit(exitCode ?? 1);
}

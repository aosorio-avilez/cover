import 'dart:io';

void main() {
  final output = File('params/benchmark_lcov.info');

  // Ensure parent directory exists
  if (!output.parent.existsSync()) {
    output.parent.createSync(recursive: true);
  }

  final sink = output.openWrite();

  const numFiles = 10000;
  const linesPerFile = 10;

  // ignore: avoid_print
  print('Generating $numFiles files in benchmark_lcov.info...');

  for (var i = 1; i <= numFiles; i++) {
    sink.writeln('SF:/virtual/project/lib/src/generated_file_$i.dart');

    // Generate some random-ish coverage
    for (var j = 1; j <= linesPerFile; j++) {
      final hits = (i + j).isEven ? 1 : 0;
      sink.writeln('DA:$j,$hits');
    }

    final hitCount = (linesPerFile / 2).floor() + (i.isEven ? 1 : 0);
    sink
      ..writeln('LF:$linesPerFile')
      ..writeln('LH:$hitCount')
      ..writeln('end_of_record');
  }

  sink.close();
  // ignore: avoid_print
  print('Done! Benchmark file generated at ${output.path}');
}

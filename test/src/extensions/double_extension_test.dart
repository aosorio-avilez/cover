import 'package:cover/src/extensions/double_extension.dart';
import 'package:test/test.dart';

void main() {
  test('verify getCoverageColorAnsi return pass color', () async {
    const coverage = 100.0;
    expect(coverage.getCoverageColorAnsi(), greenColor);
  });

  test('verify getCoverageColorAnsi return underThresholdColor color',
      () async {
    const coverage = 80.0;
    expect(coverage.getCoverageColorAnsi(), yellowColor);
  });

  test('verify getCoverageColorAnsi return fail color', () async {
    const coverage = 50.0;
    expect(coverage.getCoverageColorAnsi(), redColor);
  });
}

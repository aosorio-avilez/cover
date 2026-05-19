import 'package:cover/src/extensions/double_extension.dart';
import 'package:test/test.dart';

void main() {
  test('verify getCoverageColorAnsi return pass color', () async {
    const coverage = 100.0;
    expect(coverage.getCoverageColorAnsi(), greenColor);
  });

  test(
    'verify getCoverageColorAnsi return underThresholdColor color',
    () async {
      const coverage = 80.0;
      expect(coverage.getCoverageColorAnsi(), yellowColor);
    },
  );

  test('verify getCoverageColorAnsi return fail color', () async {
    const coverage = 50.0;
    expect(coverage.getCoverageColorAnsi(), redColor);
  });

  group('threshold-aware coloring', () {
    test('returns greenColor if coverage meets custom threshold', () {
      const coverage = 85.0;
      expect(
        coverage.getCoverageColorAnsi(minCoverage: 80),
        greenColor,
      );
    });

    test('returns yellowColor if coverage is close to custom threshold', () {
      const coverage = 70.0;
      expect(
        coverage.getCoverageColorAnsi(minCoverage: 80),
        yellowColor,
      );
    });

    test('returns redColor if coverage is significantly below custom threshold',
        () {
      const coverage = 50.0;
      expect(
        coverage.getCoverageColorAnsi(minCoverage: 80),
        redColor,
      );
    });
  });
}

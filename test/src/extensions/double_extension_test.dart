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

  group('getCoverageEmoji', () {
    test(
        'returns 🟢 for 100% coverage and 🔴 for 50% coverage with 100% threshold',
        () {
      expect(100.0.getCoverageEmoji(), '🟢');
      expect(50.0.getCoverageEmoji(), '🔴');
    });

    test('returns 🟡 for 85% coverage with 100% threshold', () {
      expect(85.0.getCoverageEmoji(), '🟡');
    });
  });

  group('getProgressBar', () {
    test('returns 10 green squares for 100%', () {
      expect(100.0.getProgressBar(), '🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩');
    });

    test('returns 10 white squares for 0%', () {
      expect(0.0.getProgressBar(), '⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜');
    });

    test(
        'returns 5 yellow squares and 5 white squares for 55% with 60% threshold',
        () {
      // 55% coverage against 60% threshold is yellow (55 >= 60*0.8=48)
      expect(55.0.getProgressBar(minCoverage: 60), '🟨🟨🟨🟨🟨⬜⬜⬜⬜⬜');
    });
  });
}

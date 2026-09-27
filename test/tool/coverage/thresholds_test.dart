import 'package:flutter_test/flutter_test.dart';

import '../../../tool/coverage/src/lcov.dart';
import '../../../tool/coverage/src/thresholds.dart';

const _domain = 'lib/features/steps/domain/xp.dart';
const _data = 'lib/features/steps/data/steps_repository.dart';
const _core = 'lib/core/time/dates.dart';

LayerResult _layer(CoverageReport report, String name) =>
    report.layers.singleWhere((layer) => layer.name == name);

CoverageReport _evaluate(Map<String, FileCoverage> coverage) =>
    evaluate(coverage: coverage, candidates: coverage.keys.toList());

void main() {
  group('evaluate', () {
    test('passes domain at exactly 100%', () {
      final report = _evaluate({_domain: (linesFound: 4, linesHit: 4)});

      expect(_layer(report, 'domain').passed, isTrue);
    });

    test('fails domain below 100%', () {
      final report = _evaluate({_domain: (linesFound: 200, linesHit: 199)});

      expect(_layer(report, 'domain').passed, isFalse);
      expect(report.filesBelowThreshold.map((f) => f.$1), [_domain]);
      expect(report.passed, isFalse);
    });

    test('passes data at exactly 85%', () {
      final report = _evaluate({_data: (linesFound: 20, linesHit: 17)});

      expect(_layer(report, 'data').passed, isTrue);
    });

    test('fails data just below 85%', () {
      final report = _evaluate({_data: (linesFound: 1000, linesHit: 849)});

      expect(_layer(report, 'data').passed, isFalse);
    });

    test('treats a layer without lines as n/a and passing', () {
      final report = _evaluate({_domain: (linesFound: 1, linesHit: 1)});

      final data = _layer(report, 'data');
      expect(data.isEmpty, isTrue);
      expect(data.passed, isTrue);
    });

    test('fails when a candidate is missing from lcov', () {
      final report = evaluate(coverage: {}, candidates: [_domain]);

      expect(report.missingFiles, [_domain]);
      expect(report.passed, isFalse);
    });

    test('fails overall below 85% even when every layer passes', () {
      final report = _evaluate({
        _domain: (linesFound: 10, linesHit: 10),
        _core: (linesFound: 90, linesHit: 60),
      });

      expect(report.layers.every((layer) => layer.passed), isTrue);
      expect(report.overall.linesHit, 70);
      expect(report.overall.linesFound, 100);
      expect(report.overall.passed, isFalse);
      expect(report.passed, isFalse);
    });

    test('ignores lcov entries that are not candidates', () {
      final report = evaluate(
        coverage: {
          'lib/features/steps/domain/old.dart': (linesFound: 10, linesHit: 0),
        },
        candidates: [],
      );

      expect(_layer(report, 'domain').isEmpty, isTrue);
      expect(report.passed, isTrue);
    });

    test('passes when nothing is measurable', () {
      final report = evaluate(coverage: {}, candidates: []);

      expect(report.layers.every((layer) => layer.isEmpty), isTrue);
      expect(report.overall.isEmpty, isTrue);
      expect(report.passed, isTrue);
    });
  });
}

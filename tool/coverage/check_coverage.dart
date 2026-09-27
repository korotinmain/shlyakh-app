// Checks line coverage against the floors in docs/AGENT_RULES.md 8.5.
//
// Usage: flutter test --coverage && dart run tool/coverage/check_coverage.dart
// Exit codes: 0 pass, 1 threshold or missing-file failure, 2 no lcov file.
import 'dart:io';

import 'src/layers.dart';
import 'src/lcov.dart';
import 'src/thresholds.dart';

Future<void> main(List<String> args) async {
  final lcovPath = args.firstOrNull ?? 'coverage/lcov.info';
  final lcovFile = File(lcovPath);
  if (!lcovFile.existsSync()) {
    stderr.writeln(
      'No coverage file at $lcovPath. Run: flutter test --coverage',
    );
    exitCode = 2;
    return;
  }

  final report = evaluate(
    coverage: parseLcov(await lcovFile.readAsString()),
    candidates: await _measuredCandidates(),
  );

  report.layers.forEach(_printLayer);
  _printLayer(report.overall);

  if (report.filesBelowThreshold.isNotEmpty) {
    stdout.writeln('\nBelow threshold:');
    for (final (path, coverage) in report.filesBelowThreshold) {
      stdout.writeln(
        '  $path  ${_percent(coverage.linesHit, coverage.linesFound)}',
      );
    }
  }
  if (report.missingFiles.isNotEmpty) {
    stdout.writeln('\nNot loaded by any test:');
    for (final path in report.missingFiles) {
      stdout.writeln('  $path');
    }
  }

  stdout.writeln(
    report.passed ? '\nCoverage check passed.' : '\nCoverage check FAILED.',
  );
  exitCode = report.passed ? 0 : 1;
}

/// All `lib/**.dart` files that are measured: not excluded by path and not
/// opted out with `// coverage:ignore-file`.
Future<List<String>> _measuredCandidates() async {
  final candidates = <String>[];
  await for (final entity in Directory('lib').list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (classify(path) == Layer.excluded) continue;
    if (hasIgnoreFileComment(await entity.readAsString())) continue;
    candidates.add(path);
  }
  return candidates;
}

void _printLayer(LayerResult layer) {
  final lines = layer.isEmpty
      ? 'n/a'.padLeft(9)
      : '${layer.linesHit}/${layer.linesFound}'.padLeft(9);
  final percent = layer.isEmpty
      ? ''.padLeft(6)
      : _percent(layer.linesHit, layer.linesFound).padLeft(6);
  final threshold = layer.threshold == null
      ? '(no min)'
      : '(min ${layer.threshold}%)';
  stdout.writeln(
    '${layer.name.padRight(18)} ${'${layer.fileCount}'.padLeft(3)} files'
    '  $lines  $percent  ${threshold.padRight(10)}  '
    '${layer.passed ? 'OK' : 'FAIL'}',
  );
}

String _percent(int hit, int found) =>
    found == 0 ? 'n/a' : '${(hit * 100 / found).toStringAsFixed(1)}%';

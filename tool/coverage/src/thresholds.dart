import 'layers.dart';
import 'lcov.dart';

/// Minimum line coverage per layer, in percent (docs/AGENT_RULES.md 8.5).
const Map<Layer, int> layerThresholds = {
  Layer.domain: 100,
  Layer.data: 85,
  Layer.presentationLogic: 85,
};

/// Minimum line coverage of all measured layers together, in percent.
const overallThreshold = 85;

const List<Layer> _measuredLayers = [
  Layer.domain,
  Layer.data,
  Layer.presentationLogic,
  Layer.core,
];

bool _meets(int linesHit, int linesFound, int? threshold) =>
    threshold == null ||
    linesFound == 0 ||
    linesHit * 100 >= threshold * linesFound;

/// Aggregated coverage of one layer (or of all measured layers).
class LayerResult {
  const new({
    required this.name,
    required this.fileCount,
    required this.linesFound,
    required this.linesHit,
    required this.threshold,
  });

  final String name;
  final int fileCount;
  final int linesFound;
  final int linesHit;

  /// Minimum percentage, or null when the layer has no own threshold.
  final int? threshold;

  /// No executable lines: reported as n/a and always passing.
  bool get isEmpty => linesFound == 0;

  bool get passed => _meets(linesHit, linesFound, threshold);
}

class CoverageReport {
  const new({
    required this.layers,
    required this.overall,
    required this.missingFiles,
    required this.filesBelowThreshold,
  });

  /// Domain, data, presentation logic and core, in that order.
  final List<LayerResult> layers;
  final LayerResult overall;

  /// Measured files that no test loaded (absent from lcov), sorted.
  final List<String> missingFiles;

  /// Files in a thresholded layer whose own coverage is below it, sorted.
  final List<(String path, FileCoverage coverage)> filesBelowThreshold;

  bool get passed =>
      layers.every((layer) => layer.passed) &&
      overall.passed &&
      missingFiles.isEmpty;
}

/// Evaluates [coverage] for [candidates], the measured source files.
///
/// Only candidates count: lcov entries for other files (deleted, excluded)
/// are ignored, and candidates absent from [coverage] are reported missing.
CoverageReport evaluate({
  required Map<String, FileCoverage> coverage,
  required List<String> candidates,
}) {
  final filesByLayer = {for (final layer in _measuredLayers) layer: <String>[]};
  final missing = <String>[];
  final below = <(String, FileCoverage)>[];

  for (final path in candidates) {
    final layer = classify(path);
    final fileCoverage = coverage[path];
    if (!_measuredLayers.contains(layer)) continue;
    if (fileCoverage == null) {
      missing.add(path);
      continue;
    }
    filesByLayer[layer]!.add(path);
    final threshold = layerThresholds[layer];
    if (!_meets(fileCoverage.linesHit, fileCoverage.linesFound, threshold)) {
      below.add((path, fileCoverage));
    }
  }

  LayerResult sum(String name, Iterable<String> files, int? threshold) {
    var found = 0;
    var hit = 0;
    for (final path in files) {
      found += coverage[path]!.linesFound;
      hit += coverage[path]!.linesHit;
    }
    return LayerResult(
      name: name,
      fileCount: files.length,
      linesFound: found,
      linesHit: hit,
      threshold: threshold,
    );
  }

  return CoverageReport(
    layers: [
      for (final layer in _measuredLayers)
        sum(layer.name, filesByLayer[layer]!, layerThresholds[layer]),
    ],
    overall: sum(
      'overall',
      filesByLayer.values.expand((files) => files),
      overallThreshold,
    ),
    missingFiles: missing..sort(),
    filesBelowThreshold: below..sort((a, b) => a.$1.compareTo(b.$1)),
  );
}

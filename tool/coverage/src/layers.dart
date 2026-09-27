/// Architectural layer a source file belongs to, for coverage thresholds.
enum Layer { domain, data, presentationLogic, core, excluded }

/// Classifies a package-relative path (`lib/...`) into a [Layer].
///
/// Rules are checked top to bottom and the first match wins, so generated
/// files are excluded even inside `domain/` or `data/`. See
/// docs/superpowers/specs/2026-09-27-coverage-thresholds-design.md.
Layer classify(String path) {
  if (path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.startsWith('lib/l10n/') ||
      path == 'lib/main.dart' ||
      path.startsWith('lib/app/')) {
    return Layer.excluded;
  }

  // lib/features/<feature>/<layer>/...
  final segments = path.split('/');
  if (segments.length > 3 && segments[1] == 'features') {
    return switch (segments[3]) {
      'domain' => Layer.domain,
      'data' => Layer.data,
      'presentation' when segments.length > 4 && segments[4] == 'providers' =>
        Layer.presentationLogic,
      'presentation' => Layer.excluded,
      _ => Layer.core,
    };
  }

  return Layer.core;
}

/// Whether [source] opts out of coverage with a `// coverage:ignore-file`
/// line comment, optionally followed by a reason.
bool hasIgnoreFileComment(String source) {
  const marker = '// coverage:ignore-file';
  return source
      .split('\n')
      .map((line) => line.trim())
      .any((line) => line == marker || line.startsWith('$marker '));
}

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

/// The rule `flutter test --coverage` uses to omit a file (package:coverage).
final _ignoreFile = RegExp(
  r'//\s*coverage:ignore-file[\w\d\s]*$',
  multiLine: true,
);

/// Whether [source] opts out of coverage with `// coverage:ignore-file`,
/// exactly as `flutter test --coverage` decides it.
bool hasIgnoreFileComment(String source) => _ignoreFile.hasMatch(source);

final _comments = RegExp(r'//[^\n]*|/\*[\s\S]*?\*/');
final _strings = RegExp(
  r"'(?:\\.|[^'\\\n])*'|"
  r'"(?:\\.|[^"\\\n])*"',
);
final _body = RegExp(r'=>|\)\s*(?:async\*?|sync\*)?\s*\{');

/// Whether [source] has function, method or getter bodies.
///
/// Files with only declarations (interfaces, enums, constants, typedefs,
/// const constructors) get no lcov record even when a test loads them, so
/// their absence from lcov is not a missing test. A heuristic: looks for
/// `=>` or `) {` outside comments and string literals.
bool hasExecutableCode(String source) {
  final code = source.replaceAll(_comments, '').replaceAll(_strings, "''");
  return _body.hasMatch(code);
}

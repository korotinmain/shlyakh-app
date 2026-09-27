// Enforces docs/decisions/0006-logging.md mechanically, so the "log only
// through AppLogger with events from one file" rule does not depend on
// review alone.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _logger = 'lib/core/logging/app_logger.dart';
const _events = 'lib/core/logging/log_events.dart';

final _generated = RegExp(r'\.(g|freezed)\.dart$|^lib/l10n/app_localizations');

Map<String, String> _libSources() => {
  for (final file in Directory('lib').listSync(recursive: true))
    if (file is File && file.path.endsWith('.dart'))
      if (!_generated.hasMatch(file.path.replaceAll(r'\', '/')))
        file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
};

List<String> _offenders(bool Function(String path, String source) breaks) => [
  for (final MapEntry(key: path, value: source) in _libSources().entries)
    if (breaks(path, source)) path,
]..sort();

void main() {
  test('nothing calls debugPrint', () {
    expect(_offenders((_, source) => source.contains('debugPrint(')), isEmpty);
  });

  test('only the logger imports dart:developer', () {
    expect(
      _offenders(
        (path, source) =>
            path != _logger && source.contains("import 'dart:developer'"),
      ),
      isEmpty,
    );
  });

  test('log events are declared only in log_events.dart', () {
    final declaresEvent = RegExp(r'(extends|implements)\s+LogEvent\b');

    expect(
      _offenders(
        (path, source) => path != _events && declaresEvent.hasMatch(source),
      ),
      isEmpty,
    );
  });

  test('event names are plain literals without interpolation', () {
    final interpolatedName = RegExp(r"get name\s*=>\s*'[^']*\$");

    expect(
      _offenders(
        (path, source) => path == _events && interpolatedName.hasMatch(source),
      ),
      isEmpty,
    );
  });
}

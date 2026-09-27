/// Line coverage of one source file. A record, so equality is by value.
typedef FileCoverage = ({int linesFound, int linesHit});

/// Parses an lcov tracefile into per-file line coverage.
///
/// Counts come from `DA:<line>,<count>` records; `LF`/`LH` are optional in
/// the format and ignored. Several records for the same file are merged:
/// a line is hit if any record hits it.
Map<String, FileCoverage> parseLcov(String content) {
  final linesByFile = <String, Map<int, bool>>{};
  Map<int, bool>? current;

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trimRight();
    if (line.startsWith('SF:')) {
      current = linesByFile.putIfAbsent(line.substring(3), () => {});
    } else if (line.startsWith('DA:') && current != null) {
      final fields = line.substring(3).split(',');
      final lineNumber = int.parse(fields[0]);
      final hit = int.parse(fields[1]) > 0;
      current[lineNumber] = (current[lineNumber] ?? false) || hit;
    } else if (line == 'end_of_record') {
      current = null;
    }
  }

  return {
    for (final MapEntry(key: path, value: lines) in linesByFile.entries)
      path: (
        linesFound: lines.length,
        linesHit: lines.values.where((hit) => hit).length,
      ),
  };
}

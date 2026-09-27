import 'package:flutter_test/flutter_test.dart';

import '../../../tool/coverage/src/lcov.dart';

void main() {
  group('parseLcov', () {
    const singleFile = 'SF:lib/a.dart\nDA:1,1\nDA:2,0\nDA:3,5\nend_of_record\n';

    test('counts found and hit lines from DA records', () {
      expect(parseLcov(singleFile), {
        'lib/a.dart': (linesFound: 3, linesHit: 2),
      });
    });

    test('parses several files', () {
      const content =
          'SF:lib/a.dart\nDA:1,1\nend_of_record\n'
          'SF:lib/b.dart\nDA:1,0\nDA:2,0\nend_of_record\n';

      expect(parseLcov(content), {
        'lib/a.dart': (linesFound: 1, linesHit: 1),
        'lib/b.dart': (linesFound: 2, linesHit: 0),
      });
    });

    test('ignores LF and LH in favour of DA', () {
      const content =
          'SF:lib/a.dart\nDA:1,1\nDA:2,0\nLF:10\nLH:10\nend_of_record\n';

      expect(parseLcov(content), {'lib/a.dart': (linesFound: 2, linesHit: 1)});
    });

    test('merges duplicate records for the same file', () {
      const content =
          'SF:lib/a.dart\nDA:1,1\nDA:2,0\nend_of_record\n'
          'SF:lib/a.dart\nDA:2,3\nDA:3,0\nend_of_record\n';

      expect(parseLcov(content), {'lib/a.dart': (linesFound: 3, linesHit: 2)});
    });

    test('handles CRLF line endings', () {
      expect(parseLcov(singleFile.replaceAll('\n', '\r\n')), {
        'lib/a.dart': (linesFound: 3, linesHit: 2),
      });
    });

    test('returns an empty map for empty input', () {
      expect(parseLcov(''), isEmpty);
    });
  });
}

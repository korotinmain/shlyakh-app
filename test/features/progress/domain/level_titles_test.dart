import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/progress/domain/level_titles.dart';

void main() {
  group('chapterOf', () {
    final cases = <(int level, int chapter)>[
      (1, 1),
      (5, 1),
      (6, 2),
      (10, 2),
      (11, 3),
      (16, 4),
      (21, 5),
      (25, 5),
      (26, 5),
      (400, 5),
    ];
    for (final (level, chapter) in cases) {
      test('puts level $level in chapter $chapter', () {
        expect(chapterOf(level), chapter);
      });
    }

    test('rejects level 0', () {
      expect(() => chapterOf(0), throwsArgumentError);
    });
  });

  group('continuationDegree', () {
    final cases = <(int level, int? degree)>[
      (1, null),
      (25, null),
      (26, 2),
      (27, 3),
      (100, 76),
    ];
    for (final (level, degree) in cases) {
      test('gives $degree for level $level', () {
        expect(continuationDegree(level), degree);
      });
    }

    test('rejects level 0', () {
      expect(() => continuationDegree(0), throwsArgumentError);
    });
  });
}

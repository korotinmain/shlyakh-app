import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/progress/domain/level_curve.dart';

void main() {
  group('xpToReachLevel', () {
    // The Levels table of docs/superpowers/specs/2026-09-27-xp-rules-design.md.
    final table = <(int level, int xp)>[
      (1, 0),
      (2, 1700),
      (3, 6900),
      (4, 15600),
      (5, 27800),
      (6, 43400),
      (7, 62500),
      (8, 85100),
      (9, 111100),
      (10, 140600),
      (11, 173600),
      (12, 210100),
      (13, 250000),
      (14, 293400),
      (15, 340300),
      (16, 390600),
      (17, 444400),
      (18, 501700),
      (19, 562500),
      (20, 626700),
      (21, 694400),
      (22, 765600),
      (23, 840300),
      (24, 918400),
      (25, 1000000),
      (26, 1081600),
      (27, 1163200),
    ];
    for (final (level, xp) in table) {
      test('level $level needs $xp XP', () {
        expect(xpToReachLevel(level), xp);
      });
    }

    test('rejects level 0', () {
      expect(() => xpToReachLevel(0), throwsArgumentError);
    });

    test('computes a far continuation level', () {
      expect(xpToReachLevel(100), 7120000);
    });

    test('thresholds strictly increase', () {
      for (var level = 2; level <= 60; level++) {
        expect(
          xpToReachLevel(level),
          greaterThan(xpToReachLevel(level - 1)),
          reason: 'level=$level',
        );
      }
    });
  });

  group('levelProgress', () {
    final cases = <(int totalXp, LevelProgress progress)>[
      (0, (level: 1, xpIntoLevel: 0, xpForNextLevel: 1700)),
      (1699, (level: 1, xpIntoLevel: 1699, xpForNextLevel: 1700)),
      (1700, (level: 2, xpIntoLevel: 0, xpForNextLevel: 5200)),
      (999999, (level: 24, xpIntoLevel: 81599, xpForNextLevel: 81600)),
      (1000000, (level: 25, xpIntoLevel: 0, xpForNextLevel: 81600)),
      (1081599, (level: 25, xpIntoLevel: 81599, xpForNextLevel: 81600)),
      (1081600, (level: 26, xpIntoLevel: 0, xpForNextLevel: 81600)),
      // Ten years at the daily cap.
      (73000000, (level: 907, xpIntoLevel: 28800, xpForNextLevel: 81600)),
    ];
    for (final (xp, progress) in cases) {
      test('at $xp XP is $progress', () {
        expect(levelProgress(xp), progress);
      });
    }

    test('rejects negative XP', () {
      expect(() => levelProgress(-1), throwsArgumentError);
    });

    test('round-trips every threshold', () {
      for (var level = 2; level <= 60; level++) {
        final threshold = xpToReachLevel(level);
        expect(levelProgress(threshold).level, level, reason: 'at $threshold');
        expect(
          levelProgress(threshold - 1).level,
          level - 1,
          reason: 'at ${threshold - 1}',
        );
      }
    });
  });

  group('isOnMainPath', () {
    test('is true for level 1', () => expect(isOnMainPath(1), isTrue));
    test('is true for the last main-path level', () {
      expect(isOnMainPath(mainPathLevels), isTrue);
    });
    test('is false after the main path', () {
      expect(isOnMainPath(mainPathLevels + 1), isFalse);
    });
  });
}

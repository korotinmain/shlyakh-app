import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/progress/domain/xp_rules.dart';

void main() {
  group('dailyXp', () {
    final cases = <(int steps, int xp)>[
      (0, 0),
      (500, 500),
      (10000, 10000),
      (10001, 10000),
      (10002, 10001),
      (25000, 17500),
      (30000, 20000),
      (500000, 20000),
    ];
    for (final (steps, xp) in cases) {
      test('gives $xp XP for $steps steps', () {
        expect(dailyXp(steps), xp);
      });
    }

    test('rejects negative steps', () {
      expect(() => dailyXp(-1), throwsArgumentError);
    });

    test('never decreases as steps grow', () {
      for (var steps = 1; steps <= 40000; steps++) {
        expect(
          dailyXp(steps),
          greaterThanOrEqualTo(dailyXp(steps - 1)),
          reason: 'steps=$steps',
        );
      }
    });
  });

  group('totalXp', () {
    test('is 0 without days', () {
      expect(totalXp(const []), 0);
    });

    test('sums daily XP', () {
      expect(totalXp(const [500, 6000, 25000]), 24000);
    });

    test('applies the cap per day', () {
      expect(totalXp(const [500000, 500000]), 40000);
    });

    test('rejects a negative day', () {
      expect(() => totalXp(const [100, -1]), throwsArgumentError);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

void main() {
  group('LocalDate.parse', () {
    final valid = <(String, int, int, int)>[
      ('2026-09-27', 2026, 9, 27),
      ('2024-02-29', 2024, 2, 29),
      ('2026-12-31', 2026, 12, 31),
      ('2026-01-01', 2026, 1, 1),
    ];
    for (final (iso, year, month, day) in valid) {
      test('reads $iso', () {
        final date = LocalDate.parse(iso);

        expect((date.year, date.month, date.day), (year, month, day));
        expect(date.toIsoString(), iso);
      });
    }

    final invalid = <(String, String)>[
      ('Feb 29 in a common year', '2026-02-29'),
      ('Apr 31', '2026-04-31'),
      ('month 13', '2026-13-01'),
      ('month 0', '2026-00-10'),
      ('day 0', '2026-09-00'),
      ('no zero padding', '2026-9-7'),
      ('two-digit year', '26-09-27'),
      ('a time part', '2026-09-27T00:00'),
      ('leading space', ' 2026-09-27'),
      ('empty string', ''),
    ];
    for (final (name, iso) in invalid) {
      test('rejects $name', () {
        expect(() => LocalDate.parse(iso), throwsFormatException);
      });
    }
  });

  group('LocalDate.next', () {
    final cases = <(String, String)>[
      ('2026-09-27', '2026-09-28'),
      ('2026-01-31', '2026-02-01'),
      ('2026-02-28', '2026-03-01'),
      ('2024-02-28', '2024-02-29'),
      ('2024-02-29', '2024-03-01'),
      ('2026-12-31', '2027-01-01'),
    ];
    for (final (from, to) in cases) {
      test('goes from $from to $to', () {
        expect(LocalDate.parse(from).next().toIsoString(), to);
      });
    }
  });

  group('LocalDate ordering and equality', () {
    final day = LocalDate.parse('2026-09-27');

    test('is before a later day and month', () {
      expect(day.isBefore(LocalDate.parse('2026-09-28')), isTrue);
      expect(day.isBefore(LocalDate.parse('2026-10-01')), isTrue);
      expect(day.isAfter(LocalDate.parse('2025-12-31')), isTrue);
      expect(day.isBefore(day), isFalse);
    });

    test('compares equal dates as 0', () {
      expect(day.compareTo(LocalDate.parse('2026-09-27')), 0);
    });

    test('equal dates are == with the same hashCode', () {
      final same = LocalDate.parse('2026-09-27');

      expect(day, same);
      expect(day.hashCode, same.hashCode);
      expect(day, isNot(LocalDate.parse('2026-09-28')));
    });

    test('prints as its ISO string', () {
      expect(day.toString(), '2026-09-27');
    });
  });

  group('LocalDate.fromDateTime', () {
    test('reads the wall-clock fields', () {
      expect(
        LocalDate.fromDateTime(DateTime(2026, 9, 28, 23, 59)),
        LocalDate.parse('2026-09-28'),
      );
    });
  });

  group('addDays', () {
    final cases = <(String, int, String)>[
      ('2026-01-31', 1, '2026-02-01'),
      ('2024-02-28', 1, '2024-02-29'),
      ('2026-12-31', 1, '2027-01-01'),
      ('2026-03-01', -1, '2026-02-28'),
      ('2024-03-01', -1, '2024-02-29'),
      ('2027-01-01', -1, '2026-12-31'),
      ('2026-09-28', 0, '2026-09-28'),
      ('2026-01-01', 365, '2027-01-01'),
      ('2024-01-01', 366, '2025-01-01'),
      ('2026-09-28', -119, '2026-06-01'),
    ];
    for (final (from, days, expected) in cases) {
      test('$from + $days is $expected', () {
        expect(LocalDate.parse(from).addDays(days), LocalDate.parse(expected));
      });
    }
  });

  group('weekday', () {
    final cases = <(String, int)>[
      ('2026-09-28', 1),
      ('2026-09-30', 3),
      ('2026-09-27', 7),
      ('2024-02-29', 4),
      ('2027-01-03', 7),
      ('2000-01-01', 6),
    ];
    for (final (iso, weekday) in cases) {
      test('of $iso is $weekday', () {
        expect(LocalDate.parse(iso).weekday, weekday);
      });
    }
  });
}

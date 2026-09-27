import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/features/steps/data/local/daily_steps_dao.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

DailySteps _day(
  String user,
  String date,
  int steps, {
  String timezone = 'Europe/Kyiv',
}) => (
  userId: user,
  localDate: LocalDate.parse(date),
  timezone: timezone,
  steps: steps,
);

LocalDate _date(String iso) => LocalDate.parse(iso);

void main() {
  late AppDatabase db;
  late DailyStepsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.dailyStepsDao;
  });

  tearDown(() => db.close());

  group('upsert', () {
    test('stores a day with zero steps', () async {
      await dao.upsert(_day('a', '2026-09-27', 0));

      expect((await dao.forDay('a', _date('2026-09-27')))!.steps, 0);
    });

    test('stores a very large step count unchanged', () async {
      const huge = 1 << 40;
      await dao.upsert(_day('a', '2026-09-27', huge));

      expect((await dao.forDay('a', _date('2026-09-27')))!.steps, huge);
    });

    test('inserts a new day', () async {
      await dao.upsert(_day('a', '2026-09-27', 5000));

      expect(
        await dao.forDay('a', _date('2026-09-27')),
        _day('a', '2026-09-27', 5000),
      );
    });

    test('replaces the day, including a lower value', () async {
      await dao.upsert(_day('a', '2026-09-27', 5000));
      await dao.upsert(_day('a', '2026-09-27', 3000));

      expect((await dao.forDay('a', _date('2026-09-27')))!.steps, 3000);
      expect(await dao.watchForUser('a').first, hasLength(1));
    });

    test('replaces the time zone too', () async {
      await dao.upsert(_day('a', '2026-09-27', 5000));
      await dao.upsert(
        _day('a', '2026-09-27', 5000, timezone: 'Europe/Warsaw'),
      );

      expect(
        (await dao.forDay('a', _date('2026-09-27')))!.timezone,
        'Europe/Warsaw',
      );
    });

    test('rejects negative steps', () async {
      await expectLater(
        dao.upsert(_day('a', '2026-09-27', -1)),
        throwsArgumentError,
      );

      expect(await dao.watchForUser('a').first, isEmpty);
    });
  });

  group('forDay', () {
    test('keeps users apart', () async {
      await dao.upsert(_day('a', '2026-09-27', 1000));
      await dao.upsert(_day('b', '2026-09-27', 2000));

      expect((await dao.forDay('a', _date('2026-09-27')))!.steps, 1000);
      expect((await dao.forDay('b', _date('2026-09-27')))!.steps, 2000);
    });

    test('returns null for a missing day', () async {
      expect(await dao.forDay('a', _date('2026-09-27')), isNull);
    });
  });

  group('watchForUser', () {
    test('returns days in ascending order', () async {
      for (final date in ['2026-09-28', '2026-09-26', '2026-09-27']) {
        await dao.upsert(_day('a', date, 100));
      }

      final days = await dao.watchForUser('a').first;

      expect(days.map((d) => d.localDate.toIsoString()), [
        '2026-09-26',
        '2026-09-27',
        '2026-09-28',
      ]);
    });

    test('applies inclusive bounds', () async {
      for (var d = 25; d <= 29; d++) {
        await dao.upsert(_day('a', '2026-09-$d', 100));
      }

      final days = await dao
          .watchForUser('a', from: _date('2026-09-26'), to: _date('2026-09-28'))
          .first;

      expect(days.map((d) => d.localDate.toIsoString()), [
        '2026-09-26',
        '2026-09-27',
        '2026-09-28',
      ]);
    });

    test('applies only a lower bound', () async {
      for (var d = 25; d <= 27; d++) {
        await dao.upsert(_day('a', '2026-09-$d', 100));
      }

      final days = await dao.watchForUser('a', from: _date('2026-09-26')).first;

      expect(days.map((d) => d.localDate.toIsoString()), [
        '2026-09-26',
        '2026-09-27',
      ]);
    });

    test('applies only an upper bound', () async {
      for (var d = 25; d <= 27; d++) {
        await dao.upsert(_day('a', '2026-09-$d', 100));
      }

      final days = await dao.watchForUser('a', to: _date('2026-09-26')).first;

      expect(days.map((d) => d.localDate.toIsoString()), [
        '2026-09-25',
        '2026-09-26',
      ]);
    });

    test('emits again after an upsert in range', () async {
      await dao.upsert(_day('a', '2026-09-26', 100));
      final stream = dao.watchForUser('a');

      final expectation = expectLater(
        stream,
        emitsInOrder([hasLength(1), hasLength(2)]),
      );
      await dao.upsert(_day('a', '2026-09-27', 100));

      await expectation;
    });
  });

  group('deleteAllForUser', () {
    test('removes only that user', () async {
      await dao.upsert(_day('a', '2026-09-26', 100));
      await dao.upsert(_day('a', '2026-09-27', 100));
      await dao.upsert(_day('b', '2026-09-27', 100));

      expect(await dao.deleteAllForUser('a'), 2);
      expect(await dao.watchForUser('a').first, isEmpty);
      expect(await dao.forDay('b', _date('2026-09-27')), isNotNull);
    });
  });

  group('SQL constraints reject a bad raw row', () {
    final rows = <(String, String)>[
      ('negative steps', "('a', '2026-09-27', 'Europe/Kyiv', -1)"),
      ('steps as text', "('a', '2026-09-27', 'Europe/Kyiv', 'abc')"),
      ('a malformed local_date', "('a', '2026-9-27', 'Europe/Kyiv', 1)"),
      ('an empty timezone', "('a', '2026-09-27', '', 1)"),
      ('an empty user_id', "('', '2026-09-27', 'Europe/Kyiv', 1)"),
    ];
    for (final (name, values) in rows) {
      test(name, () async {
        await expectLater(
          db.customStatement('INSERT INTO daily_steps VALUES $values'),
          throwsA(isA<SqliteException>()),
        );
      });
    }
  });
}

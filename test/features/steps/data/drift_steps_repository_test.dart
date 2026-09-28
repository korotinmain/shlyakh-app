import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/features/steps/data/drift_steps_repository.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

DailySteps _day(String iso, int steps) => (
  userId: 'local',
  localDate: LocalDate.parse(iso),
  timezone: 'Europe/Kyiv',
  steps: steps,
);

void main() {
  late AppDatabase db;
  late DriftStepsRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftStepsRepository(db.dailyStepsDao);
  });

  tearDown(() => db.close());

  test('emits the stored days in range, oldest first', () async {
    for (final day in [
      _day('2026-09-28', 3),
      _day('2026-09-26', 1),
      _day('2026-09-27', 2),
      _day('2026-09-20', 9),
    ]) {
      await db.dailyStepsDao.upsert(day);
    }

    final days = await repository
        .watchDays(
          userId: 'local',
          from: LocalDate.parse('2026-09-26'),
          to: LocalDate.parse('2026-09-28'),
        )
        .first;

    expect(days, [
      _day('2026-09-26', 1),
      _day('2026-09-27', 2),
      _day('2026-09-28', 3),
    ]);
  });

  test('emits again after an upsert', () async {
    final emitted = repository.watchDays(userId: 'local').take(2).toList();

    await pumpEventQueue();
    await db.dailyStepsDao.upsert(_day('2026-09-28', 6870));

    final values = await emitted;
    expect(values.first, isEmpty);
    expect(values.last, [_day('2026-09-28', 6870)]);
  });
}

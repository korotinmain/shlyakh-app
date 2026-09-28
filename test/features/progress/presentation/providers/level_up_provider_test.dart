import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/features/progress/domain/level_curve.dart';
import 'package:shlyakh/features/progress/presentation/providers/level_up_provider.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

import '../../../../helpers/steps_test_overrides.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = memoryDatabase();
    // Riverpod 3 pauses providers nobody listens to; the shell listens.
    container = ProviderContainer(
      overrides: stepsTestOverrides(db: db, api: MockStepsHostApi()),
    )..listen(pendingLevelUpProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> addDay(String iso, int steps) => db.dailyStepsDao.upsert((
    userId: 'local',
    localDate: LocalDate.parse(iso),
    timezone: 'Europe/Kyiv',
    steps: steps,
  ));

  Future<void> settle() => pumpEventQueue();

  test('two days of 10 000 steps are level 4', () {
    expect(levelProgress(20000).level, 4);
  });

  test('a level above the celebrated one is pending', () async {
    await startTestJourney(db);
    await addDay('2026-09-27', 10000);
    await addDay('2026-09-28', 10000);
    await settle();

    final up = await container.read(pendingLevelUpProvider.future);
    expect(up?.from, 1);
    expect(up?.to, 4);
  });

  test('nothing is pending after celebrating it', () async {
    await startTestJourney(db);
    await addDay('2026-09-27', 10000);
    await addDay('2026-09-28', 10000);
    await settle();

    await container.read(celebrateLevelProvider.notifier).celebrate(4);
    await settle();

    expect(await container.read(pendingLevelUpProvider.future), isNull);
  });

  test('nothing is pending before the journey starts', () async {
    await addDay('2026-09-28', 10000);
    await settle();

    expect(await container.read(pendingLevelUpProvider.future), isNull);
  });

  test('a level that went down is not pending', () async {
    await startTestJourney(db);
    await db.journeyStartDao.markCelebrated('local', 5);
    await addDay('2026-09-28', 5000);
    await settle();

    expect(await container.read(pendingLevelUpProvider.future), isNull);
  });

  test('a new day above the celebrated level is pending again', () async {
    await startTestJourney(db);
    await addDay('2026-09-27', 10000);
    await addDay('2026-09-28', 10000);
    await settle();
    await container.read(celebrateLevelProvider.notifier).celebrate(4);
    await addDay('2026-09-29', 20000);
    await settle();

    final up = await container.read(pendingLevelUpProvider.future);
    expect(up?.from, 4);
    expect(up!.to, greaterThan(4));
  });

  test('a failing write becomes StorageFailure in the state', () async {
    await startTestJourney(db);
    container.listen(celebrateLevelProvider, (_, _) {});
    await db.customStatement('DROP TABLE journey_start');

    await container.read(celebrateLevelProvider.notifier).celebrate(4);

    expect(
      container.read(celebrateLevelProvider).error,
      isA<StorageFailure>(),
    );
  });
}

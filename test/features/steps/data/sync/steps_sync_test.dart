import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/core/logging/log_events.dart';
import 'package:shlyakh/features/steps/data/healthkit/health_kit_steps_source.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';
import 'package:shlyakh/features/steps/data/sync/steps_sync.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

import '../../../../helpers/recording_logger.dart';

class _Api extends Mock implements StepsHostApi;

NativeDays _native(Map<String, int> days, {String zone = 'Europe/Kyiv'}) =>
    NativeDays(
      timeZoneId: zone,
      days: [
        for (final MapEntry(:key, :value) in days.entries)
          NativeDay(localDate: key, steps: value),
      ],
    );

DailySteps _day(String iso, int steps, {String timezone = 'Europe/Kyiv'}) => (
  userId: 'local',
  localDate: LocalDate.parse(iso),
  timezone: timezone,
  steps: steps,
);

void main() {
  late AppDatabase db;
  late _Api api;
  late RecordingLogger logger;
  late StepsSync sync;

  final now = DateTime(2026, 9, 28, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _Api();
    logger = RecordingLogger();
    sync = StepsSync(
      source: HealthKitStepsSource(api),
      starts: db.journeyStartDao,
      days: db.dailyStepsDao,
      clock: Clock.fixed(now),
      logger: logger,
      userId: 'local',
    );
  });

  tearDown(() => db.close());

  Future<void> start(DateTime startedAt) => db.journeyStartDao.insertOnce((
    userId: 'local',
    startedAt: startedAt,
    timezone: 'Europe/Kyiv',
  ));

  Future<List<DailySteps>> stored() =>
      db.dailyStepsDao.watchForUser('local').first;

  List<StepsSyncCompleted> completed() =>
      logger.events.whereType<StepsSyncCompleted>().toList();

  void answer(NativeDays days) =>
      when(() => api.dailySteps(any())).thenAnswer((_) async => days);

  test('without a journey start nothing happens', () async {
    await sync.sync();

    verifyNever(() => api.dailySteps(any()));
    expect(logger.events, isEmpty);
  });

  test('first sync queries from the start and writes the days', () async {
    final startedAt = DateTime.utc(2026, 9, 26, 7, 20);
    await start(startedAt);
    answer(_native({'2026-09-26': 800, '2026-09-27': 5000, '2026-09-28': 12}));

    await sync.sync();

    verify(() => api.dailySteps(startedAt.millisecondsSinceEpoch)).called(1);
    expect(await stored(), [
      // The partial first day is stored as HealthKit returned it.
      _day('2026-09-26', 800),
      _day('2026-09-27', 5000),
      _day('2026-09-28', 12),
    ]);
    expect(completed().single.fields['days_written']?.render(), '3');
  });

  test('a later sync queries seven days back', () async {
    await start(DateTime.utc(2026, 9));
    await db.dailyStepsDao.upsert(_day('2026-09-02', 100));
    answer(_native({}));

    await sync.sync();

    verify(() => api.dailySteps(DateTime(2026, 9, 21).millisecondsSinceEpoch))
        .called(1);
  });

  test('a lower count replaces the stored one', () async {
    await start(DateTime.utc(2026, 9, 26));
    await db.dailyStepsDao.upsert(_day('2026-09-27', 5000));
    answer(_native({'2026-09-27': 4200}));

    await sync.sync();

    expect(await stored(), [_day('2026-09-27', 4200)]);
  });

  test('a day counted in another zone is kept', () async {
    await start(DateTime.utc(2026, 9, 26));
    await db.dailyStepsDao.upsert(_day('2026-09-27', 5000));
    answer(
      _native({'2026-09-27': 5400, '2026-09-28': 3000}, zone: 'Europe/Lisbon'),
    );

    await sync.sync();

    expect(await stored(), [
      _day('2026-09-27', 5000),
      _day('2026-09-28', 3000, timezone: 'Europe/Lisbon'),
    ]);
  });

  test('a repeated identical sync writes nothing', () async {
    await start(DateTime.utc(2026, 9, 26));
    answer(_native({'2026-09-27': 5000, '2026-09-28': 12}));

    await sync.sync();
    await sync.sync();

    expect(completed().last.fields['days_written']?.render(), '0');
  });

  test('HealthDataLocked leaves the stored days and is logged', () async {
    await start(DateTime.utc(2026, 9, 26));
    await db.dailyStepsDao.upsert(_day('2026-09-27', 5000));
    when(() => api.dailySteps(any()))
        .thenThrow(PlatformException(code: 'locked'));

    await sync.sync();

    expect(await stored(), [_day('2026-09-27', 5000)]);
    expect(logger.failures.single, isA<HealthDataLocked>());
    expect(completed(), isEmpty);
  });

  test('a storage error becomes StorageFailure', () async {
    await start(DateTime.utc(2026, 9, 26));
    answer(_native({'2026-09-27': 5000}));
    await db.customStatement('DROP TABLE daily_steps');

    await sync.sync();

    expect(logger.failures.single, isA<StorageFailure>());
  });

  test('a burst of calls runs twice', () async {
    await start(DateTime.utc(2026, 9, 26));
    final first = Completer<NativeDays>();
    var calls = 0;
    when(() => api.dailySteps(any())).thenAnswer((_) {
      calls++;
      return calls == 1 ? first.future : Future.value(_native({}));
    });

    final running = [sync.sync(), sync.sync(), sync.sync()];
    await pumpEventQueue();
    first.complete(_native({'2026-09-28': 12}));
    await Future.wait(running);

    expect(calls, 2);
  });

  test('the completed event carries no steps or dates', () async {
    await start(DateTime.utc(2026, 9, 26));
    answer(_native({'2026-09-28': 6870}));

    await sync.sync();

    final event = completed().single;
    expect(event.name, 'steps_sync_completed');
    expect(event.fields.keys, unorderedEquals(['duration', 'days_written']));
  });
}

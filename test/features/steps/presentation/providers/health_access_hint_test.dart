import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/presentation/providers/health_access_hint.dart';

import '../../../../helpers/steps_test_overrides.dart';

void main() {
  final startedAt = DateTime.utc(2026, 9, 27, 9);
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<bool> hint({
    required Duration after,
    bool started = true,
    List<int> steps = const [],
  }) async {
    if (started) {
      await db.journeyStartDao.insertOnce((
        userId: 'local',
        startedAt: startedAt,
        timezone: 'Europe/Kyiv',
      ));
    }
    for (final (i, count) in steps.indexed) {
      await db.dailyStepsDao.upsert((
        userId: 'local',
        localDate: LocalDate.parse('2026-09-27').addDays(i),
        timezone: 'Europe/Kyiv',
        steps: count,
      ));
    }
    final container = ProviderContainer(
      overrides: [
        ...stepsTestOverrides(db: db, api: MockStepsHostApi()),
        clockProvider.overrideWithValue(Clock.fixed(startedAt.add(after))),
      ],
    );
    addTearDown(container.dispose);
    // Riverpod 3 pauses providers nobody listens to; the screen listens.
    final subscription = container.listen(healthAccessHintProvider, (_, _) {});
    addTearDown(subscription.close);
    return await container.read(healthAccessHintProvider.future);
  }

  test('not yet at 23 hours', () async {
    expect(await hint(after: const Duration(hours: 23)), isFalse);
  });

  test('at 25 hours with no days', () async {
    expect(await hint(after: const Duration(hours: 25)), isTrue);
  });

  test('at 25 hours with only zero days', () async {
    expect(
      await hint(after: const Duration(hours: 25), steps: [0, 0]),
      isTrue,
    );
  });

  test('not with a day that has steps', () async {
    expect(
      await hint(after: const Duration(hours: 25), steps: [0, 12]),
      isFalse,
    );
  });

  test('not before the journey starts', () async {
    expect(
      await hint(after: const Duration(hours: 25), started: false),
      isFalse,
    );
  });
}

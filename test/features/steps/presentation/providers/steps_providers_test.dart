import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/presentation/providers/steps_providers.dart';
import 'package:shlyakh/features/today/presentation/providers/steps_repository_provider.dart';

import '../../../../helpers/steps_test_overrides.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = memoryDatabase();
    container = ProviderContainer(
      overrides: stepsTestOverrides(db: db, api: MockStepsHostApi()),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('stepsSync is one instance', () {
    final first = container.read(stepsSyncProvider);
    final subscription = container.listen(stepsSyncProvider, (_, _) {});
    addTearDown(subscription.close);

    expect(container.read(stepsSyncProvider), same(first));
    expect(subscription.read(), same(first));
  });

  test('journeyStart emits null, then the inserted start', () async {
    // Riverpod 3 pauses a provider nobody listens to; the router listens.
    final started = container.listen(journeyStartProvider, (_, _) {});
    addTearDown(started.close);

    expect(await container.read(journeyStartProvider.future), isNull);
    await startTestJourney(db);
    await pumpEventQueue();

    expect(started.read().value?.startedAt, testJourneyStart);
  });

  test('stepsRepository reads Drift', () async {
    await db.dailyStepsDao.upsert((
      userId: 'local',
      localDate: LocalDate.parse('2026-09-28'),
      timezone: 'Europe/Kyiv',
      steps: 6870,
    ));

    final days = await container
        .read(stepsRepositoryProvider)
        .watchDays(userId: 'local')
        .first;

    expect(days.single.steps, 6870);
  });
}

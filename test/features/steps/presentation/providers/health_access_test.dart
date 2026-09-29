import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/steps/presentation/providers/health_access.dart';

import '../../../../helpers/steps_test_overrides.dart';

void main() {
  final tap = DateTime(2026, 9, 28, 9, 30);
  late AppDatabase db;
  late MockStepsHostApi api;
  late ProviderContainer container;

  setUp(() {
    db = memoryDatabase();
    api = MockStepsHostApi();
    // Riverpod 3 pauses providers nobody listens to; the screen listens.
    container = ProviderContainer(
      overrides: [
        ...stepsTestOverrides(db: db, api: api),
        clockProvider.overrideWithValue(Clock.fixed(tap)),
      ],
    )..listen(healthAccessProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> allow() => container.read(healthAccessProvider.notifier).allow();

  test(
    'allow requests access, stores the start at the tap and syncs',
    () async {
      await allow();

      verifyInOrder([
        () => api.requestAccess(),
        () => api.dailySteps(tap.millisecondsSinceEpoch),
      ]);
      final start = await db.journeyStartDao.get('local');
      expect(start?.startedAt, tap.toUtc());
      expect(start?.timezone, 'Europe/Kyiv');
      expect(container.read(healthAccessProvider).hasError, isFalse);
    },
  );

  test('unavailable HealthKit stores no start', () async {
    when(() => api.isAvailable()).thenAnswer((_) async => false);

    await allow();

    expect(
      container.read(healthAccessProvider).error,
      isA<HealthUnavailable>(),
    );
    expect(await db.journeyStartDao.get('local'), isNull);
    verifyNever(() => api.requestAccess());
  });

  test('a failing prompt stores no start', () async {
    when(() => api.requestAccess())
        .thenThrow(PlatformException(code: 'healthkit'));

    await allow();

    expect(
      container.read(healthAccessProvider).error,
      isA<UnexpectedFailure>(),
    );
    expect(await db.journeyStartDao.get('local'), isNull);
  });

  test('a second tap while allowing prompts once', () async {
    final prompt = Completer<void>();
    when(() => api.requestAccess()).thenAnswer((_) => prompt.future);

    final first = allow();
    final second = allow();
    await pumpEventQueue();
    prompt.complete();
    await Future.wait([first, second]);

    verify(() => api.requestAccess()).called(1);
    expect(await db.journeyStartDao.get('local'), isNotNull);
  });

  test('healthAvailable reads HealthKit', () async {
    when(() => api.isAvailable()).thenAnswer((_) async => false);
    container.listen(healthAvailableProvider, (_, _) {});

    expect(await container.read(healthAvailableProvider.future), isFalse);
  });

  test('a failing database write shows StorageFailure', () async {
    await db.customStatement('DROP TABLE journey_start');

    await allow();

    expect(container.read(healthAccessProvider).error, isA<StorageFailure>());
  });
}

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/core/database/app_database_provider.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';
import 'package:shlyakh/features/steps/presentation/providers/steps_providers.dart';

/// HealthKit for tests: available, Kyiv, no days unless a test stubs more.
class MockStepsHostApi extends Mock implements StepsHostApi {
  new() {
    when(isAvailable).thenAnswer((_) async => true);
    when(requestAccess).thenAnswer((_) async {});
    when(timeZoneId).thenAnswer((_) async => 'Europe/Kyiv');
    when(
      () => dailySteps(any()),
    ).thenAnswer((_) async => NativeDays(timeZoneId: 'Europe/Kyiv', days: []));
  }
}

/// The journey start tests use when a journey has begun.
final DateTime testJourneyStart = DateTime.utc(2026, 9);

/// Overrides that keep tests away from real HealthKit and the file
/// database: an in-memory [db] and [api].
List<Override> stepsTestOverrides({
  required AppDatabase db,
  required StepsHostApi api,
}) => [
  appDatabaseProvider.overrideWithValue(db),
  stepsHostApiProvider.overrideWithValue(api),
];

/// An in-memory database, closed after the test by the caller.
///
/// Streams close synchronously: drift otherwise closes them on a zero
/// timer, which widget tests report as pending after the tree is gone.
AppDatabase memoryDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Starts the `'local'` journey at [testJourneyStart].
Future<void> startTestJourney(AppDatabase db) => db.journeyStartDao.insertOnce((
  userId: 'local',
  startedAt: testJourneyStart,
  timezone: 'Europe/Kyiv',
));

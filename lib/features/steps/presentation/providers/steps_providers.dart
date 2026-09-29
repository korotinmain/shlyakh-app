import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/database/app_database_provider.dart';
import 'package:shlyakh/core/logging/logger_provider.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/steps/data/drift_journey_repository.dart';
import 'package:shlyakh/features/steps/data/healthkit/health_kit_steps_source.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';
import 'package:shlyakh/features/steps/data/sync/steps_sync.dart';
import 'package:shlyakh/features/steps/domain/journey_repository.dart';
import 'package:shlyakh/features/steps/domain/journey_start.dart';
import 'package:shlyakh/features/today/presentation/providers/current_user_provider.dart';

part 'steps_providers.g.dart';

/// The Pigeon bridge to native HealthKit. Tests override it with a mock.
@Riverpod(keepAlive: true)
StepsHostApi stepsHostApi(Ref ref) => StepsHostApi();

@Riverpod(keepAlive: true)
HealthKitStepsSource healthKitStepsSource(Ref ref) =>
    HealthKitStepsSource(ref.watch(stepsHostApiProvider));

/// The one sync every trigger shares: its run guard is per instance, and
/// two instances could commit a stale count over a newer one.
@Riverpod(keepAlive: true)
StepsSync stepsSync(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return StepsSync(
    source: ref.watch(healthKitStepsSourceProvider),
    starts: db.journeyStartDao,
    days: db.dailyStepsDao,
    clock: ref.watch(clockProvider),
    logger: ref.watch(loggerProvider),
    userId: ref.watch(currentUserIdProvider),
  );
}

/// Journey starts in Drift.
@Riverpod(keepAlive: true)
JourneyRepository journeyRepository(Ref ref) =>
    DriftJourneyRepository(ref.watch(appDatabaseProvider).journeyStartDao);

/// The current user's journey start; null until they allow Health access.
@Riverpod(keepAlive: true)
Stream<JourneyStart?> journeyStart(Ref ref) => ref
    .watch(journeyRepositoryProvider)
    .watchStart(ref.watch(currentUserIdProvider));

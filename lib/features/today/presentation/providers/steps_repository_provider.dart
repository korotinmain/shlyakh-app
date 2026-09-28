import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/database/app_database_provider.dart';
import 'package:shlyakh/features/steps/data/drift_steps_repository.dart';
import 'package:shlyakh/features/steps/domain/steps_repository.dart';

part 'steps_repository_provider.g.dart';

/// The steps source: Drift, filled from HealthKit by `StepsSync`.
@Riverpod(keepAlive: true)
StepsRepository stepsRepository(Ref ref) =>
    DriftStepsRepository(ref.watch(appDatabaseProvider).dailyStepsDao);

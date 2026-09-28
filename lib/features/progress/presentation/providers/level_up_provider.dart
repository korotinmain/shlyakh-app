import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:drift/native.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/database/app_database_provider.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/features/progress/domain/level_curve.dart';
import 'package:shlyakh/features/progress/domain/level_up.dart';
import 'package:shlyakh/features/progress/domain/xp_rules.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/today/presentation/providers/current_user_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/steps_repository_provider.dart';

part 'level_up_provider.g.dart';

/// The last level whose scene the user has seen; null before the journey.
@riverpod
Stream<int?> celebratedLevel(Ref ref) => ref
    .watch(appDatabaseProvider)
    .journeyStartDao
    .watchCelebratedLevel(ref.watch(currentUserIdProvider));

/// Every stored day of the user, for the current level.
@riverpod
Stream<List<DailySteps>> storedDays(Ref ref) => ref
    .watch(stepsRepositoryProvider)
    .watchDays(userId: ref.watch(currentUserIdProvider));

/// The level-up to celebrate now, or null: the level of all stored days
/// above the last celebrated one
/// (docs/superpowers/specs/2026-09-28-level-up-moment-design.md).
@riverpod
Future<LevelUp?> pendingLevelUp(Ref ref) async {
  final celebrated = await ref.watch(celebratedLevelProvider.future);
  if (celebrated == null) return null;
  final days = await ref.watch(storedDaysProvider.future);
  final current = levelProgress(totalXp(days.map((d) => d.steps))).level;
  return levelUp(celebrated: celebrated, current: current);
}

/// "Continue" on the level-up scene: records the level as seen. A storage
/// error ends up in the state as [StorageFailure] so the scene can say so
/// and let the user try again.
@Riverpod(keepAlive: true)
class CelebrateLevel extends _$CelebrateLevel {
  @override
  FutureOr<void> build() {}

  Future<void> celebrate(int level) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref
            .read(appDatabaseProvider)
            .journeyStartDao
            .markCelebrated(ref.read(currentUserIdProvider), level);
      } on SqliteException catch (e) {
        throw StorageFailure(cause: e);
      } on DriftRemoteException catch (e) {
        if (e.remoteCause is! SqliteException) rethrow;
        throw StorageFailure(cause: e);
      }
    });
  }
}

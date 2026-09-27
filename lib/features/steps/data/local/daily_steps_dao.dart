import 'package:drift/drift.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/features/steps/data/local/daily_steps_table.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

part 'daily_steps_dao.g.dart';

/// Reads and writes [DailyStepsTable] in domain types; Drift rows never
/// leave the data layer.
@DriftAccessor(tables: [DailyStepsTable])
class DailyStepsDao extends DatabaseAccessor<AppDatabase>
    with _$DailyStepsDaoMixin {
  new(super.attachedDatabase);

  /// Inserts the day or replaces the stored row for (userId, localDate),
  /// including with a lower step count: HealthKit is the source of truth.
  ///
  /// Throws [ArgumentError] for negative steps.
  Future<void> upsert(DailySteps day) async {
    if (day.steps < 0) {
      throw ArgumentError.value(day.steps, 'steps', 'must be >= 0');
    }
    await into(dailyStepsTable).insertOnConflictUpdate(
      DailyStepsTableCompanion.insert(
        userId: day.userId,
        localDate: day.localDate.toIsoString(),
        timezone: day.timezone,
        steps: day.steps,
      ),
    );
  }

  /// The stored day, or null when there is none.
  Future<DailySteps?> forDay(String userId, LocalDate date) async {
    final row =
        await (select(dailyStepsTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.localDate.equals(date.toIsoString()),
            ))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// The user's days between [from] and [to] (both inclusive, both
  /// optional), oldest first; emits again whenever they change.
  Stream<List<DailySteps>> watchForUser(
    String userId, {
    LocalDate? from,
    LocalDate? to,
  }) {
    final query = select(dailyStepsTable)
      ..where((t) => t.userId.equals(userId));
    // YYYY-MM-DD strings order the same way as the dates they encode.
    if (from != null) {
      query.where((t) => t.localDate.isBiggerOrEqualValue(from.toIsoString()));
    }
    if (to != null) {
      query.where((t) => t.localDate.isSmallerOrEqualValue(to.toIsoString()));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.localDate)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  /// Deletes every day of the user (account deletion, AGENT_RULES 5) and
  /// returns how many rows were removed.
  Future<int> deleteAllForUser(String userId) =>
      (delete(dailyStepsTable)..where((t) => t.userId.equals(userId))).go();

  DailySteps _toDomain(DailyStepsRow row) => (
    userId: row.userId,
    localDate: LocalDate.parse(row.localDate),
    timezone: row.timezone,
    steps: row.steps,
  );
}

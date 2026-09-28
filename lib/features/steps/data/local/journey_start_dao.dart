import 'package:drift/drift.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/features/steps/data/local/journey_start_table.dart';
import 'package:shlyakh/features/steps/domain/journey_start.dart';

part 'journey_start_dao.g.dart';

/// Reads and writes [JourneyStartTable] in domain types.
@DriftAccessor(tables: [JourneyStartTable])
class JourneyStartDao extends DatabaseAccessor<AppDatabase>
    with _$JourneyStartDaoMixin {
  new(super.attachedDatabase);

  /// The user's journey start, or null before it.
  Future<JourneyStart?> get(String userId) async {
    final row = await _byUser(userId).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// The user's journey start; emits again when it is created or deleted.
  Stream<JourneyStart?> watch(String userId) => _byUser(
    userId,
  ).watchSingleOrNull().map((row) => row == null ? null : _toDomain(row));

  /// Stores [start] unless the user already has one, which is never
  /// overwritten. Returns whether it was stored.
  Future<bool> insertOnce(JourneyStart start) => transaction(() async {
    if (await _byUser(start.userId).getSingleOrNull() != null) return false;
    await into(journeyStartTable).insert(
      JourneyStartTableCompanion.insert(
        userId: start.userId,
        startedAt: start.startedAt.toUtc().millisecondsSinceEpoch,
        timezone: start.timezone,
      ),
    );
    return true;
  });

  /// Deletes the user's start (account deletion, AGENT_RULES 5) and
  /// returns how many rows were removed.
  Future<int> deleteForUser(String userId) => (delete(
    journeyStartTable,
  )..where((t) => t.userId.equals(userId))).go();

  SimpleSelectStatement<$JourneyStartTableTable, JourneyStartRow> _byUser(
    String userId,
  ) => select(journeyStartTable)..where((t) => t.userId.equals(userId));

  JourneyStart _toDomain(JourneyStartRow row) => (
    userId: row.userId,
    startedAt: DateTime.fromMillisecondsSinceEpoch(row.startedAt, isUtc: true),
    timezone: row.timezone,
  );
}

import 'package:drift/drift.dart';
import 'package:shlyakh/core/database/app_database.steps.dart';
import 'package:shlyakh/features/steps/data/local/daily_steps_dao.dart';
import 'package:shlyakh/features/steps/data/local/daily_steps_table.dart';
import 'package:shlyakh/features/steps/data/local/journey_start_dao.dart';
import 'package:shlyakh/features/steps/data/local/journey_start_table.dart';

part 'app_database.g.dart';

/// The app's local database and source of truth (docs/ARCHITECTURE.md).
/// Every feature adds its tables here; schema changes go through
/// migrations (`dart run drift_dev make-migrations`).
@DriftDatabase(
  tables: [DailyStepsTable, JourneyStartTable],
  daos: [DailyStepsDao, JourneyStartDao],
)
class AppDatabase extends _$AppDatabase {
  new(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // v2: the journey start (HealthKit sync).
      from1To2: (m, schema) => m.createTable(schema.journeyStart),
      // v3: the last celebrated level (level-up scene). The table is
      // rebuilt: ALTER TABLE cannot add its CHECK constraint.
      from2To3: (m, schema) => m.alterTable(
        TableMigration(
          schema.journeyStart,
          newColumns: [schema.journeyStart.celebratedLevel],
        ),
      ),
    ),
  );
}

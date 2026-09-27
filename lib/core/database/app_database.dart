import 'package:drift/drift.dart';
import 'package:shlyakh/features/steps/data/local/daily_steps_dao.dart';
import 'package:shlyakh/features/steps/data/local/daily_steps_table.dart';

part 'app_database.g.dart';

/// The app's local database and source of truth (docs/ARCHITECTURE.md).
/// Every feature adds its tables here; schema changes go through
/// migrations (`dart run drift_dev make-migrations`).
@DriftDatabase(tables: [DailyStepsTable], daos: [DailyStepsDao])
class AppDatabase extends _$AppDatabase {
  new(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}

import 'package:drift/drift.dart';

/// Daily step totals of any number of users (the device's user and the
/// members of their Спільно). Schema: docs/superpowers/specs/
/// 2026-09-27-drift-daily-steps-design.md.
@DataClassName('DailyStepsRow')
class DailyStepsTable extends Table {
  @override
  String get tableName => 'daily_steps';

  TextColumn get userId => text()();

  /// Local calendar day, `YYYY-MM-DD` (see LocalDate).
  TextColumn get localDate => text()();

  /// IANA time zone the day was counted in, e.g. `Europe/Kyiv`.
  TextColumn get timezone => text()();

  IntColumn get steps => integer()();

  @override
  Set<Column<Object>> get primaryKey => {userId, localDate};

  @override
  List<String> get customConstraints => ['CHECK (steps >= 0)'];
}

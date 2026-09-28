import 'package:drift/drift.dart';

/// Each user's journey start (docs/superpowers/specs/
/// 2026-09-28-healthkit-steps-sync-design.md): one row per user, never
/// overwritten.
@DataClassName('JourneyStartRow')
class JourneyStartTable extends Table {
  @override
  String get tableName => 'journey_start';

  TextColumn get userId => text()();

  /// UTC milliseconds since the epoch.
  IntColumn get startedAt => integer()();

  /// IANA time zone at the start, e.g. `Europe/Kyiv`.
  TextColumn get timezone => text()();

  /// The last level whose level-up scene the user has seen; only raised
  /// (docs/superpowers/specs/2026-09-28-level-up-moment-design.md).
  IntColumn get celebratedLevel => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {userId};

  @override
  bool get isStrict => true;

  @override
  List<String> get customConstraints => [
    "CHECK (user_id <> '')",
    "CHECK (timezone <> '')",
    'CHECK (started_at >= 0)',
    'CHECK (celebrated_level >= 1)',
  ];
}

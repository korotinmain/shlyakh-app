# Drift schema for daily steps — design

Date: 2026-09-27
Status: approved in chat, pending spec review

## Goal

Give the app its local source of truth for daily step counts: a Drift
(SQLite) database with one table for the steps of any number of users, a
DAO that speaks domain types, and migration tooling from version 1.

## Success criteria

- A day's steps can be written and read back per user; writing the same
  `(user_id, local_date)` again replaces the row (idempotent upsert).
- All rows of a user can be deleted without touching other users.
- The schema is snapshotted as version 1 so later versions get generated
  migration tests.
- Data layer coverage ≥ 85%, domain 100% (`tool/coverage/check_coverage.dart`).

## Decisions

| Topic | Decision |
|---|---|
| Whose steps | Any number of users in one table, keyed by `user_id` (the device's user and members of their Спільно). Groups themselves are backend (stage 5) |
| Time zone | IANA identifier (`Europe/Kyiv`), provided later by native Swift through Pigeon; no new dependency |
| Local date | `TEXT` `YYYY-MM-DD`; domain type `LocalDate`; never a UTC timestamp (AGENT_RULES 4) |
| Lower value from HealthKit | Replace: HealthKit is the source of truth (AGENT_RULES 6). XP may decrease when a user deletes data in Health; this is a data correction, not a penalty |
| Sync columns | None yet; added by a migration in stage 5 |
| Schema snapshots | `drift_schemas/*.json` are committed (exception to ADR 0001, recorded there); generated Dart stays uncommitted |

## Dependencies (approved)

- dependencies: `drift` ^2.35.0, `drift_flutter` ^0.3.1, `sqlite3` ^3.6.0
- dev_dependencies: `drift_dev` ^2.35.0
- pending approval: `meta` (direct dependency, for `@immutable` on `LocalDate`)

`sqlite3` 3.x bundles SQLite through Dart build hooks (iOS devices and
simulators, macOS for `flutter test`); `sqlite3_flutter_libs 0.6.0+eol`
arrives transitively as an intentionally empty package.

## Schema (version 1)

Table `daily_steps`:

| Column | SQLite type | Constraint |
|---|---|---|
| `user_id` | TEXT | NOT NULL |
| `local_date` | TEXT | NOT NULL, format `YYYY-MM-DD` |
| `timezone` | TEXT | NOT NULL |
| `steps` | INTEGER | NOT NULL, `CHECK (steps >= 0)` |

Primary key `(user_id, local_date)`. The table is `STRICT` (SQLite enforces
column types) and also checks `local_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'`,
`timezone <> ''` and `user_id <> ''`, so a malformed row cannot reach a
stream (added after final review, before v1 ever shipped).

## Structure

```
lib/core/database/
├── app_database.dart           # @DriftDatabase(tables: [DailyStepsTable]), schemaVersion 1
└── app_database_provider.dart  # appDatabaseProvider (keepAlive), closes the DB on dispose
lib/features/steps/
├── domain/
│   ├── local_date.dart         # LocalDate
│   └── daily_steps.dart        # DailySteps record
└── data/local/
    ├── daily_steps_table.dart  # Drift table
    └── daily_steps_dao.dart    # DailyStepsDao
drift_schemas/                  # drift_dev make-migrations output (committed)
build.yaml                      # drift database config for make-migrations
```

One database for the whole app lives in `core`; each feature defines its
own tables. `appDatabaseProvider` opens the file database with
`drift_flutter`'s `driftDatabase(name: 'shlyakh')`; tests override it with
`NativeDatabase.memory()`.

### Domain

- `LocalDate`: an immutable `final class` (fields `year`, `month`, `day`)
  annotated `@immutable` from `package:meta`, with `==`/`hashCode`. A record
  cannot validate its input; `package:meta` is pure Dart from the Dart team
  (already in `pubspec.lock` through `drift_flutter`) and becomes a direct
  dependency, pending the developer's approval. Fallback if not approved:
  the same class with a targeted
  `// ignore: avoid_equals_and_hash_code_on_mutable_classes` and a reason.
  - `LocalDate.parse(String)` accepts exactly `YYYY-MM-DD` of a real
    calendar date, else `FormatException`.
  - `toIsoString()` → `YYYY-MM-DD`, zero-padded.
  - `compareTo`, `isBefore`, `isAfter`, `next()` (the following calendar
    day, across month and year ends and Feb 29).
- `typedef DailySteps = ({String userId, LocalDate localDate, String timezone, int steps});`

### DAO (`DailyStepsDao`, a Drift `DatabaseAccessor<AppDatabase>`)

- `Future<void> upsert(DailySteps day)` — insert or replace the whole row
  for `(user_id, local_date)`. Throws `ArgumentError` for negative steps
  before touching the database (the CHECK constraint is a second guard).
- `Future<DailySteps?> forDay(String userId, LocalDate date)`.
- `Stream<List<DailySteps>> watchForUser(String userId, {LocalDate? from, LocalDate? to})`
  — inclusive bounds, ordered by `local_date` ascending.
- `Future<int> deleteAllForUser(String userId)` — returns deleted rows.

Drift row classes never leave `data/`; the DAO maps to and from
`DailySteps`.

## Testing

- `test/features/steps/domain/local_date_test.dart` (100%): parse valid
  dates; reject `2026-02-29`, `2026-13-01`, `2026-9-7`, `26-09-27`,
  `2026-09-27T00:00`, empty; `2024-02-29` valid; round-trip
  `parse(x).toIsoString() == x`; ordering; `next()` for 2026-01-31,
  2026-02-28, 2024-02-28, 2024-02-29, 2026-12-31.
- `test/features/steps/data/local/daily_steps_dao_test.dart` (in-memory):
  upsert inserts; upsert again replaces, including a lower value; users do
  not mix; `forDay` returns null for a missing day; `watchForUser` with and
  without bounds, bounds inclusive, ascending order, emits again after an
  upsert; `deleteAllForUser` removes only that user and returns the count;
  negative steps → `ArgumentError`; a raw insert with negative steps is
  rejected by the CHECK constraint.
- Migration tooling: `dart run drift_dev make-migrations` produces the
  version 1 snapshot and its generated test scaffold; the generated test
  runs in `flutter test`.

## Docs

- ADR 0001: add the `drift_schemas/` exception.
- `docs/ARCHITECTURE.md`: local storage [built], schema summary.
- `docs/ROADMAP.md`: tick "Drift schema for daily steps".
- `CLAUDE.md` Commands: `dart run drift_dev make-migrations` after a schema
  change.

## Out of scope

- Reading HealthKit, the IANA time zone bridge, `currentUserIdProvider`,
  the repository (next task).
- Sync columns, Supabase, Спільно tables (stage 5).

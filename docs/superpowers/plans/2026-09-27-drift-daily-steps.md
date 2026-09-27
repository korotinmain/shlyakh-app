# Drift Daily Steps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app's local store for daily steps: `LocalDate`, `DailySteps`, a Drift database with the `daily_steps` table, a DAO in domain types, and migration tooling at schema version 1.

**Architecture:** `AppDatabase` in `lib/core/database/` owns all tables; the steps feature defines its table and DAO in `features/steps/data/local/` and its value types in `features/steps/domain/`. Drift row classes never leave `data/`. Tests use `NativeDatabase.memory()`.

**Tech Stack:** drift 2.35 (classic API `package:drift/drift.dart`, **not** `drift3_preview`), drift_flutter 0.3.1, sqlite3 3.6 (SQLite via build hooks), drift_dev 2.35, meta.

**Spec:** `docs/superpowers/specs/2026-09-27-drift-daily-steps-design.md`

## Global Constraints

- Branch `feat/drift-schema`; Conventional Commits ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Approved dependencies only: `drift`, `drift_flutter`, `sqlite3`, `meta`; dev `drift_dev`. Add with `flutter pub add`.
- Domain files import only `dart:core` and `package:meta/meta.dart`.
- Constructors use Dart 3.13 `new(...)` syntax.
- `local_date` is always `YYYY-MM-DD` text; no `DateTime` in the schema or domain types (AGENT_RULES 4).
- Upsert replaces the whole row, including with a lower `steps` (spec decision (a)).
- Gate before each commit: `dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && flutter test --coverage && dart run tool/coverage/check_coverage.dart` (domain 100%, data ≥ 85%).
- Before using a Drift API, check it in `~/.pub-cache/hosted/pub.dev/drift-2.35.0/lib/src/` (CLAUDE.md, "Library versions").

## Review Focus

- A day's steps reported lower by HealthKit on a later sync must replace the stored value, not be ignored or maxed. Test in Task 2.
- One user's `deleteAllForUser` must not remove any row of another user sharing a date. Test in Task 2.
- `watchForUser` must emit again after an upsert inside its range, and must not emit a row outside `from`/`to`. Test in Task 2.
- `LocalDate.parse` must reject impossible dates (`2026-02-29`, `2026-04-31`) that `DateTime.parse` would silently roll over. Test in Task 1.
- Generated migration output under `lib/` must not count as untested core code in the coverage check. Test in Task 3.

---

### Task 1: LocalDate and DailySteps

**Files:**
- Modify: `pubspec.yaml` (`flutter pub add meta`)
- Create: `lib/features/steps/domain/local_date.dart`, `lib/features/steps/domain/daily_steps.dart`
- Test: `test/features/steps/domain/local_date_test.dart`

**Interfaces:**
- Produces:
  - `@immutable final class LocalDate implements Comparable<LocalDate>` with `final int year, month, day`; `factory LocalDate.parse(String iso)` (throws `FormatException`); `String toIsoString()`; `bool isBefore(LocalDate)`, `bool isAfter(LocalDate)`; `LocalDate next()`; `==`/`hashCode`/`toString()` (= `toIsoString()`). Private validating constructor `LocalDate._(year, month, day)`.
  - `typedef DailySteps = ({String userId, LocalDate localDate, String timezone, int steps});`

- [ ] **Step 1: Write the failing tests** (table-driven):
  - valid: `'2026-09-27'`, `'2024-02-29'`, `'2026-12-31'`, `'2026-01-01'` → round-trip `parse(x).toIsoString() == x`, fields equal.
  - invalid → `throwsFormatException`: `'2026-02-29'`, `'2026-04-31'`, `'2026-13-01'`, `'2026-00-10'`, `'2026-09-00'`, `'2026-9-7'`, `'26-09-27'`, `'2026-09-27T00:00'`, `' 2026-09-27'`, `''`.
  - `next()`: `2026-01-31 → 2026-02-01`, `2026-02-28 → 2026-03-01`, `2024-02-28 → 2024-02-29`, `2024-02-29 → 2024-03-01`, `2026-12-31 → 2027-01-01`, `2026-09-27 → 2026-09-28`.
  - ordering: `2026-09-27` isBefore `2026-09-28` and `2026-10-01`; `compareTo` 0 for equal; equal instances `==` and same `hashCode`; different dates not equal.

- [ ] **Step 2: Run** `flutter test test/features/steps/domain/local_date_test.dart` — Expected: FAIL, `LocalDate` not defined.

- [ ] **Step 3: Implement** `LocalDate`. Parse with `RegExp(r'^(\d{4})-(\d{2})-(\d{2})$')`; validate month 1–12 and day 1–daysInMonth (leap: divisible by 4 and not by 100, or by 400). `next()` increments in integers, no `DateTime`. Write `daily_steps.dart`.

- [ ] **Step 4: Run** — Expected: all PASS; commit `feat(steps): LocalDate and DailySteps domain types`.

### Task 2: Database, table and DAO

**Files:**
- Modify: `pubspec.yaml` (`flutter pub add drift drift_flutter sqlite3 dev:drift_dev`)
- Create: `lib/features/steps/data/local/daily_steps_table.dart`, `lib/features/steps/data/local/daily_steps_dao.dart`, `lib/core/database/app_database.dart`, `lib/core/database/app_database_provider.dart`
- Test: `test/features/steps/data/local/daily_steps_dao_test.dart`

**Interfaces:**
- Consumes: `LocalDate`, `DailySteps` (Task 1).
- Produces:
  - `@DataClassName('DailyStepsRow') class DailyStepsTable extends Table` — `tableName` `'daily_steps'`; `userId` text, `localDate` text, `timezone` text, `steps` integer with `.check(steps.isBiggerOrEqualValue(0))`; `primaryKey => {userId, localDate}`.
  - `@DriftDatabase(tables: [DailyStepsTable], daos: [DailyStepsDao]) class AppDatabase extends _$AppDatabase` — `new(super.e)`; `schemaVersion => 1`; `migration` with `onCreate: (m) => m.createAll()`.
  - `@DriftAccessor(tables: [DailyStepsTable]) class DailyStepsDao extends DatabaseAccessor<AppDatabase> with _$DailyStepsDaoMixin` — `upsert`, `forDay`, `watchForUser`, `deleteAllForUser` exactly as the spec's DAO section; `upsert` uses `insertOnConflictUpdate`; mapping via private `_toDomain(DailyStepsRow)` / companion builder.
  - `@Riverpod(keepAlive: true) AppDatabase appDatabase(Ref ref)` — `AppDatabase(driftDatabase(name: 'shlyakh'))`, `ref.onDispose(db.close)`. First lines: `// coverage:ignore-file` + `// Reason: DI wiring for the file database; tests override appDatabaseProvider.`

- [ ] **Step 1: Write the failing tests** (`setUp`: `db = AppDatabase(NativeDatabase.memory())`, `addTearDown(db.close)`; `dao = db.dailyStepsDao`; builder `DailySteps day(String user, String date, int steps, {String tz = 'Europe/Kyiv'})`):
  - `'upsert inserts a new day'` → `forDay` returns it.
  - `'upsert replaces the day, including a lower value'`: 5000 then 3000 → `forDay(...).steps == 3000`, one row.
  - `'upsert replaces the time zone too'`: `Europe/Kyiv` then `Europe/Warsaw` → Warsaw.
  - `'keeps users apart'`: same date for `a` and `b` → each `forDay` returns its own.
  - `'forDay returns null for a missing day'`.
  - `'watchForUser returns days in ascending order'`: insert 09-28, 09-26, 09-27 → emitted dates in order.
  - `'watchForUser applies inclusive bounds'`: days 09-25…09-29, `from: 09-26, to: 09-28` → exactly 26, 27, 28.
  - `'watchForUser emits again after an upsert in range'`: `expectLater(stream, emitsInOrder([hasLength(1), hasLength(2)]))` around an upsert.
  - `'deleteAllForUser removes only that user'`: returns count for `a`; `b`'s row remains.
  - `'upsert rejects negative steps'` → `throwsArgumentError`, table still empty.
  - `'the CHECK constraint rejects negative steps'`: `db.customStatement("INSERT INTO daily_steps VALUES ('a','2026-09-27','Europe/Kyiv',-1)")` → `throwsA(isA<SqliteException>())` (import `package:sqlite3/sqlite3.dart`).

- [ ] **Step 2: Run** `flutter test test/features/steps/data` — Expected: FAIL, not defined.

- [ ] **Step 3: Implement** table, database, DAO, provider; `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Run** the tests — Expected: 11 PASS; run the full gate — Expected: data layer ≥ 85%; commit `feat(steps): Drift database and daily steps DAO`.

### Task 3: Migration tooling, ADR and docs

**Files:**
- Create: `build.yaml`, `drift_schemas/` output, generated migration test scaffold under `test/drift/`
- Modify: `tool/coverage/src/layers.dart` + `test/tool/coverage/layers_test.dart` (only if make-migrations writes Dart under `lib/`), `docs/decisions/0001-generated-files-not-committed.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `CLAUDE.md`

- [ ] **Step 1: Configure and run** — `build.yaml` with `targets.$default.builders.drift_dev.options.databases.app_database: lib/core/database/app_database.dart`, `schema_dir: drift_schemas/`, `test_dir: test/drift/`. Run `dart run drift_dev make-migrations`. Expected: `drift_schemas/app_database/drift_schema_v1.json` and a test scaffold; list every file it wrote.

- [ ] **Step 2: Decide what is committed.** Commit `drift_schemas/**` and every file make-migrations wrote (they are regenerated only by an explicit schema change, and CI must not create snapshots). If make-migrations wrote Dart under `lib/` (e.g. `app_database.steps.dart`), first add a failing case to `layers_test.dart` (`'drift migration steps'`, `'lib/core/database/app_database.steps.dart'`, `Layer.excluded`), watch it fail, then add `.steps.dart` to the excluded suffixes in `classify`.

- [ ] **Step 3: Docs.** ADR 0001: add "Exception: `drift_dev make-migrations` output (`drift_schemas/`, generated migration tests and steps) is committed: old schema versions cannot be regenerated from the current code." `ARCHITECTURE.md`: local storage → [built] with the table summary; section 2 bullet for `core/database` and `features/steps`. `ROADMAP.md`: tick "Drift schema for daily steps". `CLAUDE.md` Commands: `dart run drift_dev make-migrations` with the note "after changing the schema and bumping schemaVersion".

- [ ] **Step 4: Verify** the full gate; `flutter test` includes any generated migration test. Expected: all green, coverage check passed.

- [ ] **Step 5: Commit** `chore(steps): drift migration tooling at schema v1` and `docs: local storage in ADR 0001, architecture and roadmap`; push; open the PR.

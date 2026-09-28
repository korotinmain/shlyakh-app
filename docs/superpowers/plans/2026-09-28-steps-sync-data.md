# Steps sync data layer (PR 2 of 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Everything the HealthKit → Drift sync needs below the UI: the journey start in Drift (schema v2), the pure rules for what to query and what to write, `StepsSync.sync()` and a Drift-backed `StepsRepository`.

**Architecture:** Pure domain functions (`syncFrom`, `mergeDays`) decide the query start and the days to write; `StepsSync` (data layer) runs one sync at a time through `HealthKitStepsSource` (PR 1), `JourneyStartDao` and `DailyStepsDao`, turns storage errors into `StorageFailure` and logs failures instead of throwing them. `DriftStepsRepository` exposes Drift through the existing `StepsRepository`. Nothing calls the sync yet; providers, triggers and UI are PR 3.

**Tech Stack:** Dart, Drift 2.35 (`drift_dev make-migrations`), Pigeon 29, mocktail, `package:clock`.

**Spec:** `docs/superpowers/specs/2026-09-28-healthkit-steps-sync-design.md` (Components → Data, Domain; Data flow 1–3, 5; Errors; Testing → Domain, Data; Delivery PR 2).

## Global Constraints

- Domain code is pure Dart: no Flutter, no Drift, no `DateTime.now()` (CLAUDE.md, ADR 0002); time comes in as parameters.
- Local days are `LocalDate`; the journey start is a UTC instant plus an IANA zone (spec, Decisions).
- The re-query window is 7 days (spec, Data flow 2).
- A stored day whose zone differs from the fetched day's zone is never overwritten (spec, Data flow 3).
- Upsert replaces, also with a lower count; the app never edits counts (AGENT_RULES 6).
- Logs carry no steps, dates or ids; `LogValue.count` is a number of days only (AGENT_RULES 5, ADR 0006). Events are declared only in `lib/core/logging/log_events.dart`.
- Repositories/sync catch only specific exceptions and turn them into `Failure`s; programmer errors are never caught (ADR 0005).
- Drift schema change: bump `schemaVersion`, run `dart run drift_dev make-migrations`, commit the snapshot, the generated steps and tests (ADR 0001). Read the drift_dev 2.35 `make-migrations` docs in the package before running it.
- Swift is not built in CI: any Swift change ends with local `flutter build ios --simulator --debug` and `xcodebuild test … -only-testing:RunnerTests`.

## Review Focus

- The journey started less than 7 days ago → later syncs query from the start instant, not from before it (no days before the start are ever written). Tested in Task 2 (`syncFrom`).
- A zone change between two syncs (flight Kyiv → Lisbon) → days counted in Kyiv stay as stored; new days are written in Lisbon. Tested in Task 2 (`mergeDays`) and Task 5.
- The same sync result twice → nothing is written the second time (no Drift churn, no UI rebuild). Tested in Task 2 and Task 5.
- A burst of `sync()` calls while one runs → exactly two runs, and every caller's future completes. Tested in Task 5.
- HealthKit locked or unavailable in a sync → stored days unchanged, `sync()` completes normally, the failure is logged by variant only. Tested in Task 5.

## Rulings carried from the spec

- Spec "Log events … `stepsSyncFailed` (`kind`)": a `Failure` is not an `Enum`, so failures go through the existing `AppLogger.failure(failure)` (variant name only); only `StepsSyncCompleted` is a new event.
- Review minor from PR 1 ("days and time zone from two native calls"): fixed here in Task 1, because `mergeDays` relies on the zone.
- `mergeDays` also skips a fetched day identical to the stored one (same steps and zone), so a repeated sync writes nothing.

---

### Task 1: Days and zone from one native call

**Files:**
- Modify: `pigeons/steps_api.dart` → `dailySteps` returns `NativeDays`
- Regenerate: `ios/Runner/Steps/StepsApi.g.swift` (committed), Dart output (ignored, then `dart format` it)
- Modify: `ios/Runner/Steps/StepsHost.swift`
- Modify: `lib/features/steps/data/healthkit/health_kit_steps_source.dart`
- Test: `test/features/steps/data/healthkit/health_kit_steps_source_test.dart`

**Interfaces:**
- Produces (Pigeon): `class NativeDays { String timeZoneId; List<NativeDay> days; }`; `@async NativeDays dailySteps(int fromEpochMs)`. `timeZoneId()` stays for other callers.
- Produces (Dart): `HealthKitStepsSource.dailySteps` unchanged in signature; each day's `timezone` is `NativeDays.timeZoneId`; it no longer calls `timeZoneId()`.

- [ ] **Step 1: Failing tests** — update the source tests: the mock's `dailySteps` returns `NativeDays(timeZoneId: 'Europe/Lisbon', days: [...])` and the day's `timezone` is `'Europe/Lisbon'` even when `timeZoneId()` would return `'Europe/Kyiv'`; `verifyNever(() => api.timeZoneId())` in the `dailySteps` tests; empty `days` → `[]`.
- [ ] **Step 2:** Change the Pigeon definition, regenerate, `flutter test test/features/steps/data/healthkit` — FAIL.
- [ ] **Step 3:** `StepsHost.dailySteps` returns `NativeDays(timeZoneId: calendar.timeZone.identifier, days: …)` from the same `calendar` it queries with (also for the empty result); update the source.
- [ ] **Step 4:** Dart tests PASS; `flutter build ios --simulator --debug` builds; `xcodebuild test … -only-testing:RunnerTests` PASS.
- [ ] **Step 5:** Commit `feat(steps): days and their time zone from one native call`.

### Task 2: Domain — journey start, `syncFrom`, `mergeDays`

**Files:**
- Create: `lib/features/steps/domain/journey_start.dart`, `lib/features/steps/domain/sync_rules.dart`
- Test: `test/features/steps/domain/sync_rules_test.dart`

**Interfaces:**
- Produces:
  - `typedef JourneyStart = ({String userId, DateTime startedAt, String timezone});` — `startedAt` is UTC.
  - `const int syncWindowDays = 7;`
  - `DateTime syncFrom({required JourneyStart start, required DateTime now, required bool hasStoredDays, int windowDays = syncWindowDays})` — `now` is local wall-clock time. Returns `start.startedAt` when `!hasStoredDays`; otherwise the later instant of `start.startedAt` and `DateTime(now.year, now.month, now.day - windowDays)` (local midnight).
  - `List<DailySteps> mergeDays({required List<DailySteps> stored, required List<DailySteps> fetched})` — returns the fetched days to write, in fetched order: a day with no stored row; a day whose stored row has the same zone and a different count. Skips a day whose stored row has another zone, or the same zone and count. Asserts all days share one `userId`.

- [ ] **Step 1: Failing tests** (`now = DateTime(2026, 9, 28, 12)` local unless stated):
  - `first sync starts at the journey start`: `hasStoredDays: false`, start `DateTime.utc(2026, 9, 1, 8)` → that instant.
  - `later syncs re-query seven days`: start 2026-09-01, `hasStoredDays: true` → `DateTime(2026, 9, 21)`.
  - `a start inside the window wins`: start `DateTime.utc(2026, 9, 26, 7, 20)` → that instant.
  - `the window follows local midnight across DST`: `now = DateTime(2026, 10, 27, 9)`, start 2026-09-01 → `DateTime(2026, 10, 20)`.
  - `mergeDays writes new days`; `writes a changed count, also lower` (stored 5000 → fetched 4200); `skips an identical day`; `keeps a day counted in another zone` (stored Kyiv 2026-09-27, fetched Lisbon 2026-09-27 → not written; fetched Lisbon 2026-09-28 with no stored row → written).
- [ ] **Step 2:** `flutter test test/features/steps/domain` — FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** PASS; domain coverage 100%.
- [ ] **Step 5:** Commit `feat(steps): sync rules for the query start and the days to write`.

### Task 3: `journey_start` table, DAO and schema v2

**Files:**
- Create: `lib/features/steps/data/local/journey_start_table.dart`, `lib/features/steps/data/local/journey_start_dao.dart`
- Modify: `lib/core/database/app_database.dart` (table, DAO, `schemaVersion => 2`, migration)
- Generated and committed: `drift_schemas/app_database/drift_schema_v2.json`, the steps file and `test/drift/app_database/…` tests that `make-migrations` writes
- Test: `test/features/steps/data/local/journey_start_dao_test.dart`

**Interfaces:**
- Produces:
  - Table `journey_start`: `user_id TEXT` primary key, `started_at INTEGER` (UTC milliseconds), `timezone TEXT`; STRICT; `CHECK (user_id <> '')`, `CHECK (timezone <> '')`, `CHECK (started_at >= 0)`. Row class `JourneyStartRow`.
  - `JourneyStartDao` (`db.journeyStartDao`): `Future<JourneyStart?> get(String userId)`; `Stream<JourneyStart?> watch(String userId)`; `Future<bool> insertOnce(JourneyStart start)` — true when inserted, false when a start exists (never overwrites); `Future<int> deleteForUser(String userId)` (account deletion, AGENT_RULES 5).
  - Migration 1 → 2 creates `journey_start` only; `daily_steps` untouched.

- [ ] **Step 1: Failing tests** (in-memory `AppDatabase(NativeDatabase.memory())`): `insertOnce stores a start` (round trip keeps the UTC instant to the millisecond and `isUtc`); `insertOnce never overwrites` (second call returns false, first value stays); `get returns null for another user`; `watch emits null, then the start`; `deleteForUser removes only that user`; `an empty zone is rejected by the database` (raw insert → `SqliteException`).
- [ ] **Step 2:** `flutter test test/features/steps/data/local` — FAIL.
- [ ] **Step 3:** Implement table and DAO; register them; bump `schemaVersion`; `dart run build_runner build --delete-conflicting-outputs`; `dart run drift_dev make-migrations`; wire the generated step (`from1To2` creates `journey_start`) into `migration.onUpgrade`.
- [ ] **Step 4:** DAO tests PASS; the generated migration tests in `test/drift/` PASS (v1 → v2 keeps `daily_steps` rows).
- [ ] **Step 5:** Commit `feat(steps): journey start table and schema v2`.

### Task 4: `DriftStepsRepository`

**Files:**
- Create: `lib/features/steps/data/drift_steps_repository.dart`
- Test: `test/features/steps/data/drift_steps_repository_test.dart`

**Interfaces:**
- Consumes: `DailyStepsDao.watchForUser`.
- Produces: `final class DriftStepsRepository implements StepsRepository`, `new(DailyStepsDao days)`; `watchDays` delegates to `watchForUser` with the same bounds.

- [ ] **Step 1: Failing tests:** `emits the stored days in range, oldest first`; `emits again after an upsert`.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(steps): Drift-backed steps repository`.

### Task 5: `StepsSync`

**Files:**
- Create: `lib/features/steps/data/sync/steps_sync.dart`
- Modify: `lib/core/logging/log_events.dart` (`StepsSyncCompleted`)
- Test: `test/features/steps/data/sync/steps_sync_test.dart`

**Interfaces:**
- Consumes: `HealthKitStepsSource.dailySteps` (Task 1), `syncFrom`, `mergeDays` (Task 2), `JourneyStartDao.get` (Task 3), `DailyStepsDao.watchForUser` / `upsert`.
- Produces:
  - `final class StepsSyncCompleted extends LogEvent` — `name => 'steps_sync_completed'`, fields `duration` (`LogValue.duration`) and `days_written` (`LogValue.count`).
  - `final class StepsSync`, `new({required HealthKitStepsSource source, required JourneyStartDao starts, required DailyStepsDao days, required Clock clock, required AppLogger logger, required String userId})`; `Future<void> sync()`.

Behaviour of one run: no journey start → return, nothing logged. Else `stored = watchForUser(userId).first`; `from = syncFrom(start, clock.now(), hasStoredDays: stored.isNotEmpty)`; `fetched = source.dailySteps(userId, from)`; `write = mergeDays(stored: stored with date ≥ LocalDate.fromDateTime(from.toLocal()), fetched)`; upsert all in one transaction; log `StepsSyncCompleted`. A `Failure` from the source → `logger.failure(f)`, nothing written. `SqliteException` (from `package:drift/native.dart`) during the run → `logger.failure(StorageFailure(cause: e))`. Any other error propagates. `sync()` while a run is in progress sets "run again" and returns the in-flight future; a run loops while "run again" is set, so a burst gives at most two runs.

- [ ] **Step 1: Failing tests** (in-memory db, mocktail `HealthKitStepsSource`, `Clock.fixed(DateTime(2026, 9, 28, 12))`, `RecordingLogger`):
  - `without a journey start nothing happens` (source never called, no events).
  - `first sync queries from the start and writes the days`.
  - `a later sync queries seven days back` (verify the `from` passed to the source).
  - `the partial first day is stored as returned`.
  - `a lower count replaces the stored one`.
  - `a day counted in another zone is kept`.
  - `a repeated identical sync writes nothing` (`days_written` 0 on the second event).
  - `HealthDataLocked leaves the stored days and is logged` (`logger.failures` single `HealthDataLocked`, `sync()` completes normally).
  - `a storage error becomes StorageFailure` (drop `daily_steps` with `customStatement` before the sync).
  - `a burst of calls runs twice` (source completes via a `Completer`; three `sync()` calls → source called twice, all three futures complete).
  - `the completed event carries no steps or dates` (fields are exactly `duration` and `days_written`).
- [ ] **Step 2:** `flutter test test/features/steps/data/sync` — FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** PASS; `test/core/logging/logging_policy_test.dart` still PASS.
- [ ] **Step 5:** Commit `feat(steps): sync from HealthKit to Drift`.

### Task 6: Docs, full gate, PR

**Files:**
- Modify: `docs/ARCHITECTURE.md` — §2: journey start table (schema v2), `StepsSync`, `DriftStepsRepository`, nothing calls them yet; decision table unchanged.

- [ ] **Step 1:** Update ARCHITECTURE.md.
- [ ] **Step 2:** Full gate with `lib/main_preview.dart` moved out of `lib/`: `dart format --output=none --set-exit-if-changed .`, `dart analyze --fatal-infos`, `flutter test --coverage`, `dart run tool/coverage/check_coverage.dart` — all pass (domain 100%, data ≥ 85%).
- [ ] **Step 3:** Commit `docs: steps sync data layer in architecture`; push `feat/steps-sync`; open the PR (nothing calls the sync yet; the background-Dart device result is still pending and affects PR 3 only).

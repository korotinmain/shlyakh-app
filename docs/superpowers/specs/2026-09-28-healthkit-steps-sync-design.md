# HealthKit → Drift steps sync — design

Date: 2026-09-28
Status: approved in chat, pending spec review

## Goal

Replace `DemoStepsRepository` with real step totals from HealthKit, so the
app can be installed on our iPhones: the Today screen shows the same steps
as the Health app, kept up to date in the background while the app is
closed, offline and without an account.

## Success criteria

- On a real iPhone with an Apple Watch, the daily totals since the journey
  start match the Health app (except the partial first day, see below).
- After a walk with the app closed, Drift is updated within about an hour
  (ADR 0007) without opening the app.
- The Today screen updates by itself after every sync.
- No step counts, dates or ids in logs (AGENT_RULES 5, ADR 0006).
- Coverage thresholds hold: data and `presentation/providers/` ≥ 85%,
  domain 100%.

## Decisions (from the conversation)

| Topic | Decision |
|---|---|
| Health access UX | An explanation screen with an "Allow" button before the system prompt. On Today, a hint "check access in Health → Data Access" when at least a day has passed since the start and there are no steps at all (iOS never tells an app that read access was denied) |
| History | The journey starts when the user taps "Allow"; nothing before it is imported |
| First day | Only steps after the start moment count; the first day is partial and differs from the Health app's day total |
| Start moment | The UTC instant of the "Allow" tap and the IANA time zone at that moment, stored in Drift |
| iCloud backup | The database stays in the default iCloud backup, so a restore to a new iPhone keeps the journey. Steps are already in iCloud through Health; only the start moment is new |
| Reinstall before stage 5 | Deleting the app deletes the database, so the journey starts again. Accepted until Supabase keeps the start moment |
| Integration | All HealthKit access in Swift, exposed to Dart through Pigeon. No `health` plugin |
| Dependency | `pigeon` in `dev_dependencies` (approved); the generated Swift is committed (ADR 0001) |
| User id | `currentUserIdProvider` stays `'local'` until registration; registration will move the rows to the real id (stage 5) |

## Components

### Native (Swift, `ios/Runner/Steps/`)

- Pigeon definition in `pigeons/steps_api.dart`; generated
  `ios/Runner/Steps/StepsApi.g.swift` and
  `lib/features/steps/data/healthkit/steps_api.g.dart`.
- `StepsHostApi` (Dart → Swift):
  - `isAvailable() → bool`: `HKHealthStore.isHealthDataAvailable()`.
  - `requestAccess()`: requests read access to step count only; the
    result says nothing about what the user chose. Restarts the observer
    afterwards (an observer started before access fails, ADR 0007).
  - `dailySteps(fromEpochMs) → List<NativeDay(localDate, steps)>`: one
    `HKStatisticsCollectionQuery` (cumulative sum, daily intervals
    anchored at local midnight of `Calendar.current`) from `fromEpochMs`
    to the end of today. When `fromEpochMs` is not a local midnight, the
    first interval runs from that instant to the next midnight. Every day
    in the range is returned, with 0 when there are no samples. Fractional
    sums are truncated, like the Health app.
  - `timeZoneId() → String`: `TimeZone.current.identifier`.
- `StepsEventsApi` (Swift → Dart, async): `onStepsChanged()` completes
  when Dart has finished the sync it triggered.
- `StepsObserver`: an `HKObserverQuery` on step count registered in
  `application(_:didFinishLaunchingWithOptions:)` on every launch, with
  `enableBackgroundDelivery(for:frequency: .hourly)`. Its callback calls
  `onStepsChanged()` and calls HealthKit's completion handler only when
  Dart replies, or after a 20-second timeout, whichever comes first.
- Pure helpers in their own file, tested with XCTest in `RunnerTests`: the
  day intervals for a start instant (partial first day, DST days) and the
  truncation of a sum.
- Errors reach Dart as `PigeonError` codes: `unavailable` when HealthKit
  is not available, `locked` for `HKError.errorDatabaseInaccessible` (the
  device is locked); anything else keeps HealthKit's own code.
- Entitlements `com.apple.developer.healthkit` and
  `com.apple.developer.healthkit.background-delivery` (as in the spike);
  `NSHealthShareUsageDescription` in `Info.plist`, localized in uk and en
  through `InfoPlist.strings`.

### Data (Dart, `lib/features/steps/data/`)

- `healthkit/health_kit_steps_source.dart` — `HealthKitStepsSource`: wraps
  `StepsHostApi`; maps known `PlatformException` codes to `Failure`
  (`unavailable` → `HealthUnavailable`, `locked` → `HealthDataLocked`);
  unknown codes are rethrown (ADR 0005). Returns `DailySteps` with the
  current user id and time zone.
- `local/journey_start_table.dart` and `JourneyStartDao`: table
  `journey_start (user_id TEXT PK, started_at INTEGER UTC ms, timezone
  TEXT)`, STRICT, CHECK non-empty ids. Schema v2 with a Drift migration
  (`drift_dev make-migrations`, snapshot committed). Methods: `get`,
  `watch`, `insertOnce` (never overwrites an existing start).
- `sync/steps_sync.dart` — `StepsSync.sync()`, see Data flow.
- `drift_steps_repository.dart` — `DriftStepsRepository` implements the
  existing `StepsRepository` through `DailyStepsDao.watchForUser`.
- Removed: `demo/demo_steps_repository.dart` and its tests. The local,
  uncommitted `lib/main_preview.dart` overrides `stepsRepositoryProvider`
  with its own demo data for simulator previews (the simulator has no
  Health data).

### Domain (`lib/features/steps/domain/`)

- `JourneyStart` (`userId`, `startedAt` UTC instant, `timezone`).
- `syncFrom(start, now, window, hasStoredDays)`: the instant to query
  from — the start instant when no day is stored yet (the first sync),
  otherwise the later of the start instant and local midnight `window`
  days before today. Pure, 100% tested.
- `mergeDays(stored, fetched, currentTimezone)`: which fetched days to
  upsert — new days and stored days of the current zone are written; a
  stored day counted in a different zone is kept. Pure, 100% tested.

### Presentation

- `HealthAccessScreen` (`/health-access`): explanation, "Allow" button;
  on tap: insert the journey start, `requestAccess()`, first sync, go to
  Today. When HealthKit is unavailable it shows the `HealthUnavailable`
  message instead of the button.
- Router redirect: to `/health-access` while there is no journey start;
  from it to Today once there is.
- `stepsSyncProvider`: runs `StepsSync.sync()` on app start (when a
  journey start exists), on return to the foreground
  (`AppLifecycleListener`) and on `onStepsChanged`.
- `healthAccessHintProvider`: true when at least 24 hours have passed
  since the start and every stored day has 0 steps. Today shows the hint
  text under the card; tapping it does nothing (iOS offers no deep link to
  an app's Health permissions).
- `stepsRepositoryProvider` returns `DriftStepsRepository`.

## Data flow

1. **First sync** (after "Allow"): from the start instant to the end of
   today; the first day is partial.
2. **Later syncs**: from `syncFrom(start, now, 7 days)`. The last seven
   days are re-queried every time: Watch data can arrive hours or days
   late and the user can delete samples in Health. Upsert replaces, also
   with a lower count (HealthKit is the source of truth; the app never
   edits counts).
3. **Time zones**: every day is stored with the zone it was counted in.
   `mergeDays` does not overwrite a stored day whose zone differs from the
   current one, so days counted before a flight keep their local
   boundaries. On the travel day a slice can be counted twice or missed;
   accepted and recorded in ADR 0008.
4. **Background**: HealthKit wakes the app → `StepsObserver` →
   `onStepsChanged()` → Dart `sync()` → Drift → reply → completion
   handler. Whether Dart gets enough time in a background wakeup is
   verified on the device (ADR 0007, open question).
5. **Concurrency**: a `sync()` call while one is running does not start a
   second one; it marks "run once more", so any burst of triggers causes at
   most two syncs.
6. **UI**: `watchDays` is a Drift stream; the Today screen updates after
   every upsert without a separate signal. XP and levels are unchanged:
   the database only holds days from the start.

## Errors

| Case | Behaviour |
|---|---|
| HealthKit unavailable | `HealthUnavailable`; the access screen shows its message; no sync |
| Read access denied | Not detectable; days are 0; the hint appears after 24 hours |
| Query while the device is locked | New `HealthDataLocked`; the sync ends, stored days stay, the next trigger retries |
| Drift error | `StorageFailure` (existing) |
| Unknown native error code | Not caught: a bug, reaches the unhandled error handler |

A failed sync is never shown as a full-screen error: the UI reads Drift,
at worst slightly stale. Log events (ADR 0006): `stepsSyncCompleted`
(`duration`, `count` of days written) and `stepsSyncFailed` (`kind` of
failure). No steps, dates or ids.

## Testing

- **Domain:** `syncFrom` (first sync, window, start inside the window, DST
  day), `mergeDays` (same zone, other zone, new day).
- **Data**, fake `StepsHostApi` (mocktail) and in-memory Drift:
  `HealthKitStepsSource` error mapping; `JourneyStartDao.insertOnce`;
  migration v1 → v2 (generated test and snapshot); `StepsSync`: first
  sync range, window range, partial first day stored as returned, zero
  days, lower count replaces, other-zone day kept, `HealthDataLocked`
  leaves data unchanged, a burst of calls runs twice; log events.
- **Providers and widgets:** redirect without a start; "Allow" writes the
  start, requests access and opens Today; unavailable HealthKit; hint
  condition (23 h / 25 h, zero / non-zero); sync on start and on resume.
- **Swift (XCTest):** day intervals and truncation helpers.
- **On the iPhone (checklist in the plan):** seven daily totals match
  Health; the partial first day; how a sample that spans the start
  instant is counted (recorded in ADR 0008); a background sync writes to
  Drift with the app closed (temporary journal of times and results only,
  removed before merge).

## Delivery

Three PRs, each passing CI:

1. **Native and source:** Pigeon definitions and generated code, Swift
   host API, observer, XCTest helpers, `HealthKitStepsSource`,
   `HealthDataLocked`, `Info.plist` and entitlements.
2. **Data:** schema v2 with `journey_start`, `JourneyStartDao`, domain
   `syncFrom`/`mergeDays`, `StepsSync`, `DriftStepsRepository`, log
   events.
3. **UI and triggers:** `HealthAccessScreen`, redirect, hint, sync
   triggers, provider switch, demo removal, device checklist, docs.

The app is not installed on the phones before PR 3.

## Documentation

- ADR 0008: journey start moment, partial first day, 7-day re-query
  window, time-zone rule, completion handler after Dart, the device
  finding on samples spanning the start.
- PRODUCT.md: the journey starts at "Allow"; the first day is partial; no
  import of earlier history.
- ARCHITECTURE.md: sections 2 and 4 (Pigeon instead of the `health`
  plugin; the sync); decision table.
- CLAUDE.md, Stack: "Health data: native Swift (HealthKit) through Pigeon".
- ROADMAP: stage 2 "Repository: HealthKit to Drift sync"; stage 4 items
  already done in phase C (theme and tokens, ring, sheet).

## Out of scope

- Registration and moving `'local'` rows to a real user id (stage 5).
- Supabase sync of days and the start moment (stage 5).
- Deep link to Health settings (iOS has none for an app's permissions).
- Android.

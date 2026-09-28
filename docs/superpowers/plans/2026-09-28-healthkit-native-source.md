# HealthKit native layer and steps source (PR 1 of 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A typed Dart API over native HealthKit (access request, daily step totals from any start instant, time zone, observer with background delivery), ready for the sync in PR 2.

**Architecture:** All HealthKit code is Swift in `ios/Runner/Steps/`, exposed through Pigeon (`StepsHostApi` Dart → Swift, `StepsEventsApi` Swift → Dart). `HealthKitStepsSource` in `lib/features/steps/data/healthkit/` wraps the generated Dart API and turns native error codes into `Failure`s. Nothing in the app calls it yet; PR 2 adds the sync, PR 3 the UI and triggers.

**Tech Stack:** Swift / HealthKit, Pigeon 29 (dev dependency, approved), Dart, mocktail, XCTest.

**Spec:** `docs/superpowers/specs/2026-09-28-healthkit-steps-sync-design.md` (sections "Native", "Data" → `HealthKitStepsSource`, "Errors"; Delivery PR 1).

## Global Constraints

- Read the Pigeon API from the installed source before writing definitions (`~/.pub-cache/hosted/pub.dev/pigeon-29.*/`, CHANGELOG); do not write it from memory (CLAUDE.md).
- `pigeon` goes in `dev_dependencies` only; no other new dependency.
- Generated Dart (`*.g.dart`) is not committed; generated Swift (`*.g.swift`) is (ADR 0001). Never hand-edit either.
- Read access to `HKQuantityType(.stepCount)` only; no write access (AGENT_RULES 5).
- Never log or put into error messages step counts, dates or ids (AGENT_RULES 5, ADR 0006). `PigeonError.message` is always nil.
- Fractional sums are truncated (`Int64(sum.rounded(.towardZero))`), never rounded (ADR 0007).
- Collection query: cumulative sum, daily intervals anchored at local midnight of `Calendar.current`, predicate `.strictStartDate`.
- Background delivery at `.hourly` (ADR 0007).
- Error codes: `unavailable` (HealthKit not available, `HKError.errorHealthDataUnavailable`), `locked` (`HKError.errorDatabaseInaccessible`), otherwise `healthkit` with the `HKError.Code` raw value as `details`.
- Swift is not built in CI (Ubuntu): every Swift task ends with a local `flutter build ios --simulator --debug` and, where tests exist, `xcodebuild test`.

## Review Focus

- A start instant after the end of today (clock skew, stored start in the future) → `dailySteps` returns an empty list, no crash. Tested in Task 3 (Swift) and Task 2 (Dart).
- The DST day (Europe/Kyiv, 2026-10-25, 25 hours) → exactly one entry for that date, the next day starts at its own midnight. Tested in Task 3.
- The observer fires in a cold background launch before Dart has registered `StepsEventsApi` (it never does in PR 1) → HealthKit's completion handler is still called exactly once, within 20 s. Tested through `OnceCompletion` in Task 3.
- An unknown native error code → rethrown as is, not turned into a `Failure` or swallowed (ADR 0005). Tested in Task 2.
- A sum like 0.9 or 1234.99 → 0 and 1234 (truncation, matches Health). Tested in Task 3.

---

### Task 1: `HealthDataLocked` failure

**Files:**
- Modify: `lib/core/error/failure.dart`
- Modify: `lib/core/error/failure_message.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_uk.arb`
- Test: `test/core/error/failure_message_test.dart`

**Interfaces:**
- Produces: `final class HealthDataLocked extends Failure` (`const new({super.cause})`, `variantName == 'HealthDataLocked'`); ARB key `errorHealthDataLocked`.

- [ ] **Step 1: Failing tests** — in `failure_message_test.dart`, add `HealthDataLocked()` to the existing message cases (en: "Unlock your iPhone to update your steps.", uk: "Розблокуй iPhone, щоб оновити кроки.") and `(const HealthDataLocked(), 'HealthDataLocked')` to the `variantName` group.
- [ ] **Step 2:** `flutter test test/core/error` — FAIL (undefined `HealthDataLocked`).
- [ ] **Step 3:** Add the class after `HealthUnavailable` with the doc comment "HealthKit data is encrypted while the device is locked; a background read failed." Add the ARB entries with `@` descriptions ("A background step update failed because the iPhone was locked."), the `failureMessage` case, run `flutter gen-l10n`.
- [ ] **Step 4:** `flutter test test/core/error` — PASS; `dart analyze --fatal-infos` — no issues.
- [ ] **Step 5:** Commit `feat(core): HealthDataLocked failure`.

### Task 2: Pigeon definitions and `HealthKitStepsSource`

**Files:**
- Modify: `pubspec.yaml` (`pigeon: ^29.0.4` in `dev_dependencies`)
- Create: `pigeons/steps_api.dart`
- Generated: `lib/features/steps/data/healthkit/steps_api.g.dart` (ignored), `ios/Runner/Steps/StepsApi.g.swift` (committed)
- Create: `lib/features/steps/data/healthkit/health_kit_steps_source.dart`
- Modify: `.github/workflows/ci.yml` (step `dart run pigeon --input pigeons/steps_api.dart` right after build_runner)
- Modify: `CLAUDE.md` (Commands: the pigeon line; Stack: "Health data: native Swift (HealthKit) through Pigeon"; Library versions: drop `health 13`)
- Test: `test/features/steps/data/healthkit/health_kit_steps_source_test.dart`

**Interfaces:**
- Produces (Pigeon, `pigeons/steps_api.dart`):
  - `class NativeDay { String localDate; int steps; }` — `localDate` is `yyyy-MM-dd` in `Calendar.current`.
  - `@HostApi() abstract class StepsHostApi { bool isAvailable(); @async void requestAccess(); @async List<NativeDay> dailySteps(int fromEpochMs); String timeZoneId(); }`
  - `@FlutterApi() abstract class StepsEventsApi { @async void onStepsChanged(); }`
- Produces (Dart): `final class HealthKitStepsSource`, `new(StepsHostApi api)`:
  - `Future<bool> isAvailable()`
  - `Future<void> requestAccess()`
  - `Future<List<DailySteps>> dailySteps({required String userId, required DateTime from})` — passes `from.millisecondsSinceEpoch`; every day gets `userId` and the zone from one `timeZoneId()` call made per `dailySteps` call.
  - `Future<String> timeZoneId()`
  - Every method maps `PlatformException` code `unavailable` → `HealthUnavailable(cause: e)`, `locked` → `HealthDataLocked(cause: e)`, rethrows any other code.

- [ ] **Step 1:** Add `pigeon`, `flutter pub get`, read the Pigeon 29 README/CHANGELOG for `@ConfigurePigeon`, `@async` and the generated Swift shapes; write `pigeons/steps_api.dart` with `dartOut`/`swiftOut` above and a header comment with the regenerate command; run `dart run pigeon --input pigeons/steps_api.dart`.
- [ ] **Step 2: Failing tests** (mocktail `class _Api extends Mock implements StepsHostApi`):
  - `dailySteps maps native days`: api returns `[NativeDay(localDate: '2026-09-28', steps: 6870)]`, `timeZoneId` returns `'Europe/Kyiv'` → `[(userId: 'local', localDate: LocalDate.parse('2026-09-28'), timezone: 'Europe/Kyiv', steps: 6870)]`.
  - `dailySteps passes the start as epoch ms`: `from: DateTime.utc(2026, 9, 28, 15, 30)` → `verify(() => api.dailySteps(1790609400000))`.
  - `dailySteps with no days returns an empty list`.
  - `locked maps to HealthDataLocked` (`PlatformException(code: 'locked')` from `dailySteps`, check `cause` is the exception).
  - `unavailable maps to HealthUnavailable` (from `requestAccess` and from `isAvailable`).
  - `an unknown code is rethrown` (`code: 'healthkit'` → `throwsA(isA<PlatformException>())`).
- [ ] **Step 3:** `flutter test test/features/steps/data/healthkit` — FAIL (no source class).
- [ ] **Step 4:** Implement `HealthKitStepsSource`; one private `Future<T> _guard<T>(Future<T> Function())` holds the mapping.
- [ ] **Step 5:** `flutter test test/features/steps/data/healthkit` — PASS. `dart analyze --fatal-infos` — no issues (if the generated file trips lints, confirm `analysis_options.yaml` excludes `**/*.g.dart` and exclude it there). Delete generated Dart and rerun the CI order (`flutter pub get`, build_runner, pigeon, analyze) to prove CI can build it.
- [ ] **Step 6:** Commit `feat(steps): Pigeon steps API and HealthKit steps source` (includes `StepsApi.g.swift`, CI, CLAUDE.md).

### Task 3: Swift day helpers with XCTest

**Files:**
- Create: `ios/Runner/Steps/StepsDays.swift`, `ios/Runner/Steps/OnceCompletion.swift`
- Modify: `ios/Runner.xcodeproj/project.pbxproj` — a `Steps` group under `Runner` with every file in `ios/Runner/Steps/` (including `StepsApi.g.swift`) in the Runner target's Sources; done with a one-off Ruby script using the installed `xcodeproj` gem (script kept in the scratchpad, not committed).
- Modify: `ios/RunnerTests/RunnerTests.swift` → replace the template test with `StepsDaysTests.swift` and `OnceCompletionTests.swift` (both in the RunnerTests target).

**Interfaces:**
- Produces:
  - `enum StepsDays`:
    - `static func queryRange(from: Date, now: Date, calendar: Calendar) -> (dayStart: Date, from: Date, end: Date)?` — `dayStart` is the start of the day containing `from` (enumeration start and anchor), `end` is the start of the day after `now`; nil when `from >= end`.
    - `static func localDateString(_ date: Date, calendar: Calendar) -> String` — `yyyy-MM-dd`, `en_US_POSIX`, the calendar's zone.
    - `static func truncatedSteps(_ sum: Double) -> Int64`
  - `final class OnceCompletion` — `init(timeout: TimeInterval, queue: DispatchQueue, completion: @escaping () -> Void)`; `func fire()`; the completion runs exactly once: on the first `fire()` or when the timeout elapses.

- [ ] **Step 1: Failing XCTests** (calendar with `TimeZone(identifier: "Europe/Kyiv")`):
  - `testRangeFromMidday`: from 2026-09-28 15:30 local, now 2026-09-28 18:00 → `dayStart` 2026-09-28 00:00, `from` unchanged, `end` 2026-09-29 00:00.
  - `testRangeOverSeveralDays`: from 2026-09-21 00:00, now 2026-09-28 09:00 → `end` 2026-09-29 00:00.
  - `testRangeFromFutureIsNil`: from 2026-09-29 00:00, now 2026-09-28 23:59 → nil.
  - `testDstDayHasItsOwnDate`: `localDateString` of 2026-10-25 00:00 and of 2026-10-25 23:30 local are both `"2026-10-25"`; `calendar.date(byAdding: .day, value: 1, to: 2026-10-25 00:00)` gives `"2026-10-26"` (25-hour day).
  - `testTruncation`: 0.9 → 0, 1234.99 → 1234, 0 → 0.
  - `testOnceCompletionFiresOnce`: `fire()` twice → completion count 1.
  - `testOnceCompletionTimesOut`: no `fire()`, timeout 0.05 → completion within 1 s (expectation); a later `fire()` does not call it again.
- [ ] **Step 2:** Add the files to the Xcode project (script above); `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:RunnerTests` — FAIL (types missing). Run `flutter build ios --simulator --debug` once first if the workspace lacks Flutter build products.
- [ ] **Step 3:** Implement both files.
- [ ] **Step 4:** The same `xcodebuild test` — PASS.
- [ ] **Step 5:** Commit `feat(ios): day ranges, truncation and once-only completion for HealthKit`.

### Task 4: `StepsHost` (host API), entitlements, usage text

**Files:**
- Create: `ios/Runner/Steps/StepsHost.swift` (in the `Steps` group, Runner target)
- Create: `ios/Runner/Runner.entitlements` (`com.apple.developer.healthkit` true, `com.apple.developer.healthkit.access` absent, `com.apple.developer.healthkit.background-delivery` true); `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` for Debug, Profile, Release
- Modify: `ios/Runner/Info.plist` (`NSHealthShareUsageDescription`, English)
- Create: `ios/Runner/en.lproj/InfoPlist.strings`, `ios/Runner/uk.lproj/InfoPlist.strings` (variant group `InfoPlist.strings` in Runner resources)
- Modify: `ios/Runner/AppDelegate.swift` (register the host API in `didInitializeImplicitFlutterEngine`)

**Interfaces:**
- Consumes: `StepsDays` (Task 3), generated `StepsHostApi` protocol and `StepsHostApiSetup` (Task 2).
- Produces: `final class StepsHost: StepsHostApi` with `static let shared`, owning the one `HKHealthStore`; `requestAccess` calls `StepsObserver.shared.start()` after the prompt (Task 5 adds `StepsObserver`; until then leave this call out and add it in Task 5).

Usage text (exact):
- en: "Shlyakh reads your step count to turn your walks into progress along the path. It never writes to Health."
- uk: "Шлях читає кількість твоїх кроків, щоб перетворювати прогулянки на поступ шляхом. Він нічого не записує в Health."

- [ ] **Step 1:** Implement `StepsHost`: `isAvailable` → `HKHealthStore.isHealthDataAvailable()`; `requestAccess` → `unavailable` when not available, else `requestAuthorization(toShare: [], read: [stepType])`; `dailySteps(fromEpochMs:)` → `StepsDays.queryRange(from:now: Date(), calendar: .current)`, empty list for nil, else one `HKStatisticsCollectionQuery` (predicate `from…end`, `.strictStartDate`, anchor `dayStart`, interval 1 day), `enumerateStatistics(from: dayStart, to: end)` → `NativeDay(localDate: localDateString(stats.startDate), steps: truncatedSteps(sum ?? 0))`; `timeZoneId` → `TimeZone.current.identifier`; HealthKit errors mapped per Global Constraints.
- [ ] **Step 2:** Entitlements, `Info.plist`, `InfoPlist.strings`, `AppDelegate` registration (`StepsHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: StepsHost.shared)` via `engineBridge.pluginRegistry.registrar(forPlugin: "StepsHost")`).
- [ ] **Step 3:** `flutter build ios --simulator --debug` — builds; `xcodebuild test … -only-testing:RunnerTests` — still PASS; `plutil -lint ios/Runner/Info.plist ios/Runner/Runner.entitlements ios/Runner/*.lproj/InfoPlist.strings` — OK.
- [ ] **Step 4:** Commit `feat(ios): HealthKit steps host API with entitlements and usage text`.

### Task 5: `StepsObserver` with background delivery

**Files:**
- Create: `ios/Runner/Steps/StepsObserver.swift` (Steps group, Runner target)
- Modify: `ios/Runner/Steps/StepsHost.swift` (restart the observer after `requestAccess`)
- Modify: `ios/Runner/AppDelegate.swift`

**Interfaces:**
- Consumes: `StepsHost.shared` store, `OnceCompletion` (Task 3), generated `StepsEventsApi` Swift class (Task 2).
- Produces: `final class StepsObserver` with `static let shared`; `func start()` (idempotent: stops a running query first); `func attach(events: StepsEventsApi)`.

Behaviour:
- `start()`: `HKObserverQuery` on step count; `enableBackgroundDelivery(for: stepType, frequency: .hourly)`; does nothing when HealthKit is unavailable.
- Callback: wraps HealthKit's completion handler in `OnceCompletion(timeout: 20, queue: .main)`; on the main queue, if `events` is attached calls `onStepsChanged` and fires on its reply (success or error), otherwise keeps the pending completion and delivers `onStepsChanged` as soon as `attach` is called; the timeout fires it regardless. An observer error fires the completion without calling Dart.
- `AppDelegate`: in `didFinishLaunching`, call `super` first, then `StepsObserver.shared.start()`, then return super's result (registered before launch finishes, ADR 0007); in `didInitializeImplicitFlutterEngine`, `attach(events: StepsEventsApi(binaryMessenger: …))`.

- [ ] **Step 1:** Implement `StepsObserver`, wire `AppDelegate` and the restart in `StepsHost.requestAccess`.
- [ ] **Step 2:** `flutter build ios --simulator --debug` — builds; `xcodebuild test … -only-testing:RunnerTests` — PASS.
- [ ] **Step 3:** Smoke run on the simulator: `flutter run -d <iPhone 16 Pro> -t lib/main_preview.dart` starts without a native exception in the log (the simulator has no step data; the device checks belong to PR 3).
- [ ] **Step 4:** Commit `feat(ios): step count observer with hourly background delivery`.

### Task 6: Docs, full gate, PR

**Files:**
- Modify: `docs/ARCHITECTURE.md` — §2 "Native": the `Steps` host API, observer and source exist, nothing calls them yet; §4: daily totals via native `HKStatisticsCollectionQuery` through Pigeon (the `health` plugin is not used), error codes.

- [ ] **Step 1:** Update ARCHITECTURE.md.
- [ ] **Step 2:** Full gate, with `lib/main_preview.dart` moved out of `lib/` for the coverage check: `dart format --output=none --set-exit-if-changed .`, `dart analyze --fatal-infos`, `flutter test --coverage`, `dart run tool/coverage/check_coverage.dart` — all pass; `health_kit_steps_source.dart` ≥ 85%, the generated `steps_api.g.dart` not measured.
- [ ] **Step 3:** Commit `docs: HealthKit native layer in architecture`; push `feat/healthkit-steps`; open the PR (body: what PR 1 contains, that nothing calls it yet, local-only Swift verification with the commands run).

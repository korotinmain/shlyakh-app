# Steps UI and sync triggers (PR 3 of 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Real steps on the Today screen: a Health access screen that starts the journey, a hint when no steps arrive, syncs on launch, on return to the foreground and on HealthKit wakeups, and the demo repository gone.

**Architecture:** Riverpod providers in `features/steps/presentation/providers/` wire PR 1 and PR 2 (`HealthKitStepsSource`, `StepsSync`, the DAOs) into the app: one keepAlive `StepsSync` shared by every trigger, a `journeyStartProvider` that drives a go_router redirect to `/health-access`, and a notifier for the "Allow" action. Widgets only render. The background trigger (Task 6) waits for the device result of the background-Dart probe.

**Tech Stack:** Flutter, Riverpod 3 (`riverpod_generator`), go_router 18, Drift, Pigeon, mocktail, gen-l10n.

**Spec:** `docs/superpowers/specs/2026-09-28-healthkit-steps-sync-design.md` (Presentation; Data flow 4; Errors; Testing → Providers and widgets, On the iPhone; Delivery PR 3; Documentation).

## Global Constraints

- No business logic in widgets; widgets read providers and render (CLAUDE.md). Every string through l10n (uk, en); colours, type, spacing, radii from `lib/core/` tokens.
- Time only from `clockProvider` (ADR 0002); no `DateTime.now()`.
- One `StepsSync` instance for all triggers (keepAlive provider): two instances could commit a stale count over a newer one (PR 2 review).
- `onStepsChanged` always completes, also when a sync throws, so Swift ends the wakeup without waiting for the 20 s timeout (PR 2 review).
- Providers do not catch; failures surface as `AsyncValue.error` and `failureMessage` (ADR 0005). Sync failures stay inside `StepsSync` (logged, never thrown).
- No new dependencies.
- Widget tests never reach real HealthKit or a file database: `pumpApp` provides test overrides by default.

## Review Focus

- First launch: no journey start → the access screen, never Today with zeros; after "Allow" → Today. Tested in Task 3.
- "Allow" when HealthKit is unavailable (iPad) → the unavailable message, no journey start written, no sync. Tested in Task 2 and Task 3.
- A second "Allow" tap while the first is in progress → one journey start, one access prompt. Tested in Task 2.
- The app returns to the foreground many times quickly → syncs fold into at most two runs (shared instance). Tested in Task 4.
- The hint at 23 h vs 25 h after the start, and with one non-zero day → shown only at 25 h with all zeros. Tested in Task 5.

## Decisions for this plan

- "Allow" order: capture the start instant from the clock at the tap, check `isAvailable()`, call `requestAccess()`, then `insertOnce` the start, then the first `sync()`. If the prompt throws, no journey exists (the spec listed insert before the prompt; the start moment is still the tap).
- Before the journey start resolves (Drift's first read, milliseconds), the redirect leaves the location unchanged; Today shows its loading state.
- The start's zone is `HealthKitStepsSource.timeZoneId()` (the device zone Swift uses for the days).

---

### Task 1: Provider wiring and test defaults

**Files:**
- Create: `lib/features/steps/presentation/providers/steps_providers.dart`
- Modify: `lib/features/today/presentation/providers/steps_repository_provider.dart` (→ `DriftStepsRepository`)
- Delete: `lib/features/steps/data/demo/demo_steps_repository.dart`, `test/features/steps/data/demo/demo_steps_repository_test.dart`
- Modify: `test/helpers/pump_app.dart`; tests that relied on the demo data (`test/app/*`, `today_provider_test.dart`, `today_screen_test.dart`) keep passing through the new defaults
- Test: `test/features/steps/presentation/providers/steps_providers_test.dart`

**Interfaces:**
- Produces (all `@Riverpod(keepAlive: true)` unless noted):
  - `StepsHostApi stepsHostApi(Ref)` — returns `StepsHostApi()`; tests always override it with a mock.
  - `HealthKitStepsSource healthKitStepsSource(Ref)`
  - `StepsSync stepsSync(Ref)` — from `healthKitStepsSource`, `appDatabase` DAOs, `clock`, `logger`, `currentUserId`.
  - `Stream<JourneyStart?> journeyStart(Ref)` — `journeyStartDao.watch(currentUserId)`.
  - `stepsRepository` returns `DriftStepsRepository(appDatabase.dailyStepsDao)`.
- Produces (tests): `pumpApp(..., {bool journeyStarted = true})` adds default overrides — in-memory `appDatabaseProvider`, a mocktail `StepsHostApi` whose `dailySteps` returns `NativeDays(timeZoneId: 'Europe/Kyiv', days: [])`, `isAvailable` true, `timeZoneId` `'Europe/Kyiv'` — and, when `journeyStarted`, a journey start for `'local'` at `DateTime.utc(2026, 9, 1)` inserted before pumping. Caller overrides win.

- [ ] **Step 1: Failing tests** (`ProviderContainer` with in-memory db and the mock api): `stepsSync is one instance` (two reads, and a read after listening from a second listener, are `identical`); `journeyStart emits null, then the inserted start`; `stepsRepository reads Drift` (upsert a day → `watchDays` emits it).
- [ ] **Step 2:** `flutter test test/features/steps/presentation` — FAIL.
- [ ] **Step 3:** Implement; switch `stepsRepositoryProvider`; remove the demo; update `pumpApp`; `dart run build_runner build --delete-conflicting-outputs`.
- [ ] **Step 4:** `flutter test` — all PASS (existing Today and app tests now read an in-memory Drift with no days; where they asserted demo numbers, they insert the days they assert through the db override).
- [ ] **Step 5:** Commit `feat(steps): wire HealthKit sync providers and read steps from Drift`.

### Task 2: "Allow" action

**Files:**
- Create: `lib/features/steps/presentation/providers/health_access.dart`
- Test: `test/features/steps/presentation/providers/health_access_test.dart`

**Interfaces:**
- Consumes: Task 1 providers, `JourneyStartDao.insertOnce`, `StepsSync.sync`.
- Produces: `@riverpod class HealthAccess extends _$HealthAccess` with `FutureOr<void> build()` (idle) and `Future<void> allow()`; state goes loading → data, or error with the `Failure`. A call while loading returns the same future. `@riverpod Future<bool> healthAvailable(Ref)` → `healthKitStepsSource.isAvailable()`.

- [ ] **Step 1: Failing tests** (`Clock.fixed(DateTime(2026, 9, 28, 9, 30))`):
  - `allow requests access, stores the start at the tap and syncs` (verify order `requestAccess` → stored start `DateTime(2026, 9, 28, 9, 30).toUtc()` zone `'Europe/Kyiv'` → `dailySteps` called).
  - `unavailable HealthKit stores no start` (`isAvailable` false → state error `HealthUnavailable`, no row, `requestAccess` never called).
  - `a failing prompt stores no start` (`requestAccess` throws `PlatformException(code: 'healthkit')` → state error `UnexpectedFailure`, no row).
  - `a second tap while allowing prompts once` (two `allow()` calls, `requestAccess` completes via a `Completer` → called once, one row).
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS; `presentation/providers/` ≥ 85%.
- [ ] **Step 5:** Commit `feat(steps): allow Health access and start the journey`.

### Task 3: Access screen and redirect

**Files:**
- Create: `lib/features/steps/presentation/health_access_screen.dart`
- Modify: `lib/app/router.dart` (`AppRoutes.healthAccess = '/health-access'`, route outside the shell, `redirect`, `refreshListenable`)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_uk.arb`
- Test: `test/features/steps/presentation/health_access_screen_test.dart`, `test/app/navigation_test.dart`

**Interfaces:**
- Consumes: `journeyStartProvider`, `healthAvailableProvider`, `healthAccessProvider`.
- Produces: route `/health-access`; ARB keys `healthAccessTitle`, `healthAccessBody`, `healthAccessAllow`.

Copy (exact):
- en: title "Every step counts"; body "Shlyakh reads your steps from Health, including your Apple Watch, and turns them into progress along the path. It never writes to Health. Your path starts when you allow access."; button "Allow".
- uk: title "Кожен крок рахується"; body "Шлях читає ваші кроки зі Здоров'я, разом з Apple Watch, і перетворює їх на поступ шляхом. Він нічого не записує в Здоров'я. Ваш шлях почнеться, щойно ви дозволите доступ."; button "Дозволити".

Layout: `SkyBackground` for the current sky, a `GlassPanel` card (`AppRadii.card`, `AppSpacing.screen` margins) with title (`AppTypography.title`), body (`AppTypography.body`) and a full-width button in `palette.accent`; while `healthAccessProvider` is loading the button shows a small progress indicator and is disabled; on error the card shows `failureMessage`; when `healthAvailable` is false the button is replaced by the `errorHealthUnavailable` text.

Redirect: while `journeyStartProvider` is loading → `null`; no start and not on `/health-access` → `/health-access`; a start and on `/health-access` → `/today`. `refreshListenable` is a `ValueNotifier` updated from `ref.listen(journeyStartProvider, …)` and disposed with the provider.

- [ ] **Step 1: Failing tests:** `pumpApp(journeyStarted: false)` shows "Every step counts" and no tab bar; tapping "Allow" (mock api) ends on Today with the tab bar; `uk` shows "Кожен крок рахується"; unavailable HealthKit shows "Health data isn't available on this device." and no button; text scale 2.0 renders without overflow; existing navigation tests (journey started) still start on Today.
- [ ] **Step 2:** FAIL. **Step 3:** Implement (ARB keys with `@` descriptions, `flutter gen-l10n`). **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(steps): Health access screen before the journey starts`.

### Task 4: Sync on launch and on return to the foreground

**Files:**
- Create: `lib/features/steps/presentation/providers/sync_triggers.dart`
- Modify: `lib/app/app.dart` (watch `syncTriggersProvider`)
- Test: `test/features/steps/presentation/sync_triggers_test.dart` (widget tests: lifecycle needs a binding)

**Interfaces:**
- Consumes: `stepsSyncProvider`, `journeyStartProvider`.
- Produces: `@Riverpod(keepAlive: true) void syncTriggers(Ref)` — when `journeyStartProvider` has a start (now or later, `fireImmediately`) calls `sync()` once; registers an `AppLifecycleListener(onResume: sync)` disposed with the provider; calls are `unawaited` (sync never throws a `Failure`).

- [ ] **Step 1: Failing tests** (count `dailySteps` calls on the mock api): `syncs on launch when the journey started`; `does not sync before the journey starts`; `syncs when the journey starts`; `syncs on resume` (`tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused)` then `.resumed`); `many resumes fold into at most two syncs` (first `dailySteps` held by a `Completer`, five resumes → two calls).
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(steps): sync on launch and on return to the foreground`.

### Task 5: Health access hint on Today

**Files:**
- Create: `lib/features/steps/presentation/providers/health_access_hint.dart`
- Modify: `lib/features/today/presentation/today_screen.dart` (hint text under the card), ARB files
- Test: `test/features/steps/presentation/providers/health_access_hint_test.dart`, `test/features/today/presentation/today_screen_test.dart`

**Interfaces:**
- Produces: `@riverpod Stream<bool> healthAccessHint(Ref)` — true when `clock.now()` is at least 24 h after the journey start and every stored day of the user has 0 steps (none stored counts as all zero). ARB key `healthAccessHint`.

Copy (exact):
- en: "No steps yet? Allow Shlyakh to read Steps in Settings → Health → Data Access & Devices."
- uk: "Кроків досі немає? Дозвольте Шляху читати кроки: Параметри → Здоров'я → Доступ до даних і пристрої."

- [ ] **Step 1: Failing tests:** start 2026-09-27 09:00 UTC; `Clock.fixed` at +23 h → false; +25 h with no days → true; +25 h with days 0 and 0 → true; +25 h with one day 12 → false; no journey start → false. Widget: the hint text shows on Today in the true case, not in the false case; `uk` copy.
- [ ] **Step 2:** FAIL. **Step 3:** Implement (hint: `AppTypography.footnote`, `onSky` colour, `AppSpacing` below the card). **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(today): hint when Health sends no steps`.

### Task 6: Background trigger — BLOCKED on the device result

The probe (`spike/background-dart`) answers whether Dart runs in a HealthKit background relaunch. Fill this task in once the journal is back:

- **If Dart runs** ("launch [background]" followed by "flutter engine created", "dart main", "dart sync (observer)"): register a `StepsEventsApi` handler at startup (`main.dart`, after the container exists) whose `onStepsChanged` awaits `stepsSync.sync()` inside `try`/`finally` and always completes; widget/unit test with a fake that the handler completes also when `sync` throws a non-`Failure` error.
- **If it does not:** a headless `FlutterEngine` started natively for background launches, or native totals stored for the next launch — a new short design in chat before any code.

### Task 7: Device checks, docs, full gate, PR

**Files:**
- Create: `docs/decisions/0008-steps-sync.md` (journey start at "Allow", partial first day, 7-day window plus gap fill, zone rule, completion after Dart, the device findings below)
- Modify: `docs/PRODUCT.md` (journey starts at "Allow", partial first day, no earlier history), `docs/ARCHITECTURE.md` (§2 providers, triggers, access screen; demo gone; §4 background result), `docs/ROADMAP.md` (stage 2 "Repository: HealthKit to Drift sync", stage 4 "Wired to real data")
- Local only (not committed): `lib/main_preview.dart` overrides `stepsRepositoryProvider` with an inline demo and `journeyStartProvider` with a start

- [ ] **Step 1: Device checklist** (release build with `lib/main.dart` on the iPhone, replacing the probe after its journal is read): access screen → Allow → Today; the seven stored days vs Health (days after the start match; the first is partial); a sample spanning the start instant (recorded in ADR 0008); a background sync with the app closed updates Today on the next open; the Dart zone after a manual zone change (Settings → General → Date & Time), without restarting the app.
- [ ] **Step 2:** ADR 0008 and docs.
- [ ] **Step 3:** Full gate with `lib/main_preview.dart` moved out: format, `dart analyze --fatal-infos`, `flutter test --coverage`, coverage check; Swift build and RunnerTests.
- [ ] **Step 4:** Commit `docs: steps sync in product, architecture, roadmap and ADR 0008`; push; PR.

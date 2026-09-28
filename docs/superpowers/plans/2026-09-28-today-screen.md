# Today Screen Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Today tab — live sky, glass card with level ring and today's steps, snapping bottom sheet with the week — inside a three-tab shell, fed by a `StepsRepository` with a demo implementation.

**Architecture:** Domain interface `StepsRepository` + pure helpers; `DemoStepsRepository` in data; Riverpod providers in `features/today/presentation/providers/` build a `TodayView`; widgets in `features/today/presentation/` only render it. go_router `StatefulShellRoute.indexedStack` with a custom floating tab bar.

**Tech Stack:** Flutter 3.47, Riverpod 3 (generator), go_router 18 (`StatefulShellRoute.indexedStack(branches:, builder:)`, `navigationShell.goBranch`), `DraggableScrollableSheet(snap: true, snapSizes:)`, intl (uk plural rules: one/few/many/other), design tokens from `lib/core/design/`.

**Spec:** `docs/superpowers/specs/2026-09-28-today-screen-design.md`

## Global Constraints

- Branch `feat/today-screen`; Conventional Commits ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- No new dependencies.
- Widgets contain no colours, sizes, durations or strings of their own: tokens (`AppSpacing`, `AppRadii`, `AppTypography`, `GlassStyle`, `AppMotion`, sky palette) and ARB keys only. Allowed literals: layout fractions defined once as named constants at the top of a file (sheet snap sizes 0.18 / 0.85, ring stroke width), with a comment.
- Time only from `clockProvider`; never `DateTime.now()`.
- Numbers/dates via `intl` with `Localizations.localeOf(context)`.
- Do not install on the physical iPhone (spike build). Simulator: iPhone 16 Pro.
- Gate before each commit: `dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && flutter test --coverage && dart run tool/coverage/check_coverage.dart`.

## Review Focus

- Today is Sunday: the week is the Monday–Sunday that contains today, not the next one. Test in Task 3.
- A week across a year boundary (today 2026-12-31, Thursday → Mon 2026-12-28 … Sun 2027-01-03) has 7 correct dates. Test in Task 3.
- A week with all zero steps renders without dividing by zero. Test in Task 5.
- Large accessibility text (text scale 2.0) does not overflow the card or the collapsed sheet. Test in Task 5.
- Ukrainian plurals: 1 крок, 2 кроки, 5 кроків, 21 крок, 12 кроків. Test in Task 4.

---

### Task 1: Domain helpers and the repository interface

**Files:** Modify `lib/features/steps/domain/local_date.dart`; Create `lib/features/steps/domain/distance.dart`, `lib/features/steps/domain/steps_repository.dart`; Test `test/features/steps/domain/local_date_test.dart` (extend), `test/features/steps/domain/distance_test.dart`.

**Interfaces — Produces:** `static LocalDate fromDateTime(DateTime local)`; `LocalDate addDays(int days)` (negative allowed); `int get weekday` (1 Mon … 7 Sun; integer algorithm, e.g. Sakamoto); `const averageStepLengthMeters = 0.74`; `int approximateDistanceMeters(int steps)` (`ArgumentError` below 0); `abstract interface class StepsRepository { Stream<List<DailySteps>> watchDays({required String userId, LocalDate? from, LocalDate? to}); }`.

- [ ] **Step 1: Failing tests:** `fromDateTime(DateTime(2026, 9, 28, 23, 59))` → 2026-09-28; `addDays`: 2026-01-31 +1 → 02-01, 2024-02-28 +1 → 02-29, 2026-12-31 +1 → 2027-01-01, 2026-03-01 −1 → 02-28, 2024-03-01 −1 → 02-29, 0 → same, +365 from 2026-01-01 → 2027-01-01; `weekday`: 2026-09-28 → 1, 2026-09-27 → 7, 2024-02-29 → 4, 2027-01-03 → 7; distance 0 → 0, 1000 → 740, 10000 → 7400, −1 → ArgumentError.
- [ ] **Step 2:** Run `flutter test test/features/steps/domain` — FAIL.
- [ ] **Step 3:** Implement (`addDays` by repeated `next()`/previous in integers, or via day-number conversion; no `DateTime` arithmetic).
- [ ] **Step 4:** PASS; commit `feat(steps): date helpers, approximate distance and StepsRepository`.

### Task 2: Demo repository

**Files:** Create `lib/features/steps/data/demo/demo_steps_repository.dart`; Test `test/features/steps/data/demo/demo_steps_repository_test.dart`.

**Interfaces — Consumes:** Task 1. **Produces:** `final class DemoStepsRepository implements StepsRepository` — `new(Clock clock, {int days = 120})`; days from `today − (days − 1)` to today, steps from a fixed LCG seeded with `0x5EED` mapped to 0–14 000 (deterministic, clock-independent sequence); a single-value stream (`Stream.value`) filtered by `from`/`to`.

- [ ] **Step 1: Failing tests** (`Clock.fixed(DateTime(2026, 9, 28, 12))`): 120 entries ending 2026-09-28, ascending, consecutive dates; same output on two instances; every steps value within 0–14 000; `from`/`to` inclusive filtering; `userId` is carried into each entry.
- [ ] **Step 2:** FAIL. **Step 3:** Implement; file doc comment: "Demo data until the HealthKit → Drift repository exists; never ship to TestFlight with it." **Step 4:** PASS; commit `feat(steps): demo steps repository`.

### Task 3: Providers

**Files:** Create `lib/features/today/presentation/providers/{current_user_provider,steps_repository_provider,sky_provider,today_provider}.dart`; Test `test/features/today/presentation/providers/{sky_provider_test,today_provider_test}.dart`.

**Interfaces — Consumes:** Tasks 1–2, `clockProvider`, `skyAt`, `dailyXp`, `totalXp`, `levelProgress`, `xpToReachLevel`. **Produces:** `currentUserIdProvider` (`String`, `'local'`); `stepsRepositoryProvider` (`StepsRepository`, keepAlive); `skyProvider` (`Stream<SkyPalette>`: immediately `skyAt(clock.now())`, then at each minute boundary via `Timer` to the next whole minute + `Timer.periodic(1 min)`; timers cancelled in `ref.onDispose`); `todayProvider` (`Stream<TodayView>`) with the spec's `WeekDay` / `TodayView` records (put the typedefs in `today_view.dart` next to the providers).

- [ ] **Step 1: Failing tests** (`ProviderContainer` with `clockProvider` and `stepsRepositoryProvider` overridden by a fake returning given days):
  - Monday 2026-09-28: week = 09-28 … 10-04, `isToday` only on 09-28;
  - Wednesday 2026-09-30: week = 09-28 … 10-04, today flagged;
  - Sunday 2026-09-27: week = 09-21 … 09-27 (not the next week);
  - Thursday 2026-12-31: week = 2026-12-28 … 2027-01-03;
  - missing days are 0; `weekSteps` is the sum; `steps`, `xp`, `distanceMeters` for today; `level` = `levelProgress(totalXp(all))`, `levelStartXp`/`nextLevelXp` consistent;
  - no days at all → steps 0, level 1;
  - `skyProvider` (inside `testWidgets` for fake time, clock = a mutable test clock at 12:00:30): first value = `skyAt(12:00:30)`; after `tester.pump(30 s)` a second value for 12:01:00; no value before the boundary.
- [ ] **Step 2:** FAIL. **Step 3:** Implement; `dart run build_runner build --delete-conflicting-outputs`. **Step 4:** PASS, coverage of `presentation/providers/` ≥ 85%; commit `feat(today): providers for the sky and today's view`.

### Task 4: l10n, shell and navigation

**Files:** Modify `lib/l10n/app_en.arb`, `app_uk.arb`, `lib/app/router.dart`; Create `lib/app/app_shell.dart`, `lib/app/floating_tab_bar.dart`, `lib/features/path/presentation/path_screen.dart`, `lib/features/history/presentation/history_screen.dart`, `lib/features/today/presentation/today_screen.dart` (temporary body: sky only, filled in Task 5); Delete `lib/features/home/`; Replace `test/app/app_test.dart`; Test `test/l10n/plurals_test.dart`, `test/app/navigation_test.dart`.

**Interfaces — Produces:** the spec's ARB keys with ICU plurals where counts are involved (`todayStepsCaption(int count, String date)`, `stepsUnit(int count)`, `weekTotal(int count, String steps)`); router: `StatefulShellRoute.indexedStack(builder: (_, _, shell) => AppShell(shell: shell), branches: [today, path, history])`, initial location `/today`; `FloatingTabBar({required int index, required ValueChanged<int> onSelect})`.

- [ ] **Step 1: Failing tests:** plurals in uk for 1/2/5/12/21 (`крок`, `кроки`, `кроків`, `кроків`, `крок`) and en 1/2 (`step`, `steps`); `app_test` (replaced): the five locale cases assert `tabToday` text ("Today" / "Сьогодні") instead of the app title; navigation: tapping Path/History shows their placeholder text, tapping Today returns.
- [ ] **Step 2:** FAIL. **Step 3:** Implement keys (`flutter gen-l10n`), shell, tab bar (glass, stadium, icon + label, active in `palette.accent` read from `skyProvider`), placeholders; remove `features/home`. **Step 4:** PASS; commit `feat(app): three-tab shell with a floating tab bar`.

### Task 5: Today screen widgets

**Files:** Create in `lib/features/today/presentation/widgets/`: `sky_background.dart`, `grain.dart`, `placeholder_hills.dart`, `glass_panel.dart`, `level_ring.dart`, `today_card.dart`, `progress_sheet.dart`, `week_bars.dart`; Modify `today_screen.dart`; Test `test/features/today/presentation/today_screen_test.dart`.

**Interfaces — Consumes:** Tasks 3–4 and tokens. `GlassPanel({required SurfaceTone tone, required BorderRadius radius, required Widget child})` (BackdropFilter sigma `GlassStyle.blurSigma`, tint by tone, `GlassStyle.shadow`); `LevelRing({required double fraction, required Color arc, required Color track})`; `WeekBars({required List<WeekDay> week, required Color accent, required Color muted})`; `ProgressSheet({required TodayView view})` (snap sizes 0.18 / 0.85).

- [ ] **Step 1: Failing widget tests** (overrides: fixed clock at 2026-09-28 12:00 local, fake repository, `pumpApp`): en shows "6,870" and "Level 4"; uk shows "6 870" with U+00A0 and the uk title for level 4 in the default (masculine) form; dragging the sheet up shows 7 week bars and "All history" text; all-zero week renders (no exceptions); text scale 2.0 (`MediaQuery` override) renders the card and collapsed sheet with no overflow exceptions; a repository that emits an error shows the `errorGeneric`/failure text in the card.
- [ ] **Step 2:** FAIL. **Step 3:** Implement widgets; grain: a 128×128 noise `ui.Image` generated once with a fixed-seed LCG and tiled with `ImageShader`, opacity `skyGrainOpacity`. **Step 4:** PASS; commit `feat(today): today screen with sky, glass card, ring and sheet`.

### Task 6: Simulator check and docs

- [ ] **Step 1:** A temporary debug entry point (not committed) overriding `clockProvider` with a day time and a night time; screenshots on the iPhone 16 Pro simulator; scroll the sheet and check it stays smooth. Delete the entry point.
- [ ] **Step 2: Docs:** PRODUCT.md (approximate distance), ARCHITECTURE.md (StepsRepository + demo; Today [built]), ROADMAP (phase C).
- [ ] **Step 3:** Full gate; commit `docs: today screen in product, architecture and roadmap`; push; PR.

# Level-up moment (design phase E, part 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A full-screen scene over the app whenever the level rises: a stretch of a Duolingo-style trail with the reached node lit, the chapter and title, the levels passed, and "Continue"; celebrated once per level.

**Architecture:** Pure domain functions decide what to celebrate (`levelUp`) and where each level sits on the trail (`trailNode`). The last celebrated level is a column of `journey_start` (schema v3). `levelUpProvider` compares it with the level of all stored days; `AppShell` layers `LevelUpScene` over the tabs while it has a value. A reusable `Trail` widget draws nodes and a dashed winding line in code, with a slot for chapter art.

**Tech Stack:** Flutter, Riverpod 3, Drift 2.35 (`make-migrations`), gen-l10n, flutter_test, mocktail.

**Spec:** `docs/superpowers/specs/2026-09-28-level-up-moment-design.md`

**Precondition:** PR #22 is merged; rebase `feat/level-up` onto `main` before Task 1 (`journeyStartProvider`, `stepsRepositoryProvider` on Drift, `pumpApp` defaults, `test/helpers/steps_test_overrides.dart` come from it).

## Global Constraints

- XP and levels stay derived from daily steps; `celebrated_level` is UI state, only ever raised (CLAUDE.md Rules; PRODUCT: no XP ever lost).
- Domain is pure Dart and 100% covered; data and `presentation/providers/` ≥ 85%.
- Every string through l10n (uk, en; titles with grammatical gender via `levelTitle`, chapters via `levelChapter`); every colour, size, radius and duration from `lib/core/design/` tokens.
- Schema change: bump `schemaVersion` to 3, run `dart run drift_dev make-migrations`, commit snapshot, steps and tests (ADR 0001).
- Tests run with `TZ=Europe/Kyiv` (#23); Pigeon before build_runner.
- No new dependencies.

## Review Focus

- A level that goes down after samples are deleted → no scene, and the next scene only above the celebrated level. Tested in Task 3.
- A sync raising the level while the scene is open → after "Continue" the scene shows again with the newer level (not lost, not skipped). Tested in Task 5.
- The widest jump a first day allows (1 → 4) and a jump across a chapter start (4 → 7) → one scene, passed levels listed, chapter line for 4 → 7. Tested in Tasks 1 and 5.
- Feminine titles in "Along the way" and on the scene → feminine forms. Tested in Task 5.
- Text scale 2.0 → no overflow; the trail stays visible. Tested in Task 5.

---

### Task 1: Domain — `levelUp` and `trailNode`

**Files:**
- Create: `lib/features/progress/domain/level_up.dart`, `lib/features/progress/domain/trail_layout.dart`
- Test: `test/features/progress/domain/level_up_test.dart`, `test/features/progress/domain/trail_layout_test.dart`

**Interfaces:**
- Produces:
  - `typedef LevelUp = ({int from, int to, List<int> passed, int? newChapter, bool finishesMainPath});`
  - `LevelUp? levelUp({required int celebrated, required int current})` — null when `current <= celebrated`; `passed` = levels strictly between, ascending; `newChapter` = `chapterOf` of the highest level in `celebrated + 1 … current` that is a chapter start (6, 11, 16, 21), else null; `finishesMainPath` = 25 in that range. `ArgumentError` for a level below 1.
  - `enum TrailSide { left, centre, right }`; `typedef TrailNode = ({int level, int chapter, TrailSide side, bool startsChapter});`
  - `TrailNode trailNode(int level)` — side by `(level - 1) % 4`: 0 centre, 1 left, 2 centre, 3 right; `startsChapter` for 1, 6, 11, 16, 21; `chapter` = `chapterOf(level)`. `ArgumentError` below 1.

- [ ] **Step 1: Failing tests:** `levelUp` — equal → null; lower → null; 1 → 2 (`passed` empty, no chapter, not main path); 1 → 4 (`passed` [2, 3]); 5 → 6 (`newChapter` 2); 4 → 7 (`passed` [5, 6], `newChapter` 2); 24 → 26 (`passed` [25], `finishesMainPath`, `newChapter` null); 30 → 31 (plain); celebrated 0 → `ArgumentError`. `trailNode` — levels 1–5 sides centre, left, centre, right, centre; 1 and 6 `startsChapter`, 5 not; 25 chapter 5; 26 chapter 5, not a start; 0 → `ArgumentError`.
- [ ] **Step 2:** `TZ=Europe/Kyiv flutter test test/features/progress/domain` — FAIL. **Step 3:** Implement. **Step 4:** PASS, 100%.
- [ ] **Step 5:** Commit `feat(progress): level-up and trail layout rules`.

### Task 2: `celebrated_level` in `journey_start` (schema v3)

**Files:**
- Modify: `lib/features/steps/data/local/journey_start_table.dart`, `journey_start_dao.dart`, `lib/features/steps/domain/journey_start.dart`, `lib/core/database/app_database.dart` (v3, `from2To3`)
- Generated, committed: `drift_schemas/app_database/drift_schema_v3.json`, steps file, `test/drift/app_database/…`
- Modify: every `JourneyStart` literal in `lib/` and `test/` (add `celebratedLevel: 1`)
- Test: `test/features/steps/data/local/journey_start_dao_test.dart`, `test/drift/app_database/migration_test.dart`

**Interfaces:**
- Produces: `JourneyStart` gains `int celebratedLevel`; column `celebrated_level INTEGER NOT NULL DEFAULT 1` with `CHECK (celebrated_level >= 1)`; `Future<void> JourneyStartDao.markCelebrated(String userId, int level)` — `MAX(celebrated_level, level)`, no-op without a row; `insertOnce` stores `start.celebratedLevel`.

- [ ] **Step 1: Failing tests:** `markCelebrated raises` (1 → 4); `never lowers` (4 then 2 → 4); `another user is untouched`; `celebratedLevel round trip`; migration 2 → 3 keeps a `journey_start` row and gives it 1 (fill the generated data-integrity test like v1 → v2).
- [ ] **Step 2:** FAIL. **Step 3:** Implement; build_runner; `make-migrations`; wire `from2To3: (m, schema) => m.addColumn(schema.journeyStart, schema.journeyStart.celebratedLevel)`. **Step 4:** PASS (whole suite).
- [ ] **Step 5:** Commit `feat(steps): remember the last celebrated level (schema v3)`.

### Task 3: `levelUpProvider` and the "Continue" action

**Files:**
- Create: `lib/features/progress/presentation/providers/level_up_provider.dart`
- Test: `test/features/progress/presentation/providers/level_up_provider_test.dart`

**Interfaces:**
- Consumes: `journeyStartProvider`, `stepsRepositoryProvider`, `currentUserIdProvider`, `appDatabaseProvider` (Task 2 DAO), `levelUp` (Task 1), `levelProgress`, `totalXp`.
- Produces: `@riverpod Stream<LevelUp?> levelUp(Ref)` (provider `levelUpProvider`; rename the domain import with a prefix if the generated name clashes); `@riverpod class CelebrateLevel` with `Future<void> celebrate(int level)` (state loading → data, or error with the `Failure`; `SqliteException`/wrapped → `StorageFailure` like `StepsSync`).

- [ ] **Step 1: Failing tests** (in-memory db via the #22 helpers; listen before reading): days worth level 4 (2 days of 10 000 steps → 20 000 XP, inside level 4's 15 600–27 800; assert with `levelProgress` in the test setup) and celebrated 1 → `(from: 1, to: 4)`; after `celebrate(4)` → null; no start → null; celebrated 5 with days worth level 2 → null (level went down); a raise after celebrating (add a day) → a new `LevelUp` from the celebrated level.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(progress): detect a level to celebrate`.

### Task 4: `Trail` widget and tokens

**Files:**
- Create: `lib/core/design/trail_tokens.dart` (node size, reached-node size, line width, dash, dash gap, glow blur, row height, horizontal offset of the sides; comments with their meaning), `lib/features/progress/presentation/widgets/trail.dart`
- Test: `test/features/progress/presentation/widgets/trail_test.dart`

**Interfaces:**
- Consumes: `trailNode` (Task 1), `SkyPalette`, `levelChapter`.
- Produces: `Trail({required int current, required int firstLevel, required int lastLevel, required SkyPalette palette, Widget Function(int chapter)? backgroundFor, super.key})` — nodes bottom-up, one row each, drawn after `docs/design/level_up_sprites_draft.svg` (spec, Trail → Look): passed nodes raised accent discs, current node larger with white centre and a two-step accent halo, upcoming nodes translucent with a dashed outline; a flag at a chapter start with the chapter name; white round dots along the curve through the node centres (`CustomPainter`); a dark "you are here" pill (`trailYouAreHere`) with a caret at the current node; nodes carry `Semantics(label: '<level> · <title>', selected: level == current)`.
- Produces (tokens): `trail_tokens.dart` — node, current-node and halo sizes, raise offset, shade lightness step (subtracted from `palette.accent`'s Oklab `l` with `toOklab` / `fromOklab` from `lib/core/design/sky/oklab.dart`), halo opacities, upcoming-node fill and outline opacities, dot size and spacing, row height, side offset.

- [ ] **Step 1: Failing widget tests:** `Trail(current: 4, firstLevel: 3, lastLevel: 6)` shows node labels 3–6 and "you are here" exactly once, next to 4; the chapter name "The Beaten Road" appears (6 starts chapter 2); semantics: 4 is `selected`; a `CustomPaint` is present.
- [ ] **Step 2:** FAIL. **Step 3:** Implement (ARB `trailYouAreHere` en/uk from the spec copy table; `flutter gen-l10n`). **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(progress): trail widget`.

### Task 5: `LevelUpScene` over the shell

**Files:**
- Create: `lib/features/progress/presentation/level_up_scene.dart`
- Modify: `lib/app/app_shell.dart` (scene on top while `levelUpProvider` has a value), `lib/core/design/` (dim overlay colour token), `lib/l10n/app_en.arb`, `lib/l10n/app_uk.arb` (spec copy table)
- Test: `test/features/progress/presentation/level_up_scene_test.dart`

**Interfaces:**
- Consumes: `levelUpProvider`, `celebrateLevelProvider` (Task 3), `Trail` (Task 4), `skyProvider`, `grammaticalGenderProvider`, `levelTitle`, `levelChapter`, `failureMessage`.
- Produces: the scene per the spec (Presentation → `LevelUpScene`): kicker, optional chapter line, title, "Along the way" or main-path line, `Trail(firstLevel: max(1, from - 1), lastLevel: to + 2, current: to)`, "Continue" as the raised accent pill from the draft.

- [ ] **Step 1: Failing widget tests** (`pumpApp` with days inserted into the in-memory db): 1 → 4 in en shows "New level · Home Land", "Pathfinder", "Along the way: 2 · Passer-by, 3 · Wanderer", "you are here", "Continue", and the tab bar is covered (the scene is the top hit-test target over it); same in uk with the feminine override: "Шукачка стежок", "Дорогою: 2 · Перехожа, 3 · Мандрівниця"; 5 → 6 shows "New chapter · The Beaten Road"; 24 → 25 shows "A million steps. The main path is done — a new trail begins." and the kicker "The Milky Way"; "Continue" hides the scene and `journey_start.celebrated_level` becomes the new level; a day added while the scene is open, then "Continue" → the scene shows again with the newer level; a failing `markCelebrated` (drop the table) shows the storage message and the button stays enabled; text scale 2.0 → no exception.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS (whole suite).
- [ ] **Step 5:** Commit `feat(progress): level-up scene over the app`.

### Task 6: Simulator check, docs, gate, PR

**Files:**
- Modify: `docs/PRODUCT.md` (the scene: when it appears; never twice or lower), `docs/ARCHITECTURE.md` (§2: `levelUpProvider`, the scene in `AppShell`, `Trail`, schema v3), `docs/ROADMAP.md` (phase E: level-up done, history and the Path tab open)

- [ ] **Step 1:** Simulator: local `lib/main_preview.dart` override with a journey start and days worth level 4 → screenshots day and night, uk and en; tap "Continue".
- [ ] **Step 2:** Docs.
- [ ] **Step 3:** Full gate (`lib/main_preview.dart` moved out): format, `dart analyze --fatal-infos`, `TZ=Europe/Kyiv flutter test --coverage`, coverage check.
- [ ] **Step 4:** Commit `docs: level-up moment in product, architecture and roadmap`; push; PR.

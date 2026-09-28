# Path domain: route, star cost, ETA, star moment; levels and titles removed (constellation path, plan 2 of 7) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stars replace levels in the code. A pure-Dart route loaded from `assets/sky/route.json`, the star cost and path progress, the ETA and the star moment. The Today screen shows star progress instead of a level, and levels, titles, gender and Roman numerals are gone.

**Architecture:** `features/path/domain/` holds the pure model (`Route`, `Constellation`) and functions (`starCost`, `xpToLight`, `pathProgress`, `daysToNextStar`, `starMoment`). `features/path/data/route_asset.dart` parses the bundled JSON into a `Route`. A keep-alive `routeProvider` loads it once. `todayProvider` combines the route with the user's days. Today keeps its current layout (plan 4 redesigns it): the ring and the sheet switch from level to star.

**Tech Stack:** Dart, Riverpod 3 (riverpod_generator), flutter_test, gen-l10n. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-28-constellation-path-design.md` (Decisions; Numbers; Components → Domain, Data; Edge cases; Testing → Domain, Route asset).

## Global Constraints

- Star cost: `cost(n) = min(25 000, 1 500 × n)` XP for the n-th star (1-based); capped from star 17.
- Daily XP unchanged: `dailyXp`, `totalXp` in `lib/features/progress/domain/xp_rules.dart` stay.
- Route order: main `Sge, Vul, Cyg, Lac, Cep, Cas, Per, Aur, Tau, Gem, Ori, Mon, CMa`, then branch `Aql, Sct, Sgr`. Both come from the asset's `route` object and are never re-listed in code.
- A shared star (Elnath, HIP 25428) lights once, in the first constellation on the route that has it (Auriga). The main route has 140 lit stars; with the branch, 177.
- Milky Way relation: `edge` for `Tau`, `Gem`, `Ori`; `inside` for the rest.
- ETA: the average daily XP of the last 14 full days; null with fewer than 7 days of history.
- Progress is recomputed from daily steps; nothing new is stored. (`celebrated_stars` lands in plan 6 with the star-moment provider.)
- Domain is pure Dart (no Flutter imports). All user-facing text is in l10n (uk, en); constellation names come from ARB keys, never from the asset.
- Constellation names: uk Стріла, Лисичка, Лебідь, Ящірка, Цефей, Кассіопея, Персей, Візничий, Телець, Близнята, Оріон, Єдиноріг, Великий Пес, Орел, Щит, Стрілець; en Sagitta, Vulpecula, Cygnus, Lacerta, Cepheus, Cassiopeia, Perseus, Auriga, Taurus, Gemini, Orion, Monoceros, Canis Major, Aquila, Scutum, Sagittarius.
- Headers in sentence case. No denominators ("1 of 60").
- Tests run with `TZ=Europe/Kyiv`. Pigeon runs before build_runner. `lib/main_preview.dart` is moved out before the coverage check.
- Branch `feat/path-domain` from `main` after PR #24 is merged.

## Review Focus

- XP exactly at a star's cumulative cost → that star is lit and the next one starts at 0 XP (not off by one). Tested in Task 2.
- A constellation whose first lighting-order star was lit by an earlier constellation (Taurus after Auriga) → its first own star is the next one in its order, and no star is counted twice. Tested in Tasks 1 and 5 (real asset: 140 / 177).
- XP beyond the last star of the branch → progress reports the whole route lit, with no next star and no division by zero in the UI. Tested in Tasks 2 and 6.
- XP went down (samples deleted in Health) → no star moment, and no negative or repeated stars. Tested in Task 4.
- ETA when recent days are missing (no row) or zero → missing days count as 0; an all-zero window gives no ETA rather than infinity. Tested in Task 3.

---

### Task 1: The route model

**Files:**
- Create: `lib/features/path/domain/route.dart`
- Test: `test/features/path/domain/route_test.dart`

**Interfaces:**
- Produces:
  - `class RouteException implements Exception { const new(this.message); final String message; }`, with `toString` → `'RouteException: $message'`.
  - `enum MilkyWay { inside, edge }`
  - `typedef SkyPoint = ({int hip, double x, double y, double mag, double ra, double dec});`
  - `final class Constellation` with `const new({required String id, required List<SkyPoint> stars, required List<(int, int)> lines, required List<int> order, required MilkyWay milkyWay, required ({double ra, double dec}) centre, required double spanDeg})`. `order` is the asset's lighting order (indices into `stars`).
  - `typedef RouteStar = ({int constellationIndex, int starInConstellation, int hip});`, where `starInConstellation` is the 0-based position among the stars that constellation lights itself.
  - `final class Route` with `new({required List<Constellation> constellations, required int mainLength})` and these members:
    - `List<Constellation> constellations`, `int mainLength`;
    - `List<RouteStar> stars`: every star in lighting order, each HIP once;
    - `List<int> ownOrder(int constellationIndex)`: indices into that constellation's `stars` that it lights itself, in `order`;
    - `int ownerOf(int hip)`: the index of the constellation that lights it;
    - `bool isComplete(int constellationIndex, int starsLit)`.

- [ ] **Step 1: Failing tests.** Use a fixture of three constellations. `A` has stars hip 1, 2, 3, lines (0,1),(1,2) and order [0,1,2]. `B` has hip 3, 4, lines (0,1) and order [0,1] (it shares hip 3 with A). `C` has hip 5. `mainLength` is 2. Assertions:
  - `route.stars` is `[(0,0,1),(0,1,2),(0,2,3),(1,0,4),(2,0,5)]`;
  - `ownOrder(1)` is `[1]`; `ownerOf(3)` is 0;
  - `isComplete(0, 3)` is true, `isComplete(0, 2)` false, `isComplete(1, 4)` true.

  Each of these throws `RouteException` whose message names the constellation id:
  - no constellations;
  - `mainLength` 0 or greater than the count;
  - duplicate ids;
  - an empty `stars`;
  - an `order` that is not a permutation of the star indices (missing index, duplicate, out of range);
  - a line index out of range, or a line from a star to itself;
  - a constellation left with no own star (all its stars lit earlier).
- [ ] **Step 2:** `TZ=Europe/Kyiv flutter test test/features/path/domain/route_test.dart` → FAIL (no library).
- [ ] **Step 3:** Implement `route.dart`. The constructor validates, then walks the constellations in route order with a `Set<int>` of HIPs already lit, building `ownOrder` per constellation and `stars`. Lists are unmodifiable.
- [ ] **Step 4:** Same command → PASS.
- [ ] **Step 5:** Commit `feat(path): the route model with shared stars resolved`.

### Task 2: Star cost and path progress

**Files:**
- Create: `lib/features/path/domain/star_cost.dart`
- Test: `test/features/path/domain/star_cost_test.dart`

**Interfaces:**
- Consumes: `Route`, `RouteStar` (Task 1).
- Produces:
  - `int starCost(int n)`: throws `ArgumentError` for `n < 1`.
  - `int xpToLight(int stars)`: the cumulative cost of the first `stars` stars. It is 0 for 0 and throws `ArgumentError` for negative input. Closed form: `750 × k × (k + 1)` for `k ≤ 16`, otherwise `204 000 + 25 000 × (k − 16)`.
  - `typedef NextStar = ({int constellationIndex, int starInConstellation, int xpIntoStar, int xpForStar});`
  - `typedef PathProgress = ({int starsLit, NextStar? next});`, where `next` is null when every star of the route is lit.
  - `PathProgress pathProgress(int totalXp, Route route)`: throws `ArgumentError` for negative XP.

- [ ] **Step 1: Failing tests.**
  - `starCost` (table-driven): 1 → 1 500, 16 → 24 000, 17 → 25 000, 100 → 25 000; 0 throws.
  - `xpToLight`: 0 → 0, 1 → 1 500, 4 → 15 000, 16 → 204 000, 17 → 229 000, 140 → 3 304 000; −1 throws.
  - `pathProgress` on the Task 1 fixture (5 stars; cumulative costs 1 500, 4 500, 9 000, 15 000, 22 500):
    - 0 XP → `starsLit` 0, next `(0, 0, 0, 1 500)`;
    - 1 499 → `starsLit` 0, next `(0, 0, 1 499, 1 500)`;
    - 1 500 → `starsLit` 1, next `(0, 1, 0, 3 000)`;
    - 9 000 (A complete) → `starsLit` 3, next `(1, 0, 0, 6 000)`;
    - 15 000 (main route done, into the branch) → next `(2, 0, 0, 7 500)`;
    - 22 500 and 1 000 000 → `starsLit` 5, next null;
    - −1 throws.
- [ ] **Step 2:** `TZ=Europe/Kyiv flutter test test/features/path/domain/star_cost_test.dart` → FAIL.
- [ ] **Step 3:** Implement. `starsLit` is the largest `k ≤ route.stars.length` with `xpToLight(k) ≤ totalXp`: invert the closed form, or loop up to `route.stars.length` (177 at most).
- [ ] **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(path): star cost and path progress`.

### Task 3: ETA to the next star

**Files:**
- Create: `lib/features/path/domain/eta.dart`
- Test: `test/features/path/domain/eta_test.dart`

**Interfaces:**
- Consumes: `DailySteps`, `LocalDate` (`features/steps/domain/`), `dailyXp`.
- Produces: `int? daysToNextStar({required List<DailySteps> days, required LocalDate today, required int xpLeft})`.

  Ruling against the spec's signature: `today` is added. The window is the full days before today, so a partial today does not lower the pace, and the domain does not read a clock.

  Rules:
  - The window is the 14 days `today − 14 … today − 1`, starting no earlier than the earliest date in `days`. A day with no row counts as 0 XP.
  - Return null when `days` is empty, the window has fewer than 7 days, or the average is 0.
  - Otherwise return `ceil(xpLeft / average)`, where average = the window's XP sum / window length. Return 0 when `xpLeft ≤ 0`.

- [ ] **Step 1: Failing tests** (today = 2026-10-20):
  - no days → null;
  - 6 days of history (from 2026-10-14) → null;
  - 7 days of 7 000 steps with `xpLeft` 25 000 → 4 (25 000 / 7 000 rounded up);
  - 20 days of history where only the last 14 count: days 15–20 back have 30 000 steps and the last 14 have 5 000, `xpLeft` 10 000 → 2;
  - today's row of 30 000 steps is ignored;
  - a window of 10 days with rows only on 5 of them (10 000 steps each) → average 5 000, `xpLeft` 12 000 → 3;
  - all-zero window → null;
  - `xpLeft` 0 → 0.
- [ ] **Step 2:** `TZ=Europe/Kyiv flutter test test/features/path/domain/eta_test.dart` → FAIL.
- [ ] **Step 3:** Implement with `LocalDate.addDays` and `compareTo`, in integer arithmetic: `(xpLeft × length + sum − 1) ~/ sum`.
- [ ] **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(path): days to the next star at the recent pace`.

### Task 4: The star moment

**Files:**
- Create: `lib/features/path/domain/star_moment.dart`
- Test: `test/features/path/domain/star_moment_test.dart`

**Interfaces:**
- Consumes: `Route`, `RouteStar` (Task 1).
- Produces:
  - `typedef StarMoment = ({List<RouteStar> stars, List<int> completedConstellations});`
  - `StarMoment? starMoment({required int celebratedStars, required int currentStars, required Route route})`
  - Behaviour:
    - `stars` are route stars `celebratedStars … currentStars − 1`, in order, with `currentStars` clamped to `route.stars.length`;
    - `completedConstellations` are the indices whose last own star is in that range, in order;
    - returns null when `currentStars ≤ celebratedStars`;
    - throws `ArgumentError` when either count is negative.

- [ ] **Step 1: Failing tests** on the Task 1 fixture:
  - `(1, 1)` → null (none);
  - `(0, 1)` → one star `(0,0,1)`, no completed;
  - `(0, 2)` → two stars in order;
  - `(1, 4)` → stars `(0,1,2),(0,2,3),(1,0,4)`, completed `[0, 1]`;
  - `(4, 2)` (XP went down) → null;
  - `(0, 99)` → all 5 stars, completed `[0, 1, 2]`;
  - `(−1, 2)` throws.
- [ ] **Step 2:** `TZ=Europe/Kyiv flutter test test/features/path/domain/star_moment_test.dart` → FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(path): the star moment from celebrated and current stars`.

### Task 5: The route asset, its provider and constellation names

**Files:**
- Create:
  - `lib/features/path/data/route_asset.dart`;
  - `lib/features/path/presentation/providers/route_provider.dart`;
  - `lib/features/path/presentation/providers/constellation_name.dart`;
  - `test/helpers/route_fixture.dart`.
- Modify: `lib/l10n/app_en.arb` and `lib/l10n/app_uk.arb` (16 keys `constellationSge` … `constellationSgr` with the Global Constraints names; the en entries get `@` descriptions).
- Test:
  - `test/features/path/data/route_asset_test.dart`;
  - `test/features/path/presentation/providers/route_provider_test.dart`;
  - `test/features/path/presentation/providers/constellation_name_test.dart`.

**Interfaces:**
- Consumes: Task 1.
- Produces:
  - `Route parseRouteAsset(String json)`. It reads `route.main` and `route.branch` in order (`mainLength` = main length) and `constellations.<id>` (`stars[{hip,x,y,mag,ra,dec}]`, `lines`, `order`, `centre{ra,dec}`, `spanDeg`). It sets `milkyWay` from `const _edge = {'Tau', 'Gem', 'Ori'}`. A missing key, a wrong type or an id missing from `constellations` throws `RouteException` naming what failed.
  - `Future<Route> loadRouteAsset(AssetBundle bundle)`, which reads `assets/sky/route.json`.
  - `@Riverpod(keepAlive: true) Future<Route> route(Ref ref)`, which loads through `rootBundle`.
  - `String constellationName(AppLocalizations l10n, String id)`, a switch over the 16 ids that throws `ArgumentError` for others.
  - `Route testRoute()` in `test/helpers/route_fixture.dart`, which parses `File('assets/sky/route.json')` synchronously for unit and widget tests.

- [ ] **Step 1: Failing tests.**
  - `parseRouteAsset` on the real file:
    - 16 constellations, ids in the asset route order, `mainLength` 13;
    - `route.stars.length` is 177, and the stars with `constellationIndex < 13` number 140;
    - `ownerOf(25428)` is the index of `Aur`, and `Tau`'s `ownOrder` has 11 entries;
    - `milkyWay` is `edge` exactly for Tau, Gem and Ori;
    - `pathProgress(16 870, route)` gives `starsLit` 4, next `(1, 0, 1 870, 7 500)` (Стріла complete, the first star of Лисичка).
  - `parseRouteAsset` throws `RouteException` for:
    - no `route` key;
    - an id in `route.main` missing from `constellations`, with the id in the message;
    - a star without `hip`.
  - `routeProvider` resolves to 16 constellations under `TestWidgetsFlutterBinding` (listen before reading `.future`).
  - `constellationName`: every route id gives a non-empty string in both `uk` and `en` (`lookupAppLocalizations`); spot checks `Sge` → «Стріла» / "Sagitta" and `CMa` → «Великий Пес» / "Canis Major"; an unknown id throws.
- [ ] **Step 2:** `TZ=Europe/Kyiv flutter test test/features/path` → FAIL.
- [ ] **Step 3:** Implement, then `dart run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n`.
- [ ] **Step 4:** PASS; `dart analyze --fatal-infos` clean.
- [ ] **Step 5:** Commit `feat(path): load the route asset and name its constellations`.

### Task 6: Today shows stars; levels, titles and gender removed

**Files:**
- Modify:
  - `lib/features/today/presentation/providers/today_view.dart` and `today_provider.dart`;
  - `lib/features/today/presentation/today_screen.dart`;
  - `lib/features/today/presentation/widgets/today_card.dart` and `progress_sheet.dart`;
  - `lib/l10n/app_en.arb` and `app_uk.arb`;
  - `docs/ARCHITECTURE.md` (domain lines for `features/path`, Today data flow, remove level titles and `grammaticalGenderProvider`, open question on gender removed);
  - `docs/ROADMAP.md` (tick plan 2);
  - the tests `today_provider_test.dart` and `today_screen_test.dart`.
- Rename: `widgets/level_ring.dart` → `widgets/progress_ring.dart` (`LevelRing` → `ProgressRing`, doc comment "progress through the current star").
- Delete:
  - `lib/features/progress/domain/level_curve.dart`, `level_titles.dart`;
  - `lib/features/progress/presentation/providers/level_title.dart`;
  - `lib/core/text/roman_numerals.dart`;
  - their tests (`level_curve_test.dart`, `level_titles_test.dart`, `level_title_test.dart`, `roman_numerals_test.dart`).
- ARB keys:
  - removed: `levelTitle1`–`levelTitle25`, `levelChapter1`–`levelChapter5`, `levelTitleContinuation`, `levelLabel`, `xpToNextLevel`, `xpRange`;
  - added:

| Key | en | uk |
|---|---|---|
| `percentValue` (`{value}` int) | `{value}%` | `{value} %` (non-breaking space, U+00A0) |
| `nowHere` | You are here | Зараз тут |
| `starFilled` (`{percent}` String) | Star {percent} full | Зорю заповнено на {percent} |
| `xpToNextStar` (`{xp}` String) | {xp} XP to the next star | Ще {xp} XP до наступної зорі |
| `routeComplete` | The whole route is lit | Увесь шлях засвічено |

**Interfaces:**
- Consumes: `routeProvider`, `pathProgress`, `constellationName`, `testRoute()`.
- Produces: `TodayView` loses `level`, `levelStartXp` and `nextLevelXp`. It gains `PathProgress progress`, `String constellationId` (the id of `next.constellationIndex`, or of the last constellation when `next` is null) and `int starPercent` (`floor(xpIntoStar × 100 / xpForStar)`, or 100 when `next` is null). `todayProvider` stays `Stream<TodayView>`: it awaits `ref.watch(routeProvider.future)`, then maps `watchDays` as before.

- [ ] **Step 1: Failing tests.**
  - `today_provider_test`: 16 870 XP of days gives `progress.starsLit` 4, `constellationId` `'Vul'`, `starPercent` 24. XP past the whole route gives `next` null, `starPercent` 100 and `constellationId` `'Sgr'`. No days gives `starsLit` 0, `Sge`, 0.
  - `today_screen_test` (override `routeProvider` with `testRoute()`; en and uk):
    - the collapsed sheet shows "You are here" and "Vulpecula" above the tab bar;
    - the ring label reads "24%" in en and "24 %" in uk;
    - the expanded sheet shows "Star 24% full" and "5,630 XP to the next star";
    - with the whole route lit the sheet shows "The whole route is lit" and no progress bar;
    - no text contains "Level".
- [ ] **Step 2:** `TZ=Europe/Kyiv flutter test test/features/today` → FAIL.
- [ ] **Step 3:** Implement.
  - Card: `ProgressRing(fraction: starPercent / 100)` with the `percentValue` label in place of the level number.
  - Sheet collapsed: `nowHere` (footnote), constellation name (title), a progress bar of the current star.
  - Sheet expanded: adds `starFilled` and `xpToNextStar`; with `next` null it shows `routeComplete` instead of the bar and both lines.
  - Remove the `gender` parameter and the `grammaticalGenderProvider` watch. Delete the files and keys listed above.
  - Regenerate: pigeon, then build_runner, then gen-l10n.
- [ ] **Step 4:** `TZ=Europe/Kyiv flutter test` → all pass. `grep -rniE "levelProgress|levelTitle|GrammaticalGender|toRoman|LevelRing" lib test` → no matches.
- [ ] **Step 5:** Update ARCHITECTURE.md and ROADMAP.md.
- [ ] **Step 6:** Full gate with `lib/main_preview.dart` moved out: `dart format --output=none --set-exit-if-changed .`, `dart analyze --fatal-infos`, `TZ=Europe/Kyiv flutter test --coverage`, `dart run tool/coverage/check_coverage.dart`. Move the file back.
- [ ] **Step 7:** Commit `feat(today): show star progress instead of levels` and `docs: path domain in architecture`; push; open the PR.

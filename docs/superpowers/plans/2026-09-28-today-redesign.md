# Today redesign: the current constellation in the sky (constellation path, plan 4 of 7) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Today becomes the hybrid "C" screen, laid out in zones:
- the card at the top: today's steps, a ring for the current star with its percent, and the date on its own line;
- the current constellation drawn in the sky below it, with its name: lit stars, the current-star marker, faint rings for the stars ahead, solid lines behind and dashed lines ahead;
- a hills silhouette under the constellation;
- a sheet with the day's contribution ("+6 870 XP сьогодні", "Зорю заповнено на 62 %"), the week, and a link to Path.

Nothing sits under the tab bar.

**Architecture:**
- A pure domain function, `figureStates`, turns `(SkyRoute, PathProgress)` into a state per figure star (`lit`, `current`, `ahead`) and per line (solid or not).
- `todayProvider` adds the current `Constellation` and its `FigureStates` to `TodayView`.
- `ConstellationFigure`, a `CustomPaint`, draws it with new palette tokens. Its marker is a static code-drawn beacon; plan 6 animates it through the Rive contract, with this painter as the fallback.
- `TodayScreen` stacks the zones: the card, the figure zone (between the card and the collapsed sheet), the silhouette and the sheet.

**Tech Stack:** Flutter `CustomPainter`, Riverpod 3, gen-l10n, flutter_test. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-28-constellation-path-design.md`:
- Decisions: Today, Current marker, Themes;
- Components → Presentation → Today and the Layout rule;
- Success criteria: tab-bar clearance, labels ≥ 11 pt, WCAG AA;
- Testing → Widgets.

Look: `full-concept-v4.html`, "«Сьогодні»", with the reviewer changes the spec adopted: the sheet shows the day's contribution rather than the Path summary, the ring has a % label, and the sky label is in sentence case with no letter-spacing.

## Global Constraints

- Star states for the current constellation:
  - **lit**: lit by an earlier constellation (a shared star), or among this constellation's own stars lit so far;
  - **current**: the next star (`progress.next`);
  - **ahead**: the rest.

  With the whole route lit, every star of the last constellation is lit and there is no current star.
- A line is solid when neither end is ahead (it reaches the current star, as in the concept), and dashed otherwise.
- New palette tokens (ARGB):

| Token | Dark | Light |
|---|---|---|
| `star` | `#FFFFFF` | `#3D4F9A` |
| `starGlow` | `#F3E3BE` at 22 % (`0x38F3E3BE`) | transparent (`0x003D4F9A`) |
| `starLine` | `#F3E3BE` at 80 % (`0xCCF3E3BE`) | `#3D4F9A` at 70 % (`0xB33D4F9A`) |
| `starAhead` | `#C8D2F0` at 45 % (`0x73C8D2F0`) | `#3D4F9A` at 38 % (`0x613D4F9A`) |
| `aheadLine` | `#C8D2F0` at 30 % (`0x4DC8D2F0`) | `#3D4F9A` at 25 % (`0x403D4F9A`) |
| `marker` | `#FFE9B8` | `#3D4F9A` |

- Contrast: `star` and `marker` against every `sky` colour ≥ 3:1. Stars are UI marks, not text.
- Star core radius (logical px): `(3.5 − 0.5 × mag).clamp(1.5, 3.5)`. The dark theme also draws a glow of 3 × that radius in `starGlow`.
- Ahead stars are a ring of radius 3 at stroke 0.8. Solid lines have stroke 1, dashed lines stroke 0.8 with dash 2 / gap 4.
- The marker is static in this plan: a core of radius 3.2 in `star`, and a ring of radius 9 at stroke 0.8 in `marker` at 60 % with a gap (dash 40 / gap 16.5 of the circumference). It also has two cross spikes of half-length 16 at stroke 0.7 in `marker` at 50 %, and a soft disc of radius 16 in `marker` at 12 %.
- The figure is fitted into its zone with 24 pt padding on each side, keeping the asset's aspect (the unit box is square). The constellation name sits under the figure, inside the zone: `footnote` in `onSkyMuted`, sentence case, no letter-spacing.
- Zones:
  - the card is at the top (SafeArea);
  - the figure zone runs from the card (or the health hint) down to the top of the collapsed sheet;
  - the silhouette sits behind the lower part of the zone and the sheet;
  - the sheet is collapsed at its current height, with its content above the tab bar.
- Copy (uk / en):

| Key | uk | en |
|---|---|---|
| `todayContribution` (`{xp}` String) | +{xp} XP сьогодні | +{xp} XP today |
| `todayStepsLabel` (`{count}` int, plural) | крок / кроки / кроків / кроку сьогодні | step / steps today |
| `pathLink` | Увесь шлях → | The whole path → |

  `starFilled`, `xpToNextStar`, `routeComplete`, `percentValue`, the week keys and the stat keys stay.

  Removed keys: `todayStepsCaption` (the date becomes its own line through `formatLongDate`), `nowHere`, and `historyLink` (History stays a tab).
- The hills silhouette: the three existing ridges in `palette.hills`, without the path and without the user's dot. Спільно members appear on constellations in stage 5.
- Tests run with `TZ=Europe/Kyiv`; Pigeon before build_runner; `lib/main_preview.dart` is local only.
- Branch `feat/today-redesign` from `main` after PR #26 is merged.

## Review Focus

- **Large text (2.0).** The card and the sheet grow and the figure zone shrinks. The figure must never paint over the card or the sheet, and must not throw when the zone is tiny or 0 high (it hides, or draws at the size that fits). Tested in Task 3.
- **The whole route lit.** The figure shows Sagittarius fully lit with no marker; the sheet shows `routeComplete` and no bar. Tested in Tasks 1 and 3.
- **A shared star.** On Taurus, Elnath shows lit from the start (Auriga lit it), with a solid line to the current star when it is the neighbour. Tested in Task 1 on the real asset.
- **Light theme.** Lit stars and lines in ink blue are visible on the pale sky; ahead rings are fainter but present. Contrast is tested in Task 2.
- **The health hint shown.** The figure zone starts below the hint, not under it. Tested in Task 3.

---

### Task 1: Figure states

**Files:**
- Create: `lib/features/path/domain/figure_state.dart`
- Test: `test/features/path/domain/figure_state_test.dart`

**Interfaces:**
- Consumes: `SkyRoute`, `PathProgress`, `NextStar`.
- Produces:
  - `enum StarState { lit, current, ahead }`
  - `typedef FigureStates = ({int constellationIndex, List<StarState> stars, List<bool> solidLines});`, where `stars` is indexed like `Constellation.stars` and `solidLines` like `Constellation.lines`.
  - `FigureStates figureStates(SkyRoute route, PathProgress progress)`: the constellation of `progress.next`, or the last one when `next` is null.

- [ ] **Step 1: Failing tests** on `smallRoute()` (A: hips 1, 2, 3; B: 3 shared, 4; C: 5):
  - 0 XP → A: `[current, ahead, ahead]`, lines `[false, false]`;
  - 1 500 XP → A: `[lit, current, ahead]`, lines `[true, false]`;
  - 9 000 XP → B: `[lit, current]` (hip 3 lit by A), lines `[true]`;
  - 22 500 XP → C, `[lit]`, no lines;
  - a figure with a line between two ahead stars is dashed;
  - on `testRoute()` with the XP of 50 lit stars, the result is the constellation of the 51st route star, the number of `current` entries is 1, and the `lit` count equals the stars lit in it so far plus the shared ones;
  - on `testRoute()` at the first own star of Taurus, Elnath's index in Taurus is `lit`.
- [ ] **Step 2:** `TZ=Europe/Kyiv flutter test test/features/path/domain/figure_state_test.dart` → FAIL.
- [ ] **Step 3:** Implement. A star's position in `ownOrder` against `next.starInConstellation` decides lit / current / ahead; a star not in `ownOrder` is lit, since an earlier constellation owns it.
- [ ] **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(path): states of the current figure's stars and lines`.

### Task 2: Star tokens

**Files:**
- Modify: `lib/core/design/app_palette.dart` (six colours: `star`, `starGlow`, `starLine`, `starAhead`, `aheadLine`, `marker`; wired into the constructor, `copyWith` and `lerp`), `docs/DESIGN.md` (the token table).
- Test: `test/core/design/app_palette_test.dart`.

- [ ] **Step 1: Failing tests.**
  - The six values for dark and light from the Global Constraints.
  - `star` and `marker` against every `sky` colour ≥ 3.
  - `lerp` blends the new colours; `copyWith(star: …)` changes only `star`.
- [ ] **Step 2:** `TZ=Europe/Kyiv flutter test test/core/design/app_palette_test.dart` → FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(design): star tokens for the constellation figure`.

### Task 3: The figure, the silhouette and the Today layout

**Files:**
- Create: `lib/features/today/presentation/widgets/constellation_figure.dart`.
- Rename: `widgets/placeholder_hills.dart` → `widgets/hills_silhouette.dart` (`HillsSilhouette`, no parameters: no path, no dot).
- Modify:
  - `lib/features/today/presentation/providers/today_view.dart` and `today_provider.dart`: `constellationId` is replaced by `Constellation constellation`, and `FigureStates figure` is added;
  - `lib/features/today/presentation/today_screen.dart` (zones);
  - `widgets/today_card.dart` (two lines under the number);
  - `widgets/progress_sheet.dart`: contribution first; no name, no "You are here"; a Path link instead of the History link; `static double collapsedHeight(BuildContext context)` exposed for the zone;
  - `lib/l10n/app_en.arb`, `app_uk.arb`.
- Test:
  - `test/features/today/presentation/providers/today_provider_test.dart`;
  - `test/features/today/presentation/widgets/constellation_figure_test.dart`;
  - `test/features/today/presentation/today_screen_test.dart`.

**Interfaces:**
- Consumes: `figureStates` (Task 1), the star tokens (Task 2), `constellationName`.
- Produces:
  - `ConstellationFigure({required Constellation constellation, required FigureStates figure, super.key})`. It paints the figure and, below it, `Text(constellationName(...))`. Its `Semantics` label is the constellation name.
  - `@visibleForTesting Offset figurePoint(SkyPoint star, Rect box)`: the star's position in `box`, the square of side `min(width, height) − 2 × 24` centred in the zone.

- [ ] **Step 1: Failing tests.**
  - `today_provider_test`: the 16 870 XP days give `constellation.id` `'Vul'` and `figure.stars.first` `current`; the whole route lit gives `constellation.id` `'Sgr'` and every star `lit`.
  - `constellation_figure_test`:
    - `figurePoint` puts `(0, 0)` and `(1, 1)` at the corners of the padded, centred square in a 300 × 200 zone;
    - the figure renders in both themes with the name text;
    - in a zone 0 high it throws nothing (`tester.takeException()` is null).
  - `today_screen_test`:
    - "Vulpecula" (the sky label) is below the card's bottom and above the top of the collapsed sheet;
    - the collapsed sheet shows "+6,870 XP today" and "Star 24% full" above the tab bar;
    - the card shows "6,870", "steps today" and "Monday, September 28" as separate lines; in uk: "6 870", "кроків сьогодні", "понеділок, 28 вересня";
    - the expanded sheet shows "The whole path →", and tapping it opens Path ("Your path is coming soon");
    - with the health hint shown, the `ConstellationFigure` rect starts below the hint;
    - with text scale 2, the figure's rect does not overlap the card's or the collapsed sheet's, and there is no exception;
    - with the whole route lit: "Sagittarius" in the sky, "The whole route is lit" in the sheet, no `LinearProgressIndicator`;
    - both themes: the tab-bar clearance test and the contrast of the name (`onSkyMuted`) against the sky colour at its position;
    - update the existing tests: drag the sheet by "+6,870 XP today"; there is no "You are here" and no "All history →".
- [ ] **Step 2:** `TZ=Europe/Kyiv flutter test test/features/today` → FAIL.
- [ ] **Step 3:** Implement.
  - **Painter order:** dashed lines, solid lines, glows, lit cores, ahead rings, then the marker.
  - **Hiding:** skip painting when the square's side is ≤ 0; hide the name when the zone is shorter than the name's line height.
  - `shouldRepaint` compares the palette, `figure` and `constellation` by identity.
  - Regenerate l10n.
- [ ] **Step 4:** `TZ=Europe/Kyiv flutter test` → all pass; `dart analyze --fatal-infos` clean.
- [ ] **Step 5:** Commit `feat(today): the current constellation in the sky`.

### Task 4: Docs, gate, simulator, PR

**Files:**
- Modify:
  - `docs/ARCHITECTURE.md`: the Today screen paragraph (`figureStates`, `ConstellationFigure`, `HillsSilhouette`, zones);
  - `docs/DESIGN.md`: a "Constellation figure" section with the sizes and the marker from the Global Constraints, and the layout zones;
  - `docs/ROADMAP.md`: tick plan 4;
  - `docs/PRODUCT.md`: "Today screen content", the sheet's contents.

- [ ] **Step 1:** Update the docs.
- [ ] **Step 2:** Full gate, with `lib/main_preview.dart` moved out: format, `dart analyze --fatal-infos`, `TZ=Europe/Kyiv flutter test --coverage`, `dart run tool/coverage/check_coverage.dart`.
- [ ] **Step 3:** Run on the simulator in dark and light. Screenshot Today with steps (use `lib/main_preview.dart` locally with a fake repository if the simulator has no steps), and check the zones by eye.
- [ ] **Step 4:** Commit `docs: the Today constellation in design and architecture`; push; open the PR.

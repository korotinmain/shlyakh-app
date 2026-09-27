# Design Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Design tokens in code — a time-of-day sky (Oklab-interpolated keyframes placed by a NOAA sun calculation), member colours, Geologica typography, spacing, radii, matte glass and motion — plus `docs/DESIGN.md`, replacing the placeholder seed colour.

**Architecture:** Pure-Dart colour and sun math in `lib/core/design/sky/` (ARGB `int`s, no Flutter), thin Flutter token files in `lib/core/design/`, `lib/app/theme.dart` built from tokens. Geologica is bundled as one variable font.

**Tech Stack:** Dart 3.13, Flutter 3.47 (`FontVariation`, `FontFeature`), flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-27-design-foundation-design.md`

## Global Constraints

- Branch `feat/design-foundation`; Conventional Commits ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- No new dependencies. The font is an asset, not a package.
- All colour values, timings, sizes and member colours exactly as in the spec tables.
- Sky and sun code: pure Dart, `int` ARGB (`0xAARRGGBB`), no `dart:ui`; time only from arguments (callers pass the injected `Clock`'s time; no `DateTime.now()`).
- Downloading the font requires the developer's explicit approval of: `Geologica[CRSV,SHRP,slnt,wght].ttf` (348 640 bytes) and `OFL.txt` (4 400 bytes) from `github.com/google/fonts/tree/main/ofl/geologica`. Save as `assets/fonts/geologica/Geologica-Variable.ttf` and `assets/fonts/geologica/OFL.txt`.
- Gate before each commit: `dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && flutter test --coverage && dart run tool/coverage/check_coverage.dart`.

## Review Focus

- A DST change (Kyiv, last Sunday of March / October) must shift local keyframe times by exactly the offset change, not by a day. Test in Task 2.
- 00:30 local (after midnight, before `preDawn`) must be `night`, not the previous day's interpolation running backwards. Test in Task 3.
- The blend into `preDawn` must be continuous: 1 minute before `preDawn` is almost `preDawn`, 61 minutes before is exactly `night`. Test in Task 3.
- Oklab interpolation between a warm and a cool colour (`goldenHour` sky bottom → `blueHour` sky bottom) must not pass through a mid-grey. Test in Task 1.
- Bold and Regular must render at different weights with the variable font (not both at the default axis). Verified visually in Task 5.

## Reference values (sunrise-sunset.org API, lat 50.45, lng 30.52, UTC)

| Date | Sunrise | Solar noon | Sunset |
|---|---|---|---|
| 2026-03-20 | 03:58:50 | 10:05:24 | 16:11:57 |
| 2026-06-21 | 01:44:09 | 09:59:43 | 18:15:18 |
| 2026-09-22 | 03:42:38 | 09:50:39 | 15:58:40 |
| 2026-12-21 | 05:53:48 | 09:55:56 | 13:58:04 |

---

### Task 1: Oklab

**Files:** Create `lib/core/design/sky/oklab.dart`; Test `test/core/design/sky/oklab_test.dart`

**Interfaces — Produces:** `typedef Oklab = ({double l, double a, double b});` `Oklab toOklab(int argb)`, `int fromOklab(Oklab c, {int alpha = 0xFF})` (clamps to sRGB), `int lerpArgb(int from, int to, double t)` (Oklab lerp; alpha linear; `t` clamped to 0–1).

- [ ] **Step 1: Failing tests:** round-trip within 1 per channel for all 42 spec palette colours plus `0xFF000000`, `0xFFFFFFFF`; `lerpArgb(x, y, 0) == x`, `(…, 1) == y`; Oklab midpoint of black/white ≠ `0xFF808080` (it is `0xFF636363` ± 1); `lerpArgb(0xFFF7DCB0, 0xFFA2B0CF, .5)` has chroma `sqrt(a²+b²)` of its Oklab > 0.02 (not grey).
- [ ] **Step 2:** Run `flutter test test/core/design/sky/oklab_test.dart` — FAIL (not defined).
- [ ] **Step 3:** Implement with the published Oklab matrices (Björn Ottosson) and sRGB transfer functions.
- [ ] **Step 4:** Run — PASS; commit `feat(design): Oklab colour interpolation`.

### Task 2: Sun times

**Files:** Create `lib/core/design/sky/solar.dart`; Test `test/core/design/sky/solar_test.dart`

**Interfaces — Produces:** `typedef SunTimes = ({DateTime sunrise, DateTime solarNoon, DateTime sunset});` (UTC); `SunTimes? sunTimesUtc({required int year, required int month, required int day, required double latitude, required double longitude})` — `null` when the sun does not rise or set that day. `const kyivLatitude = 50.45; const kyivLongitude = 30.52;`

- [ ] **Step 1: Failing tests:** each row of the reference table within ±3 min (sunrise, noon, sunset); latitude 80, 2026-06-21 → `null` (polar day, no throw); latitude 80, 2026-12-21 → `null`.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3:** Implement the NOAA general solar position equations (fractional year, equation of time, declination, hour angle for zenith 90.833°).
- [ ] **Step 4:** Run — PASS; commit `feat(design): NOAA sunrise and sunset`.

### Task 3: Sky keyframes and palette

**Files:** Create `lib/core/design/sky/sky_keyframes.dart`, `lib/core/design/sky/sky_palette.dart`; Test `test/core/design/sky/sky_palette_test.dart`

**Interfaces:**
- Consumes: `lerpArgb` (Task 1), `sunTimesUtc` (Task 2).
- Produces:
  - `enum SkyKeyframe { preDawn, dawn, morning, day, goldenHour, blueHour, night }`
  - `enum SurfaceTone { light, dark }`
  - `typedef SkyPalette = ({List<int> sky, List<int> hills, int accent, int onSky, SurfaceTone surfaceTone});` (`sky` and `hills` have 3 entries)
  - `const Map<SkyKeyframe, SkyPalette> skyKeyframes` — spec table values.
  - `SkyPalette skyAt(DateTime local, {double latitude = kyivLatitude, double longitude = kyivLongitude})` — computes sun times for `local`'s calendar date, converts them with `local.timeZoneOffset`, places keyframes per the spec timing table, holds `night` until 60 min before `preDawn`, then blends into `preDawn`; interpolates every colour with `lerpArgb`; `onSky` and `surfaceTone` switch at the halfway point between keyframes. Polar `null` → `day` palette for lat > 0 in Apr–Sep, else `night`.
  - `SkyPalette lerpPalette(SkyPalette a, SkyPalette b, double t)`

- [ ] **Step 1: Failing tests** (build `local` as `DateTime(2026, 6, 21, h, m)` with a fixed offset by passing UTC-shifted instants through a helper `atKyivSummer(h, m)` that constructs `DateTime.utc(...)` minus 3 h and a test-only offset parameter — see Step 3 note):
  - at each keyframe instant for 2026-06-21 the palette equals `skyKeyframes[k]` exactly;
  - halfway between `day` and `goldenHour` it differs from both;
  - 00:30 → `night` exactly; 60 min before `preDawn` → `night`; 1 min before `preDawn` → within 2% of `preDawn` per channel;
  - DST: sunrise-relative `dawn` on 2026-03-28 (+02:00) vs 2026-03-29 (+03:00) differs by ~1 h in local clock time and ~1–2 min in UTC;
  - table of `onSky` and `surfaceTone` per keyframe.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3:** Implement. Note: Dart's `DateTime` cannot carry an arbitrary offset in tests; give `skyAt` an optional named `Duration? utcOffset` (default `local.timeZoneOffset`) so tests are deterministic regardless of the machine's zone. Record this as a ruling.
- [ ] **Step 4:** Run — PASS; commit `feat(design): time-of-day sky palette`.

### Task 4: Colour, spacing, radii, glass and motion tokens

**Files:** Create `lib/core/design/app_colors.dart`, `app_spacing.dart`, `app_radii.dart`, `app_motion.dart`, `glass.dart`; Test `test/core/design/app_colors_test.dart`

**Interfaces — Produces:** `const memberColors` (6 ARGB ints in spec order); `int memberColorFor(String userId)` (FNV-1a 32-bit over UTF-8 bytes, modulo 6); `extension ArgbColor on int { Color get color; }`; `abstract final class AppSpacing` (`xxs 4, xs 8, s 12, m 16, screen 20, l 24, xl 32, xxl 48`); `AppRadii` (`card 20, sheet 24`); `AppMotion` (`fast 150ms, normal 300ms, slow 600ms, curve easeOutCubic`); `GlassStyle` (`lightTint 0xADFFFFFF` = 68%, `darkTint 0xB8161C38` = 72%, `blurSigma 12`, shadow `BoxShadow(color: 0x29000000, offset: Offset(0, 6), blurRadius: 18)`).

- [ ] **Step 1: Failing tests:** `memberColorFor('user-a')` equals itself across calls and equals a hard-coded expected index computed once in the test from the FNV-1a definition; 60 ids `user-0…user-59` hit all 6 colours; FNV-1a of `''` is `0x811C9DC5` (offset basis) and of `'a'` is `0xE40C292C`.
- [ ] **Step 2:** Run — FAIL. **Step 3:** Implement. **Step 4:** Run — PASS; commit `feat(design): colour, spacing, radius, glass and motion tokens`.

### Task 5: Typography, theme and docs

**Files:** Add `assets/fonts/geologica/Geologica-Variable.ttf`, `assets/fonts/geologica/OFL.txt` (after approval); Modify `pubspec.yaml` (`flutter: fonts: - family: Geologica, fonts: - asset: assets/fonts/geologica/Geologica-Variable.ttf`); Create `lib/core/design/app_typography.dart`; Modify `lib/app/theme.dart`; Create `docs/DESIGN.md`; Modify `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`; Test `test/core/design/app_typography_test.dart`, `test/app/app_test.dart` (extend).

**Interfaces — Produces:** `abstract final class AppTypography` with `hero, display, title, headline, body, footnote, caption` `TextStyle`s (family `Geologica`, spec size/weight, each with `fontVariations: [FontVariation.weight(w)]` and `fontWeight` matching; `hero/display/title` letterSpacing `-0.02 * size`); `TextStyle tabular(TextStyle s)` adds `FontFeature.tabularFigures()`; `TextTheme appTextTheme()`. `buildAppTheme()` uses `fontFamily: 'Geologica'`, `appTextTheme()`, and a `ColorScheme.fromSeed(seedColor: skyKeyframes[SkyKeyframe.day]!.accent.color)`; the old `_seedColor` constant is removed.

- [ ] **Step 1: Failing tests:** each style's size, weight and `wght` variation match the spec; `tabular` adds the feature; app test asserts `Theme.of(context).textTheme.bodyMedium!.fontFamily == 'Geologica'`.
- [ ] **Step 2:** Run — FAIL. **Step 3:** Download the approved files, register the font, implement typography and theme.
- [ ] **Step 4: Visual check:** build and run on the iPhone 16 Pro simulator a temporary debug screen (not committed) showing each style; screenshot; confirm 300/400/500/700 look different. Remove the temporary screen.
- [ ] **Step 5: Docs:** `docs/DESIGN.md` (principles recap; palette + timing tables; typography scale; surfaces; spacing; radii; motion; "Delivering art for phase D": separate layer files, SVG or @3x PNG, monochrome or neutral daylight, licence allows app use). ARCHITECTURE: design tokens [built] + section 2 bullet. ROADMAP: tick phase B.
- [ ] **Step 6:** Full gate; commit `feat(design): Geologica typography and token-based theme` and `docs: DESIGN.md with the design foundation`; push; PR.

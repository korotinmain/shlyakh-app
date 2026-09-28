# XP and level rules — design

Date: 2026-09-27
Status: daily XP rules in force; the level curve and titles are
superseded by `2026-09-28-constellation-path-design.md` (stars replace
levels) and are removed from the code in its plan 2.

## Goal

Define how daily step counts become XP and how XP becomes levels, as pure,
deterministic domain logic with full test coverage. Closes the open
question "XP formula and level curve" in `docs/PRODUCT.md`.

## Product decisions (from the conversation)

- The journey is **finite with a continuation**: a main path of 25 levels
  that ends at **1 000 000 XP** ("a million steps"), then levels continue
  at a constant pace ("a new trail"). A second landscape for the trail is
  out of scope; the model only has to support levels above 25.
- The main path takes **about a year** at a typical pace (~2 750 steps a
  day; ~1.5 years at 1 800). First levels arrive within days, the last
  ones about once a month (every six weeks at 1 800 steps a day). One
  capped day early on can bring several levels at once.
- **Calm, not pushy:** no penalties, no streaks, no XP ever lost. A day
  without steps gives 0 XP and nothing else.
- Both users use the same rules.

## Rules

### Daily XP

Each local day (a `local_date`, see AGENT_RULES 4) is scored on its own:

```
dailyXp(steps) = min(steps, 10 000) + (max(steps − 10 000, 0) ~/ 2), capped at 20 000
```

- Up to 10 000 steps: 1 XP per step.
- Above 10 000: 1 XP per 2 steps, integer division (fractions dropped,
  like HealthKit's step totals).
- Cap: 20 000 XP per day, reached at 30 000 steps. Protects the pace from
  a single hike and from sensor glitches (AGENT_RULES 8.6, "a very large
  value").
- Negative steps are a data bug: `ArgumentError`, never silently clamped.

| Steps | XP |
|---|---|
| 0 | 0 |
| 500 | 500 |
| 10 000 | 10 000 |
| 10 001 | 10 000 |
| 10 002 | 10 001 |
| 25 000 | 17 500 |
| 30 000 | 20 000 |
| 500 000 | 20 000 |

### Total XP

`totalXp = Σ dailyXp(steps of day)` over all days. Never stored as a
counter; recomputed from daily steps whenever they change (CLAUDE.md,
Rules). Re-scoring a day after a later HealthKit sync can only raise the
total, because step counts only grow.

### Levels

- Everyone starts at **level 1 with 0 XP**.
- Level `n` for `2 ≤ n ≤ 25` is reached at
  `threshold(n) = round_to_100(1 000 000 · ((n − 1) / 24)²)`,
  computed in integers as `(1 000 000 · (n − 1)² + 28 800) ~/ 57 600 · 100`
  (no exact halves occur, so the rounding mode never matters).
- Continuation: level `25 + k` (`k ≥ 1`) is reached at
  `1 000 000 + k · 81 600`, where 81 600 = `threshold(25) − threshold(24)`.
  No upper bound.

| Level | XP | Level | XP | Level | XP |
|---|---|---|---|---|---|
| 1 | 0 | 10 | 140 600 | 19 | 562 500 |
| 2 | 1 700 | 11 | 173 600 | 20 | 626 700 |
| 3 | 6 900 | 12 | 210 100 | 21 | 694 400 |
| 4 | 15 600 | 13 | 250 000 | 22 | 765 600 |
| 5 | 27 800 | 14 | 293 400 | 23 | 840 300 |
| 6 | 43 400 | 15 | 340 300 | 24 | 918 400 |
| 7 | 62 500 | 16 | 390 600 | 25 | 1 000 000 |
| 8 | 85 100 | 17 | 444 400 | 26 | 1 081 600 |
| 9 | 111 100 | 18 | 501 700 | 27 | 1 163 200 |

## Domain API

Pure Dart in `lib/features/progress/domain/` (no Flutter, no Clock: the
rules do not depend on time; day boundaries belong to the data layer).

```
xp_rules.dart
  int dailyXp(int steps)
  int totalXp(Iterable<int> dailySteps)

level_curve.dart
  const mainPathLevels = 25;
  const mainPathXp = 1000000;
  int xpToReachLevel(int level)          // level ≥ 1; ArgumentError below 1
  LevelProgress levelProgress(int totalXp)  // totalXp ≥ 0; ArgumentError below 0

  bool isOnMainPath(int level)            // level ≤ 25

  typedef LevelProgress = ({
    int level,           // current level, ≥ 1
    int xpIntoLevel,     // totalXp − xpToReachLevel(level)
    int xpForNextLevel,  // xpToReachLevel(level + 1) − xpToReachLevel(level)
  });
```

`LevelProgress` gives the UI everything for the progress ring and "N XP
to the next level" without recomputing thresholds in widgets. The gap is
XP, not steps: above 10 000 steps a day one XP costs two steps, so showing
it as steps needs today's count and a separate helper. It is a
record, so it has value equality without `package:meta` (same choice as
`FileCoverage` in the coverage tool).

Constants live next to the functions and are the single source of truth;
`docs/PRODUCT.md` states the rules in words and points here.

## Out of scope

- Level names (separate roadmap item; the domain exposes only numbers).
- Streaks, bonuses, goals, any time-based rule.
- Reading steps from HealthKit or Drift, day boundaries, time zones:
  data layer, later tasks.
- The dot's position on the landscape (open question in PRODUCT.md).

## Testing

Unit tests in `test/features/progress/domain/`, table-driven, 100% line
coverage (enforced by `tool/coverage/check_coverage.dart`):

- `dailyXp`: every row of the Daily XP table, plus `-1` → `ArgumentError`.
- `totalXp`: empty → 0; several days sum; a capped day inside a sum; a
  negative day → `ArgumentError`.
- `xpToReachLevel`: every row of the Levels table (1–27), level 0 →
  `ArgumentError`, a far level (e.g. 100 → `1 000 000 + 75 · 81 600`).
- `levelProgress`, each boundary: 0 → level 1; 1 699 → level 1 with
  1 699 into it; 1 700 → level 2 with 0 into it; 999 999 → level 24;
  1 000 000 → level 25; 1 081 599 → 25; 1 081 600 → 26;
  `isOnMainPath(25)` true, `isOnMainPath(26)` false; `xpForNextLevel` at level 24,
  25 and 26 equals 81 600; −1 → `ArgumentError`.
- A property-style check over levels 1–60: thresholds strictly increase,
  and `levelProgress(xpToReachLevel(n)).level == n`.

## Docs

- `docs/PRODUCT.md`: replace the open question with a short "XP and
  levels" section (rules in words, the million-step main path, the
  continuation, no penalties), pointing to this spec and the domain code.
- `docs/ARCHITECTURE.md`: mark XP/levels as built in sections 3 and 5
  when the code lands.
- `docs/ROADMAP.md`: tick "Decide XP formula and level curve" and "Pure
  Dart XP/level logic with unit tests".

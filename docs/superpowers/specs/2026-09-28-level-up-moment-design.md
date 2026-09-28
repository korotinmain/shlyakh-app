# Level-up moment (design phase E, part 1) — design

Date: 2026-09-28
Status: approved in chat (visual companion: form "A · full-screen scene", copy for three cases), pending spec review

## Goal

When the level rises, the user sees it: a full-screen scene over the app
with the new level, its chapter and title, the levels passed on the way,
and a single "Continue". It works for several levels at once (a big first
day reaches level 4) and marks a new chapter and the end of the main
path. History is part 2 of phase E, a separate spec. Motion, count-up and
haptics are phase F.

Depends on PR #22 (`journeyStartProvider`, the Drift-backed steps
repository, the access screen outside `AppShell`); implementation starts
after it is merged.

## Success criteria

- After a sync raises the level, the next time the app UI is in the
  foreground the scene appears, over any tab, exactly once per level
  reached.
- A jump of several levels shows one scene with the final level and the
  passed ones.
- The level shown by the ring can go down (samples deleted in Health), but
  no scene ever shows a lower level, and no level is celebrated twice
  (PRODUCT: no XP ever lost).
- uk and en, masculine and feminine titles; no hard-coded strings or
  design values.
- Domain 100% covered; data and providers ≥ 85%.

## Decisions (from the conversation)

| Topic | Decision |
|---|---|
| Form | "A": full-screen scene over the app; the sky dims, the new level is large in the centre with its chapter and title, one "Continue" button |
| When | Every level-up, as soon as the foreground UI sees a level above the last celebrated one; a level reached by a background sync shows at the next open |
| Several levels | One scene: the final level and "Along the way: …" with the passed levels and titles |
| New chapter | "B": the same scene with a "New chapter · …" line above the level (levels 6, 11, 16, 21). Level 25 has its own line about the end of the main path |
| Continuation (26+) | Plain scenes with the continuation title ("Star Wanderer II"), no chapter line |
| State | Last celebrated level in a new `journey_start.celebrated_level` column (part of the journey; synced with it in stage 5) |

## Copy

| Key | uk | en |
|---|---|---|
| `levelUpKicker` | "Новий рівень · {chapter}" | "New level · {chapter}" |
| `levelUpKickerNoChapter` (with the chapter line) | "Новий рівень" | "New level" |
| `levelUpNewChapter` | "Новий розділ · {chapter}" | "New chapter · {chapter}" |
| `levelUpAlongTheWay` | "Дорогою: {levels}" | "Along the way: {levels}" |
| `levelUpPassedLevel` (one item) | "{level} · {title}" | "{level} · {title}" |
| `levelUpMainPathDone` | "Мільйон кроків. Головний шлях пройдено — далі новий шлях." | "A million steps. The main path is done — a new trail begins." |
| `levelUpContinue` | "Далі" | "Continue" |

Level 25's kicker is the chapter name alone ("Чумацький Шлях" / "The Milky
Way"). Titles and chapter names come from the existing ARB keys with the
user's grammatical gender (`levelTitle`, `levelChapter`). Items of "Along
the way" are joined with ", ".

## Components

### Domain (`lib/features/progress/domain/level_up.dart`)

- `typedef LevelUp = ({int from, int to, List<int> passed, int? newChapter, bool finishesMainPath});`
- `LevelUp? levelUp({required int celebrated, required int current})` —
  null when `current <= celebrated`. `passed` are the levels strictly
  between `celebrated` and `current`, ascending. `newChapter` is the
  chapter of the highest level in `celebrated + 1 … current` that opens a
  chapter (6, 11, 16, 21 → 2, 3, 4, 5), null if none. `finishesMainPath`
  is true when 25 is in `celebrated + 1 … current`. Throws `ArgumentError`
  for levels below 1.

### Data

- `journey_start.celebrated_level INTEGER NOT NULL DEFAULT 1`,
  `CHECK (celebrated_level >= 1)`; schema v3, migration 2 → 3 adds the
  column (existing rows get 1); snapshot, steps and migration tests
  committed.
- `JourneyStart` gains `int celebratedLevel`; a new start stores 1.
- `JourneyStartDao.markCelebrated(String userId, int level)` — sets
  `celebrated_level = MAX(celebrated_level, level)`; no-op without a row.

### Presentation

- `levelUpProvider` (`features/progress/presentation/providers/`) —
  `Stream<LevelUp?>`: `levelUp(celebrated: start.celebratedLevel,
  current: level of all stored days)`, null without a journey start. The
  current level uses `levelProgress(totalXp(...))`, the same as Today.
- `LevelUpScene` (`features/progress/presentation/level_up_scene.dart`) —
  full-screen: current `SkyBackground`, a dim overlay (a new token in
  `lib/core/design/`), centred kicker, optional chapter line (accent
  background), level number (`AppTypography.hero`), title
  (`AppTypography.title`), optional main-path line or "Along the way"
  (`AppTypography.footnote`), "Continue" button in the accent. Scrolls
  with large text.
- `AppShell` puts the scene on top of the tabs and the tab bar while
  `levelUpProvider` has a value. "Continue" → a notifier calls
  `markCelebrated(userId, to)`; the provider then emits null and the scene
  goes. While the write runs the button is disabled; a `Failure` shows
  `failureMessage` above the button and the button works again.
- No route: nothing to navigate back to, deep links unaffected.

## Edge cases

| Case | Behaviour |
|---|---|
| Level went down (Health samples deleted) | No scene; `celebrated_level` stays; the next scene comes only above it |
| "Continue" tapped twice, or after another level-up | `markCelebrated` only raises; a newer level-up shows a new scene |
| No journey start | No scene (the access screen is outside `AppShell`) |
| Write fails | Scene stays, message shown, "Continue" retries |
| Levels 26+ | Plain scene with the continuation title, no chapter line |
| Jump 4 → 7 | Final 7, passed 5 and 6, chapter line for chapter 2 |
| Jump 24 → 26 | Final 26, passed 25, main-path line |

## Testing

- **Domain** (`level_up`): none (equal, lower); 1 → 2; 1 → 4 (`passed`
  2, 3); 5 → 6 (chapter 2); 4 → 7 (chapter 2 inside the jump); 24 → 26
  (`finishesMainPath`, passed 25); 30 → 31 (continuation, no chapter);
  level 0 → `ArgumentError`.
- **Data:** migration 2 → 3 (generated test; a `journey_start` row keeps
  its values and gets 1); `markCelebrated` raises, never lowers, no-op for
  another user; `celebratedLevel` round trip; a new start stores 1.
- **Provider:** days worth level 4 with celebrated 1 → `LevelUp(1, 4)`;
  after `markCelebrated(4)` → null; no start → null; days worth level 2
  with celebrated 3 → null.
- **Widgets:** the scene over Today for the three copy cases in uk and en,
  masculine and feminine; "Continue" hides it and stores the level; large
  text without overflow; a failing write shows the message and the button
  works again.

## Documentation

- PRODUCT.md: when the level-up scene appears and that no level is shown
  twice or lower.
- ARCHITECTURE.md §2: `levelUpProvider`, the scene in `AppShell`, schema
  v3.
- ROADMAP: phase E part 1 (level-up) done, history still open.

## Out of scope

- History (phase E, part 2).
- Count-up, motion, haptics (phase F); level-up notifications (stage 6).
- Illustrated chapter scenes (phase D).

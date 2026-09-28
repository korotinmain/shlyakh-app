# Today screen skeleton (design phase C) — design

Date: 2026-09-28
Status: approved in chat (visual companion: layout "A · Postcard", expanded sheet), pending spec review

## Goal

The first real screen: "Today" with the live sky, a matte glass card with
the level ring and today's steps, a two-position bottom sheet, and a
floating three-tab bar, built only from design tokens and l10n. Data comes
through a repository interface that a demo implementation fills until the
HealthKit → Drift repository exists.

## Success criteria

- On the simulator the Today screen looks right at any time of day (the
  sky follows `skyAt`) in Ukrainian and English.
- The sheet snaps between collapsed and expanded; the tab bar switches
  between Today, Path and History.
- No hard-coded colours, sizes or strings in widgets.
- Providers and domain logic are unit-tested; presentation/providers ≥ 85%,
  domain 100%.

## Decisions (from the conversation)

| Topic | Decision |
|---|---|
| Tabs | Three: Today, Path, History. Спільно becomes a fourth tab in stage 5. Path and History are placeholders in this phase |
| Layout | "A · Postcard": glass card with ring and steps at the top, landscape in the middle, bottom sheet, floating tab bar |
| Expanded sheet | Title and level with XP range; Today (steps, XP, approximate distance); neutral week (7 bars Monday–Sunday, today highlighted, total); link to History |
| Distance | Approximate from steps: `steps × 0.74 m`, shown with "≈", in kilometres in both languages; no new HealthKit permission |
| Data | `StepsRepository` interface in domain; `DemoStepsRepository` in memory now; the HealthKit → Drift repository replaces it later |
| User id | `currentUserIdProvider` returns `'local'` until registration |

## Domain

- `lib/features/steps/domain/steps_repository.dart`:
  `abstract interface class StepsRepository { Stream<List<DailySteps>> watchDays({required String userId, LocalDate? from, LocalDate? to}); }`
  (inclusive bounds, ascending by date — the same contract as
  `DailyStepsDao.watchForUser`).
- `lib/features/steps/domain/distance.dart`:
  `const averageStepLengthMeters = 0.74;`
  `int approximateDistanceMeters(int steps)` — `(steps * 0.74).round()`;
  `ArgumentError` for negative steps.
- `lib/features/steps/domain/local_date.dart` gains
  `static LocalDate fromDateTime(DateTime local)` (reads the fields as wall
  clock) and `LocalDate addDays(int days)` and `int get weekday`
  (1 = Monday … 7 = Sunday), all integer arithmetic.

## Data

- `lib/features/steps/data/demo/demo_steps_repository.dart`:
  `DemoStepsRepository implements StepsRepository` — deterministic demo
  days for the last 120 days before and including "today" given by an
  injected `Clock` (a fixed pseudo-random sequence seeded with a constant,
  steps 0–14 000), so the ring, week and level look realistic. No database
  writes. It is used only until the real repository exists; the file says
  so.

## Presentation (providers in `lib/features/today/presentation/providers/`)

- `currentUserIdProvider` → `'local'`.
- `stepsRepositoryProvider` → `DemoStepsRepository(clock)`.
- `skyProvider` (StreamProvider<SkyPalette>): emits `skyAt(clock.now())`
  immediately, then at every minute boundary (a `Timer` scheduled to the
  next whole minute, then periodic); cancelled on dispose.
- `todayProvider` (StreamProvider<TodayView>) from all days of the current
  user and the clock:

```dart
typedef WeekDay = ({LocalDate date, int steps, bool isToday});
typedef TodayView = ({
  int steps,            // today
  int xp,               // dailyXp(today)
  int distanceMeters,   // approximateDistanceMeters(today)
  LevelProgress level,  // levelProgress(totalXp(all days))
  int levelStartXp,     // xpToReachLevel(level)
  int nextLevelXp,      // xpToReachLevel(level + 1)
  List<WeekDay> week,   // Monday..Sunday of the current week, 7 entries, missing days = 0
  int weekSteps,        // sum of week
});
```

  Title and chapter strings are resolved in widgets with `levelTitle` /
  `levelChapter` and `grammaticalGenderProvider` (they need `l10n`).

## Widgets (`lib/features/today/presentation/`) and navigation

- `lib/app/router.dart`: `StatefulShellRoute.indexedStack` with branches
  `/today` (initial), `/path`, `/history`; `lib/app/app_shell.dart` puts
  `FloatingTabBar` over the branch body.
- `FloatingTabBar`: matte glass, stadium shape, three labelled items
  (icon + text), active item in the sky accent; bottom inset by the safe
  area + `AppSpacing.m`.
- `TodayScreen`: `Stack` of `SkyBackground`, `PlaceholderHills`,
  `TodayCard`, `ProgressSheet`.
  - `SkyBackground`: vertical gradient from `palette.sky` at
    `skyGradientStops`; grain overlay at `skyGrainOpacity` from a noise
    image generated once (fixed seed) and tiled.
  - `PlaceholderHills`: three hill shapes in `palette.hills`, a path
    stroke, and the user's dot in `memberColorFor(userId)`. Replaced in
    phase D.
  - `TodayCard`: matte glass (`GlassStyle`, radius `AppRadii.card`),
    `LevelRing` (custom painter: track in the text colour at 18%, arc in
    `palette.accent`, fraction `xpIntoLevel / xpForNextLevel`, round caps)
    and today's steps (`AppTypography.display`, tabular) with the caption
    "{steps} today · {weekday, date}".
  - `ProgressSheet`: `DraggableScrollableSheet` below the card, running
    under the tab bar to the bottom edge. Collapsed: 0.18 of the screen
    above the tab bar; expanded: up to `AppSpacing.s` under the card, never
    covering it. Content fades out where the tab bar starts. Glass with
    top radius `AppRadii.sheet`. Collapsed: "Level {n} ·
    {chapter}", title, progress bar, "{xp} XP to level {n + 1}". Expanded
    adds the XP range, the Today row (steps, XP, "≈ {km} km"), `WeekBars`
    with the week total, and "All history →" (goes to `/history`).
  - `WeekBars`: 7 bars, heights relative to the week's maximum (all zero →
    flat minimum bars), today in the accent, others in the text colour at
    28%; localized short weekday names.
- Glass tint and text colour follow `palette.surfaceTone`
  (`GlassStyle.lightTint` + `#18293A` text, or `darkTint` + white).
- Loading: card and sheet show their layout with neutral placeholders
  instead of numbers. Error: `failureMessage(l10n, error)` in the card.
  The sky never depends on data.

## Replacing the placeholder home

- `lib/features/home/` (the title-only `HomeScreen`) is removed; `/today`
  is the new initial route.
- `test/app/app_test.dart` (locale resolution through the app title) is
  replaced, not deleted: the same five locale cases now assert a
  localized string that the Today screen shows (`tabToday`: "Today" /
  "Сьогодні"), so locale resolution through the real app stays covered.
- The demo repository must not reach real users: no TestFlight build is
  made until the HealthKit → Drift repository replaces it.

## Text and formatting

- Numbers and dates through `intl` with the current locale
  (`NumberFormat.decimalPattern`, `DateFormat.MMMMEEEEd`), so Ukrainian
  gets a non-breaking thousands separator. Distance: one decimal, km.
- New ARB keys (en + uk): `tabToday`, `tabPath`, `tabHistory`,
  `todayStepsCaption` (plural on steps: крок / кроки / кроків · date),
  `levelLabel` ("Level {level} · {chapter}"), `xpToNextLevel` ("{xp} XP to
  level {level}"), `xpRange` ("{from} → {to} XP"), `todayHeading`,
  `stepsUnit` (plural), `xpUnit`, `distanceApprox` ("≈ {km} km"),
  `weekHeading`, `weekTotal` (plural), `historyLink`, `pathPlaceholder`,
  `historyPlaceholder`.

## Testing

- Domain: `approximateDistanceMeters` (0, 1 000 → 740, 10 000 → 7 400,
  negative → error); `LocalDate.fromDateTime`, `addDays` across month/year
  and Feb 29, `weekday` for known dates (2026-09-28 is Monday).
- Data: `DemoStepsRepository` is deterministic (same clock → same days),
  covers exactly 120 days ending today, respects `from`/`to`, steps in
  0–14 000.
- Providers (`ProviderContainer`, fixed clock, fake repository):
  `todayProvider` week is Monday–Sunday with today flagged for a Monday, a
  Wednesday and a Sunday; missing days are 0; week total; XP and level
  from all days; a day with 0 steps; `skyProvider` emits at start and
  again after the next minute boundary (fake time).
- Widgets: Today renders formatted steps, title and level in en and uk;
  the expanded sheet shows 7 bars; the tab bar switches to Path and
  History; an erroring repository shows the failure message.
- Simulator: screenshots at a day and a night time (clock overridden in a
  debug-only entry point that is not committed), and a check that three
  blurred layers scroll smoothly.

## Docs

- `docs/PRODUCT.md`: distance is approximate from steps (0.74 m) with "≈".
- `docs/ARCHITECTURE.md`: StepsRepository with the demo implementation;
  Today screen [built]. `docs/ROADMAP.md`: phase C.

## Out of scope

- Real HealthKit data, the Drift-backed repository, sync.
- Path and History content, level-up moment (phase E), animations (phase
  F), art and member dots of others (phase D, stage 5), Спільно tab.

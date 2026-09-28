# The constellation path — design

Date: 2026-09-28
Status: approved in chat (visual companion: `full-concept-v4.html`, route and data researched with sources), pending spec review

Supersedes `2026-09-28-level-up-moment-design.md` and the XP-to-levels
part of `docs/PRODUCT.md` ("XP and levels", "Level titles", "Main screen
content"). The HealthKit sync (ADR 0007, 0008) and the daily XP rule are
unchanged.

## Goal

Replace numbered levels and titles with one unit of progress: a **star**.
Steps earn XP; XP lights the stars of real constellations one by one,
along a fixed route that follows the Milky Way from Sagitta to Canis
Major. The app is a walk along «Чумацький Шлях»; its name becomes the
route. Two screens carry it: **Today** (the day's contribution) and
**Path** (the whole journey).

## Success criteria

- A person who knows the sky finds no error: real constellations, real
  neighbours, real star positions, standard figures, correct Ukrainian
  names, facts checked against a source.
- The first constellation is done in about two days of ordinary walking;
  later a star takes about three to four days; the journey lasts more than
  a year.
- Progress is always recomputable from daily steps (no counters stored).
- Nothing is ever hidden under the floating tab bar; labels are at least
  11 pt and meet WCAG AA contrast in both themes.
- All text is Flutter text through l10n (uk, en), never inside art.

## Decisions (from the conversation)

| Topic | Decision |
|---|---|
| Unit of progress | A star. No levels, no level numbers, no titles (the 25 titles and their grammatical gender are removed) |
| Registration gender | No longer needed (it only served the titles); dropped from PRODUCT |
| Star cost | Grows, then caps (B): star 1 costs 1 500 XP, each next one 1 500 more, capped at 25 000 XP from star 17 on |
| Daily XP | Unchanged: 1 XP per step up to 10 000, 1 per 2 steps beyond, at most 20 000 a day |
| Order | Fixed for everyone (A), along the Milky Way, each constellation bordering the next (IAU boundaries) |
| Main route | Стріла → Лисичка → Лебідь → Ящірка → Цефей → Кассіопея → Персей → Візничий → Телець → Близнята → Оріон → Єдиноріг → Великий Пес. Ends at Canis Major, where the Milky Way sinks towards our southern horizon (Puppis is not used: its standard figure includes Canopus and γ² Velorum, and four of its stars never rise at 50° N) |
| After the main route | A branch "to the heart of the Galaxy": back at Sagitta, Орел → Щит → Стрілець (Sagittarius is only partly visible from Ukraine; the copy says so) |
| Figures and stars | Standard IAU / Sky & Telescope stick figures; one star per figure star; star counts vary by constellation (4–25) |
| Shared stars | A star in two figures (Elnath, β Tau, in Auriga and Taurus) is lit once, in the first constellation that reaches it |
| Folk names | Kept as asterisms inside real constellations, never called constellations: Волосожар (Pleiades) and Чепіги (Hyades) in Taurus, Косарі (Orion's belt) in Orion, Хрест in Cygnus, Борона in Cassiopeia, Коза (Capella) in Auriga |
| Themes | System light and dark themes; no time-of-day sky. Dark: night sky. Light: an ink star chart on a pale background (not stars drawn on a daytime sky) |
| Today | Hybrid "C": the current constellation in the sky zone, a silhouette of hills below; the day's contribution, not a copy of Path |
| Path | One constellation per page with swipe; a route strip of neighbours; a map of the Milky Way band with fog ahead; no denominators ("Складено 5 сузір'їв", never "1 із 60") |
| Completed look | Gold lines and stars with a moving highlight plus a seal "Складено <date>" (A + C). Atlas engravings (Hevelius, Bode, public domain) come later as a figure layer (B) |
| Current marker | The elegant beacon: a small bright point, a thin slowly rotating ring, faint cross spikes, a soft pulse |
| Buttons | Matte glass, like the cards |
| New-star moment | Not a separate screen: the constellation page animates (the line draws, the star lights, a haptic); several stars light one after another (~0.6 s each); with Reduce Motion everything appears at once |
| Stories | A short, source-checked story per constellation (uk, en) |
| ETA | "≈ N днів у твоєму темпі", from the average daily XP of the last 14 days; hidden without at least 7 days of history |
| Спільно (stage 5) | Members appear as dots on the constellations (Path page and map), not on a landscape |
| Animation | Rive for the art (marker, lines, stars, highlight); text stays Flutter |

## Numbers

Star cost: `cost(n) = min(25 000, 1 500 × n)` XP for the n-th star
(1-based). At 7 000 steps a day:

| Star | Cost | Reached after |
|---|---|---|
| 1 | 1 500 | about an hour of walking |
| 3 | 4 500 | the first day |
| 4 (Стріла complete) | 6 000 | about 2 days |
| 9 | 13 500 | about 10 days |
| 17 (cap) | 25 000 | about a month |
| then | 25 000 | a star every ~3.5 days |

Main route: 140 stars (d3-celestial figures, Elnath once): about
3.3 million XP, about 16 months at 7 000 steps a day. Branch: 37 stars,
about 4 more months. Long figures (Perseus 23, Orion 23) take about
2.5 months each; their stories say so.

| # | Constellation | Stars | Milky Way |
|---|---|---|---|
| 1 | Стріла | 4 | in |
| 2 | Лисичка | 5 | in |
| 3 | Лебідь | 9 | in |
| 4 | Ящірка | 9 | in (north part) |
| 5 | Цефей | 10 | in (south part) |
| 6 | Кассіопея | 5 | in |
| 7 | Персей | 23 | in |
| 8 | Візничий | 9 | in |
| 9 | Телець | 11 (Elnath counted in Auriga) | at the edge |
| 10 | Близнята | 12 | at the edge |
| 11 | Оріон | 23 | at the edge |
| 12 | Єдиноріг | 9 | in |
| 13 | Великий Пес | 11 | in |
| Branch 1 | Орел | 8 | in |
| Branch 2 | Щит | 4 | in (Scutum Star Cloud) |
| Branch 3 | Стрілець | 25 | in (galactic centre), partly visible |

Counts come from the bundled data at build time, not from this table;
tests pin them.

## Data and licences

- **Figures and star positions:** d3-celestial by Olaf Frohn
  (BSD-3-Clause): `constellations.lines.json` (IAU / Sky & Telescope
  figures, CC BY 4.0, "some line modifications" by the author) and
  `stars.6.json` (HIP id, magnitude, RA/Dec from XHIP, Anderson & Francis
  2012). Attribution on the licences page.
- **Not bundled:** HYG and Stellarium sky cultures (CC BY-SA, share-alike
  on data is a risk for a closed-source app).
- **Build step:** a Dart tool (`tool/sky/`) reads the pinned source files
  and writes one compact asset for the 16 constellations (star HIP ids,
  projected positions, magnitudes, line pairs, route order). The asset and
  the tool are committed; the raw sources are downloaded by the tool, not
  committed. Source URLs and versions are recorded.
- **Names:** constellations from uk.wikipedia "Список сузір'їв"; star
  proper names from the IAU WGSN list with Ukrainian spellings from
  Ukrainian Wikipedia; unverified spellings (Альдерамін, Алголь, Ельнат,
  Нункі) are checked before release. Stars without a proper name use the
  Bayer designation in Ukrainian ("γ Кассіопеї").
- **Folk names:** І. Процик, «Словник власних астрономічних назв
  української мови».
- **ADR 0009** records the dataset choice, the licences, the attribution
  and the build step before any data enters the app.

## Components

### Domain (pure Dart)

- `features/path/domain/route.dart` — the route: ordered constellations
  (id, Latin and uk/en l10n keys, star list in lighting order, line pairs,
  Milky Way relation "in" / "edge"), branch after the main route; loaded
  from the bundled asset by the data layer, validated on load (every
  constellation non-empty, lighting order covers every figure star once,
  shared stars resolved).
- `features/path/domain/star_cost.dart` — `int starCost(int n)` and
  `PathProgress pathProgress(int totalXp, Route route)` →
  `(starsLit, constellationIndex, starInConstellation, xpIntoStar,
  xpForStar)`. Pure, 100% tested; replaces `level_curve.dart`.
- `features/path/domain/eta.dart` — `int? daysToNextStar(List<DailySteps>
  lastDays, int xpLeft)`: null with fewer than 7 days of history; average
  over the last 14 days.
- `features/path/domain/star_moment.dart` — replaces `level_up.dart`:
  `StarMoment? starMoment({celebratedStars, currentStars, route})` → the
  stars lit since the last celebration, in order, and the constellations
  completed on the way.
- Kept: `xp_rules.dart` (`dailyXp`, `totalXp`).
- Removed: `level_curve.dart`, `level_titles.dart`, the level-title ARB
  keys, `grammaticalGenderProvider`.

### Data

- `journey_start.celebrated_level` becomes `celebrated_stars` (schema v3
  on `feat/level-up` is not merged; the column is introduced fresh here,
  default 0).
- The route asset loader (`features/path/data/route_asset.dart`).

### Presentation

- **Today** (`features/today/`): sky zone with the current constellation
  (lit stars, marker, dashed stars ahead) and its name; hills silhouette;
  top card: steps today with a ring for the current star and a "62 %"
  label; bottom sheet: the day's contribution ("+6 870 XP сьогодні",
  "зоря заповнена на 62 %"), the week, and a link to Path. Sheet content
  ends above the tab bar.
- **Path** (`features/path/presentation/`): a `PageView` of constellation
  pages (completed, current, ahead) with a route strip of neighbours; a map
  page with the Milky Way band, completed constellations in gold, the
  current one with the same marker, the next one visible, the rest in fog.
  Headers in sentence case ("Зараз тут", "Складено").
- **Star moment**: when `starMoment` has stars, the Path page of the
  current constellation animates them; Today shows a quiet banner "Нова
  зоря в Кассіопеї" that opens it.
- **Layout rule**: every screen is zones (top, flexible, bottom) plus a
  reserved strip under the tab bar with a soft scrim; the constellation
  fits its zone with padding, labels stay inside it.
- **Themes**: `ThemeMode.system`; design tokens get a light and a dark
  set; `skyAt` and the time-of-day palettes are removed.

### Art (Rive)

A Rive contract (artboards `marker`, `star`, `line`, `highlight`; state
machine inputs `state` passed/current/ahead/done, trigger `light`) is
written in the plan; Flutter code-drawn fallbacks with the same API are
used until the `.riv` files exist. Widget tests use the fallbacks.

## Edge cases

| Case | Behaviour |
|---|---|
| A big day lights several stars across a constellation boundary | One moment: stars light in order; the finished constellation turns gold with its seal, then the next page shows the new stars |
| XP goes down (samples deleted in Health) | Stars shown follow the recomputed XP; `celebrated_stars` never goes down, so no moment repeats |
| Main route finished | The branch pages appear; the map extends to the galactic centre |
| New user, fewer than 7 days of data | No ETA line |
| Reduce Motion | No animation; states change instantly |
| Very large text | Zones scroll; nothing overlaps the tab bar |

## Testing

- Domain: `starCost` (1, 16, 17, 100), `pathProgress` at boundaries
  (0 XP, exactly a star's cost, ±1, a constellation boundary, end of the
  main route, into the branch), `daysToNextStar` (no history, 6 / 7 / 14
  days, zero average), `starMoment` (none, one, several, across a
  constellation, after XP went down).
- Route asset: every constellation borders the next (pinned list), star
  counts match the table, Elnath counted once, every name key exists in
  uk and en.
- Widgets: Today and Path in light and dark, uk and en; tab-bar clearance
  (no widget's rect intersects the tab bar except the scrim); text scale
  2.0; Reduce Motion.

## Delivery

Separate plans, one per PR:

1. ADR 0009 and the sky-data tool with the bundled asset.
2. Domain: route, star cost, ETA, star moment; removal of levels and
   titles.
3. Themes (light/dark tokens) and removal of the time-of-day sky.
4. Today redesign.
5. Path tab (pages, route strip, map).
6. Star moment and the Rive contract with fallbacks.
7. Stories (uk, en) and PRODUCT / DESIGN / ROADMAP / ARCHITECTURE.

`feat/level-up` is not merged; its tasks 1–3 (celebrated level, provider)
are reused as the pattern for `celebrated_stars` in plan 2 and 6.

## Out of scope

- Atlas engravings as a figure layer (later, "B").
- Спільно dots on constellations (stage 5).
- Seasonal "visible tonight" hints, real sky position.

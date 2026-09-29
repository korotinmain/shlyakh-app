# Product: Shlyakh (Шлях)

## Vision

A walking tracker that feels like a polished, hand-crafted App Store app
rather than a fitness dashboard. Walking earns XP, and XP lights the stars
of real constellations one by one along a fixed route through the Milky
Way: the "constellation path". There are no levels and no titles; the
unit of progress is a star, and the story is the route across the sky.

Full design: `docs/superpowers/specs/2026-09-28-constellation-path-design.md`
(decided 2026-09-28; it replaces the earlier levels, titles, time-of-day
sky and landscape).

## Users

Any number of people. Everyone walks on their own path, and anyone can
create a "Спільно" (Together): a private shared journey where they invite
people close to them (a spouse, a relative, friends). The first users are
the developer and his wife, then family; no public release is planned
yet, but nothing in the data model, auth or row-level security may assume
a fixed number of users or of members per Спільно.

## Goals

- Steps are imported from HealthKit automatically, with no manual entry and
  no Shortcuts-style automations. The journey starts when the user allows
  Health access: only steps after that moment count, so the first day is
  partial, and no earlier history is imported (decided 2026-09-28).
- Apple Watch steps are counted correctly (no double counting with iPhone).
- XP is earned from steps and lights stars of real constellations, in a
  fixed order along the route.
- The sky is astronomically accurate: real star positions, magnitudes and
  the standard constellation figures (data and licences: ADR 0009).
- Two screens carry the product: **Today** (the current constellation in
  the sky above a hills silhouette) and **Path** (constellation pages with
  swipe, the route strip and a Milky Way map).
- Light and dark themes; no live sky that follows the time of day.
- Smooth, deliberate animations; typography in a modern SaaS style.
- Full Ukrainian and English localization.
- Also serves as a learning project for mobile development from scratch.

## Non-goals (for now)

- Android version
- Manual step entry or editing
- Public social features: feeds, global leaderboards, finding strangers.
  Спільно is only private groups by invitation
- A virtual geographic route (e.g. Kyiv to another city)
- Levels, level titles, and a user gender for their grammar
- A sky that follows the real time of day or the user's location
- Showing progress as a fraction of the whole ("1 of 60"): the route is
  shown without denominators
- Workouts, calories, heart rate or other health metrics beyond steps
- Monetization, subscriptions, ads
- Standalone watchOS app (possible later as a separate SwiftUI project)

## Design principles

- Should not look like a template or AI-generated UI: no generic dashboard
  cards, no default gradients, no stock icon grids.
- The sky is the hero: art (Rive) draws the constellations; every piece of
  text is Flutter and goes through l10n, never baked into art.
- Rewards feel earned and calm: a star moment when a star lights, a gold
  figure and a dated seal when a constellation is complete. No penalties,
  no streaks, no XP ever lost.
- Fonts must have high-quality Cyrillic support.

## XP and stars

- Each local day is scored on its own: 1 XP per step up to 10 000 steps,
  1 XP per 2 steps beyond that, at most 20 000 XP a day. Rules:
  `docs/superpowers/specs/2026-09-27-xp-rules-design.md` (the level
  sections there are superseded); code:
  `lib/features/progress/domain/xp_rules.dart`.
- The n-th star on the route costs `min(25 000, 1 500 × n)` XP, so the
  first stars come within days and later ones take a steady few days each.
- Main route, 13 constellations from Sagitta to Canis Major along the
  Milky Way: Sge, Vul, Cyg, Lac, Cep, Cas, Per, Aur, Tau, Gem, Ori, Mon,
  CMa. 141 figure stars, 140 distinct (Elnath is shared by Auriga and
  Taurus and lights once), about 3.3 M XP: roughly 16 months at 7 000
  steps a day.
- After the main route a branch continues: Aql, Sct, Sgr (37 stars).
- Everyone follows the same rules; XP and progress are always recomputed
  from daily steps, never stored as a counter.

## Today screen content

Still valid from design stage A (2026-09-27):

- **No XP bonuses.** XP is only `dailyXp(steps)`.
- **No daily goal.** Today's steps are the big number; progress points to
  the next star.
- **The sky shows the current constellation** with its lit stars, the
  current star's marker and the stars ahead; the sheet shows the day's
  contribution ("+6 870 XP сьогодні") and how full the current star is,
  then the week and a link to Path.
- **Neutral week:** 7 bars with each day's steps (today highlighted) and
  the week's total. No check marks, no "active days", no weekly goal.
- **Distance is approximate:** steps × 0.74 m, shown as "≈ 8.5 km". It is
  not read from HealthKit and never affects XP.

Layout, the Path tab, stories and the ETA: the constellation path spec.

## Path tab content

- One page per constellation out of the fog: the completed ones (gold,
  "Складено 27 вересня", recomputed from the steps), the current one
  (XP to the next star, the bar, "≈ 2 дні у твоєму темпі") and the next
  one (locked). No page beyond the next; no denominators.
- A strip of neighbouring constellations under each page.
- The map: the Milky Way band on a real star chart with the visible
  constellations at their places, fog beyond.
- Stories, star names on the figures and the moving shine on completed
  constellations come later (plans 6–7).

## Open questions

- Home screen widget: in scope for v1 or later?

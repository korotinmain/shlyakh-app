# Product: Shlyakh (Шлях)

## Vision

A walking tracker that feels like a polished, hand-crafted App Store app
rather than a fitness dashboard. Walking is rewarded with XP and named
levels, and progress is shown as a calm illustrated landscape where each
person is a dot on the path.

## Users

Two people: the developer and his wife. No public release planned for now,
but the architecture should not block adding more users later
(multi-user data model, auth, row-level security).

## Goals

- Steps are imported from HealthKit automatically, with no manual entry and
  no Shortcuts-style automations.
- Apple Watch steps are counted correctly (no double counting with iPhone).
- XP is earned from steps and raises levels; every level has a name.
- Main screen follows the "postcard" concept: illustrated landscape,
  progress ring, bottom sheet with details.
- Each user can see where the other one is on the landscape, ideally in
  real time.
- Day/night gradient landscape that reflects the time of day.
- Smooth, deliberate animations; typography in a modern SaaS style.
- Full Ukrainian and English localization.
- Also serves as a learning project for mobile development from scratch.

## Non-goals (for now)

- Android version
- Manual step entry or editing
- Social features beyond the two users (friends, feeds, leaderboards, sharing)
- A virtual geographic route (e.g. Kyiv to another city). Dropped in favor
  of an abstract landscape
- Workouts, calories, heart rate or other health metrics beyond steps
- Monetization, subscriptions, ads
- Standalone watchOS app (possible later as a separate SwiftUI project)

## Design principles

- Should not look like a template or AI-generated UI: no generic dashboard
  cards, no default gradients, no stock icon grids.
- Illustration first: the landscape is the hero of the main screen.
- Calm over gamified noise: rewards feel pleasant, not pushy.
- Fonts must have high-quality Cyrillic support.

## XP and levels

- Each local day is scored on its own: 1 XP per step up to 10 000 steps,
  1 XP per 2 steps beyond that, at most 20 000 XP a day (a long hike is
  rewarded but cannot race through the later path; sensor glitches cannot
  break the pace). Early on one big day can bring several levels at once
  (a capped first day reaches level 4), so level-ups must handle more than
  one level at a time.
- The main path has 25 levels and ends at 1 000 000 XP, "a million steps".
  At a typical pace it takes about a year: the first levels arrive within
  days, the last ones about once a month (about every six weeks at a
  slower 1 800 steps a day).
- After the main path the journey continues ("a new trail"): every further
  level takes the same 81 600 XP. A separate landscape for it is not
  planned yet.
- No penalties, no streaks, no XP ever lost; a day without steps simply
  earns nothing. Both users follow the same rules.
- Exact rules and tables: `docs/superpowers/specs/2026-09-27-xp-rules-design.md`;
  code: `lib/features/progress/domain/`.

## Open questions

- Level names (theme and list)
- What exactly the dot's position on the landscape represents
  (daily progress, level progress, or total distance)
- Home screen widget: in scope for v1 or later?

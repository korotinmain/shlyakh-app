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

## Open questions

- XP formula and level curve
- Level names (theme and list)
- What exactly the dot's position on the landscape represents
  (daily progress, level progress, or total distance)
- Home screen widget: in scope for v1 or later?

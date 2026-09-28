# Roadmap

Current stage: **3 — Constellation path**

Stages are ordered by risk: the riskiest technical part (HealthKit) is
validated first, visual polish comes last. No deadlines.

## 0. Foundation
- [x] `flutter create` with bundle id and iOS-only target
- [x] Strict lints (very_good_analysis)
- [x] Folder structure per CLAUDE.md
- [x] Core dependencies added (Riverpod, go_router, freezed)
- [x] Git repo, first commit
- [ ] Apple Developer account

## 1. HealthKit spike (throwaway code allowed)
- [x] Request HealthKit permissions
- [x] Read daily step counts on a real iPhone
- [x] Verify Apple Watch steps are included without double counting
- [x] Prototype background delivery (HKObserverQuery in Swift via Pigeon)
- [x] Write findings to `docs/decisions/`

## 2. Domain
- [x] Decide XP formula (update PRODUCT.md)
- [x] Pure Dart XP logic with unit tests
- [x] Drift schema for daily steps
- [x] Repository: HealthKit to Drift sync

## 3. Constellation path

Spec: `docs/superpowers/specs/2026-09-28-constellation-path-design.md`.
It replaces the earlier levels, titles, time-of-day sky and landscape
(the old level-up work is kept as the `archive/level-up` tag).

- [x] Today screen skeleton wired to real data (glass card, week, sheet)
- [x] 1. ADR 0009 and the bundled sky data (`assets/sky/route.json`)
- [x] 2. Domain: route, star cost, path progress, ETA, star moment;
      remove levels and titles
- [ ] 3. Light and dark themes; remove the time-of-day sky
- [ ] 4. Today: the current constellation above a hills silhouette
- [ ] 5. Path: constellation pages with swipe, route strip, Milky Way map
- [ ] 6. Star moment and the Rive contract (art has no text)
- [ ] 7. Stories and docs

## 4. Motion and polish
- [ ] Micro-animations (flutter_animate) and haptics
- [ ] Constellation engravings (atlas style, later)
- [ ] Star notifications
- [ ] Ukrainian + English localization complete
- [ ] Home screen widget (if in scope)

## 5. Backend
- [ ] Supabase project, schema, RLS policies
- [ ] Auth and registration
- [ ] Спільно: private groups by invitation (any number of members)
- [ ] Sync daily steps to Supabase
- [ ] Realtime: Спільно members on the path
- [x] Create `docs/ARCHITECTURE.md` (created early, before stage 2)

## 6. Release to our phones
- [ ] TestFlight build
- [ ] Installed on our family's phones

## Later
- Watch complication (SwiftUI)

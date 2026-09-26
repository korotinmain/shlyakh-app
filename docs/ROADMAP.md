# Roadmap

Current stage: **0 — Foundation**

Stages are ordered by risk: the riskiest technical part (HealthKit) is
validated first, visual polish comes last. No deadlines.

## 0. Foundation
- [ ] `flutter create` with bundle id and iOS-only target
- [ ] Strict lints (very_good_analysis)
- [ ] Folder structure per CLAUDE.md
- [ ] Core dependencies added (Riverpod, go_router, freezed)
- [ ] Git repo, first commit
- [ ] Apple Developer account

## 1. HealthKit spike (throwaway code allowed)
- [ ] Request HealthKit permissions
- [ ] Read daily step counts on a real iPhone
- [ ] Verify Apple Watch steps are included without double counting
- [ ] Prototype background delivery (HKObserverQuery in Swift via Pigeon)
- [ ] Write findings to `docs/decisions/`

## 2. Domain
- [ ] Decide XP formula and level curve (update PRODUCT.md)
- [ ] Choose level names
- [ ] Pure Dart XP/level logic with unit tests
- [ ] Drift schema for daily steps
- [ ] Repository: HealthKit to Drift sync

## 3. Design (Claude Design)
- [ ] Main screen "postcard" concept
- [ ] Level-up moment
- [ ] History / details in bottom sheet
- [ ] Extract design tokens, create `docs/DESIGN.md`

## 4. Main screen
- [ ] Theme and tokens in code
- [ ] Static landscape
- [ ] Progress ring (CustomPainter)
- [ ] Bottom sheet with today's stats and level
- [ ] Wired to real data

## 5. Backend
- [ ] Supabase project, schema, RLS policies
- [ ] Auth for two users
- [ ] Sync daily steps to Supabase
- [ ] Realtime: partner's dot on the landscape
- [ ] Create `docs/ARCHITECTURE.md`

## 6. Polish
- [ ] Rive landscape with day/night transition
- [ ] Micro-animations (flutter_animate)
- [ ] Level-up notifications
- [ ] Ukrainian + English localization complete
- [ ] Home screen widget (if in scope)

## 7. Release to two phones
- [ ] TestFlight build
- [ ] Installed on both phones

## Later
- Watch complication (SwiftUI)

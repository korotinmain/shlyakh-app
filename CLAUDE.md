# Shlyakh (Шлях)

Personal walking tracker for iOS built with Flutter. Steps from HealthKit
(including Apple Watch data) turn into XP, XP raises named levels, and the
main screen is an illustrated landscape ("postcard") where each user is a dot.
Built for two users; architected like a small SaaS product.

Before starting work, read `docs/ROADMAP.md` to see the current stage.
For product scope and non-goals, see `docs/PRODUCT.md`.

**Hard rules for agents are in `docs/AGENT_RULES.md`. Read them before
making any change. They override convenience.**

## Stack

- Flutter (iOS first), Dart with sound null safety
- State / DI: Riverpod (code generation via `riverpod_generator`)
- Navigation: go_router
- Models: freezed + json_serializable
- Local storage: Drift (SQLite)
- Health data: `health` package; background delivery via native Swift
  (`HKObserverQuery`) exposed through Pigeon
- Backend: Supabase (auth, Postgres with RLS, Realtime)
- Animation: Rive (landscape), CustomPainter (progress ring), flutter_animate
- i18n: gen-l10n with ARB files (uk, en)
- Tests: flutter_test + mocktail

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
flutter run
```

Run `flutter analyze` and `flutter test` before considering a task done.

## Project structure

```
lib/
├── app/            # app bootstrap, router, theme
├── core/           # shared utilities, design tokens, extensions
├── features/
│   └── <feature>/
│       ├── data/          # repositories impl, data sources (HealthKit, Drift, Supabase)
│       ├── domain/        # entities, pure business logic, repository interfaces
│       └── presentation/  # widgets, screens, Riverpod providers
└── l10n/           # ARB files
ios/Runner/         # native Swift (HealthKit background delivery)
docs/               # product, roadmap, architecture, decisions
```

## Rules

- Domain layer is pure Dart: no Flutter, no packages with platform code.
- No business logic in widgets. Widgets read providers and render.
- All XP and level logic lives in the domain layer and is covered by tests.
- XP is a deterministic function of daily step counts. Never store XP as an
  incrementing counter; it must be recomputable from raw data.
- Every user-facing string goes through l10n. No hardcoded text in widgets.
- Colors, typography, spacing and radii come from design tokens in
  `lib/core/`. No magic values in widgets.
- Do not add dependencies without asking first.
- Do not implement anything listed in the non-goals of `docs/PRODUCT.md`.
- Significant technical decisions get a short ADR in `docs/decisions/`.

## Communication

The developer is a senior Angular engineer learning Flutter and mobile
development through this project. Explain Flutter/iOS-specific concepts
briefly when they first appear, especially where they differ from Angular.
Point out trade-offs and disagree when a request seems like a bad idea.

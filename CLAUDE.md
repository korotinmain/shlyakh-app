# Shlyakh (Шлях)

Personal walking tracker for iOS built with Flutter. Steps from HealthKit
(including Apple Watch data) turn into XP, and XP lights the stars of real
constellations along a fixed route through the Milky Way (the "constellation
path"). There are no levels or titles; progress is the current star.
Users can walk together in private groups ("Спільно"); no fixed number of
users or members. Architected like a small SaaS product.

Before starting work, read `docs/ROADMAP.md` to see the current stage.
For product scope and non-goals, see `docs/PRODUCT.md`.
For layers, data flow and what is built vs planned, see
`docs/ARCHITECTURE.md`; update it in the same PR when the architecture
changes.

**Hard rules for agents are in `docs/AGENT_RULES.md`. Read them before
making any change. They override convenience.**

## Stack

- Flutter (iOS first), Dart with sound null safety
- State / DI: Riverpod (code generation via `riverpod_generator`)
- Navigation: go_router
- Models: freezed + json_serializable
- Local storage: Drift (SQLite)
- Health data: native Swift (HealthKit) exposed to Dart through Pigeon
  (`pigeons/steps_api.dart`); no `health` plugin
- Backend: Supabase (auth, Postgres with RLS, Realtime)
- Animation: Rive (constellation art; all text stays in Flutter), CustomPainter,
  flutter_animate
- i18n: gen-l10n with ARB files (uk, en)
- Tests: flutter_test + mocktail

## Library versions

Dependencies are newer than most model training data: Riverpod 3,
go_router 18, freezed 3, pigeon 29, Dart 3.13 (e.g. the
`new(...)` constructor syntax that `very_good_analysis` enforces). Do not
write API calls from memory. Check the exact version in `pubspec.lock`,
then read the signatures in the package source (`~/.pub-cache/hosted/pub.dev/`
or the Dart MCP `read_package_uris` tool) or its CHANGELOG before using an
API. If an API looks different from what you expect, trust the source.

## Commands

```bash
flutter pub get
dart run pigeon --input pigeons/steps_api.dart   # first; then dart format its .g.dart output
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev make-migrations   # after a schema change + schemaVersion bump; commit its output
dart run tool/sky/build_route.dart   # after changing the pinned sky data (ADR 0009); commit assets/sky
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
TZ=Europe/Kyiv flutter test
TZ=Europe/Kyiv flutter test --coverage
dart run tool/coverage/check_coverage.dart
flutter run
```

Run `dart analyze --fatal-infos` and `flutter test` before considering a
task done. `dart analyze` includes the `riverpod_lint` analyzer plugin
(`flutter analyze` silently skips plugin lints), and `--fatal-infos` makes
its info-level lints fail the exit code. `flutter pub get` regenerates l10n
files; `flutter test` does not.
Tests run with `TZ=Europe/Kyiv` so local-time tests (DST, local
midnight) mean the same on every machine; `test/time_zone_test.dart`
fails otherwise.
Testing rules and coverage thresholds: `docs/AGENT_RULES.md`, section 8.
CI (`.github/workflows/ci.yml`) runs format check, analyze, tests and the
coverage thresholds check on every PR to `main`; merging requires it to
pass.

## Dart MCP server

`.mcp.json` registers the Dart SDK's MCP server (`dart mcp-server`):
analyzer, LSP, pub.dev search, package source reading and, for a running
app, hot reload, runtime errors and the widget inspector. To connect it to
a running app, start the app with `flutter run --print-dtd` and pass the
printed DTD URI to the `dtd` tool. Read-only tools are pre-allowed in
`.claude/settings.json`; `pub` stays behind a prompt because adding
dependencies requires asking first.

## Claude Code hooks

`.claude/settings.json` runs these hooks (scripts in `.claude/hooks/`):

- Edit/Write on a generated file (`*.g.dart`, `*.freezed.dart`,
  `*.g.swift`, l10n output) is blocked: edit the source and regenerate.
- After an edit, the Dart file is formatted with `dart format`.
- After an edit, `DateTime.now()` in `lib/` (outside `clockProvider`) is
  reported (ADR 0002).
- Before finishing a turn with changed Dart files, `dart analyze
  --fatal-infos` and `flutter test` run; a failure keeps the turn going.

## Project structure

```
lib/
├── app/            # app bootstrap, router, theme
├── core/           # shared utilities, design tokens, extensions
├── features/
│   └── <feature>/
│       ├── data/          # repositories impl, data sources (HealthKit, Drift, Supabase)
│       ├── domain/        # entities, pure business logic, repository interfaces
│       └── presentation/  # widgets, screens
│           └── providers/ # Riverpod providers and notifiers (coverage-measured)
└── l10n/           # ARB files
ios/Runner/         # native Swift (HealthKit background delivery)
docs/               # product, roadmap, architecture, decisions
```

## Rules

- Domain layer is pure Dart: no Flutter, no packages with platform code.
- No business logic in widgets. Widgets read providers and render.
- All XP and star progress logic lives in the domain layer and is covered by tests.
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

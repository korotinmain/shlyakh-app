# Shlyakh (Шлях)

A personal walking tracker for iOS, built with Flutter. Daily steps from
HealthKit, Apple Watch included, turn into XP, and XP lights the stars of
real constellations along a fixed route through the Milky Way.

- Product scope and non-goals: [docs/PRODUCT.md](docs/PRODUCT.md)
- Current stage: [docs/ROADMAP.md](docs/ROADMAP.md)
- Layers and data flow: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Visual design: [docs/DESIGN.md](docs/DESIGN.md)
- Decisions: [docs/decisions/](docs/decisions/)
- Commands, stack and rules: [CLAUDE.md](CLAUDE.md) and
  [docs/AGENT_RULES.md](docs/AGENT_RULES.md)

## Getting started

```bash
flutter pub get
dart run pigeon --input pigeons/steps_api.dart
dart run build_runner build --delete-conflicting-outputs
TZ=Europe/Kyiv flutter test
flutter run
```

Steps come from HealthKit, so run on a real iPhone.
[ADR 0007](docs/decisions/0007-healthkit-steps-and-background-delivery.md)
covers what a Personal Team can sign.

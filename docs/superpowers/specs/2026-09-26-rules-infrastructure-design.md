# PR 1: Rules infrastructure — design

Date: 2026-09-26
Status: approved in chat, pending spec review

## Goal

Make every piece of code written after this PR follow the project rules by
default: user-facing text goes through l10n, time comes from an injected
clock, Riverpod usage is linted, and the generated-files policy is decided.
No product functionality is added.

## Success criteria

- `flutter analyze` reports no issues (including `riverpod_lint`).
- `flutter test` passes; the template counter test is replaced, not deleted.
- The app launches on the iPhone and shows the localized app title: Ukrainian
  on a Ukrainian system, English on an English system, English otherwise.
- The four ADRs below exist and `docs/AGENT_RULES.md` section 9 points to
  ADR 0001 instead of "TBD".

## Out of scope

- Design tokens (stage 3 of the roadmap). The theme is a minimal Material 3
  `ThemeData`.
- The ADR with HealthKit spike findings (waits for the background delivery
  test; separate PR).
- In-app language switcher (iOS offers per-app language in Settings).
- CI, coverage script, hooks (PR 2).

## Decisions

| Topic | Decision | ADR |
|---|---|---|
| Generated files (`*.g.dart`, `*.freezed.dart`, l10n output) | Not committed; generated locally and on CI | 0001 |
| Current time | Explicit `Clock` injection (`clock` package type): constructor in domain, `clockProvider` in presentation | 0002 |
| App root | `MaterialApp.router` with a custom theme | 0003 |
| Localization | English template ARB; supported `en`, `uk`; unsupported system locales fall back to English | 0004 |

## Structure

```
lib/
├── main.dart                          # runApp(ProviderScope(child: App()))
├── app/
│   ├── app.dart                       # App: MaterialApp.router, theme, l10n delegates
│   ├── router.dart                    # routerProvider -> GoRouter, single route '/'
│   └── theme.dart                     # minimal Material 3 ThemeData, no tokens
├── core/
│   ├── l10n/l10n_extension.dart       # BuildContext.l10n
│   └── time/clock_provider.dart       # clockProvider -> const Clock()
├── features/
│   └── home/presentation/home_screen.dart   # placeholder: localized title only
└── l10n/
    ├── app_en.arb                     # template
    └── app_uk.arb
l10n.yaml
test/
├── app/app_test.dart                  # replaces test/widget_test.dart
└── helpers/pump_app.dart              # ProviderScope + overrides + locale
docs/decisions/0001..0004-*.md
```

The `.gitkeep` files in folders that get real content are removed.

### Bootstrap

- `main.dart` only wraps `App` in `ProviderScope`. No logic.
- `App` is a `ConsumerWidget` that reads `routerProvider` and builds
  `MaterialApp.router` with `AppLocalizations.localizationsDelegates`,
  `AppLocalizations.supportedLocales` and the theme from `theme.dart`.
- `routerProvider` is a Riverpod provider (code-generated) returning a
  `GoRouter` with one route `/` -> `HomeScreen`. A provider instead of a
  global so the router can depend on other providers later (auth, stage 5)
  and can be overridden in tests.
- `HomeScreen` renders `context.l10n.appTitle`. No providers, no data.

### Localization

- `l10n.yaml`: `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`,
  `output-localization-file: app_localizations.dart`,
  `nullable-getter: false`. `pubspec.yaml`: `flutter: generate: true`.
- Keys in this PR: `appTitle` ("Shlyakh" / "Шлях").
- Fallback to English is achieved by listing `en` first in supported locales
  (Flutter falls back to the first supported locale).
- `.gitignore`: `lib/l10n/app_localizations*.dart`.
- `ios/Runner/Info.plist`: `CFBundleLocalizations` = `en`, `uk`, so iOS
  exposes the per-app language setting.

### Time

- Domain code receives `Clock` via constructor. Presentation reads
  `clockProvider`. Tests override it with `Clock.fixed(...)`.
- Direct `DateTime.now()` is not used in `lib/` outside `clockProvider`.
  (Enforcing this with a lint is a PR 2 candidate.)

### Lints

- Add `riverpod_lint`. The integration method for Riverpod 3 (analyzer
  plugin via `plugins:` in `analysis_options.yaml` vs `custom_lint`) is
  verified against the package source while writing the implementation plan.

## Dependencies

Approved by the developer:

- dependencies: `flutter_localizations` (SDK), `intl` (version pinned by
  `flutter_localizations`), `clock`
- dev_dependencies: `mocktail`, `riverpod_lint`

## Testing

- `test/app/app_test.dart`:
  - renders "Shlyakh" when the locale is `en`;
  - renders "Шлях" when the locale is `uk`.
  Together they cover bootstrap -> router -> l10n.
- `test/helpers/pump_app.dart`: wraps a widget in `ProviderScope(overrides:)`
  with a given locale; used by all future widget tests.
- Not tested (per AGENT_RULES 8.3): `clockProvider`, `theme.dart`, the
  `l10n` extension — no logic.
- `mocktail` is added but not used yet.

## Cleanup

- Remove the untracked leftover `lib/spike/health_spike_api.g.dart` on main.

## Risks

- Riverpod 3 / riverpod_lint integration may differ from memory: verify in
  the package source before planning (CLAUDE.md, "Library versions").
- gen-l10n output location changed across Flutter versions (synthetic
  package removed): verify generated file paths so `.gitignore` and imports
  match.

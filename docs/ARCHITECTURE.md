# Architecture

How Shlyakh is put together: what exists today, what is decided but not
built yet, and what is still open. Rules for agents are in
`docs/AGENT_RULES.md`; decisions with their trade-offs are in
`docs/decisions/`. When this document and the code disagree, the code is
right and this document needs an update in the same PR.

Status markers: **[built]** exists in `main`, **[decided]** agreed but not
implemented, **[open]** not decided yet.

## 1. Layers

```
lib/
├── main.dart             ProviderScope(child: App())
├── app/                  bootstrap: App, routerProvider, theme
├── core/                 shared utilities (l10n extension, clockProvider)
├── features/<feature>/
│   ├── domain/           pure Dart: entities, rules (XP, levels), repository interfaces
│   ├── data/             repository implementations, data sources
│   └── presentation/
│       ├── providers/    Riverpod providers and notifiers (state, derived values)
│       └── …             widgets and screens (render only)
└── l10n/                 ARB files (en template, uk)
ios/Runner/               native Swift (HealthKit background delivery)
tool/                     developer tooling (coverage check)
```

Dependency rule:

```
presentation ──► domain ◄── data
      │                       │
      └──► core ◄─────────────┘
```

- `domain` depends on nothing but Dart and `package:clock`'s `Clock` type
  (no Flutter, no platform packages). It defines repository interfaces;
  `data` implements them.
- `presentation` reads domain logic through providers. Widgets contain no
  business logic.
- `app` wires everything together and is the only place that knows every
  feature.

## 2. Current state [built]

```
main.dart ── ProviderScope
               └── App (MaterialApp.router, theme, l10n delegates)
                     └── routerProvider (go_router, route '/')
                           └── HomeScreen (placeholder: localized title)
```

- Navigation: `routerProvider` (keepAlive) returns a `GoRouter`, so the
  router can later depend on auth state and be overridden in tests.
- Time: `clockProvider` is the only source of "now" (ADR 0002).
- Domain: `features/progress/domain/` holds the XP rules (`dailyXp`,
  `totalXp`) and the level curve (`xpToReachLevel`, `levelProgress`), pure
  functions with 100% test coverage. Nothing reads real steps yet.
- Level titles: `features/progress/domain/level_titles.dart` (chapters,
  continuation degree, `GrammaticalGender`) and
  `presentation/providers/level_title.dart` (maps a level to its ARB string;
  `grammaticalGenderProvider`).
- Localization: gen-l10n, `en` template and fallback, `uk` translation,
  `CFBundleLocalizations` for the iOS per-app language (ADR 0004).
- Native: `AppDelegate` is the Flutter template; no native code in `main`
  yet. The HealthKit probe lives only on the throwaway `spike/healthkit`
  branch.

## 3. Target data flow [decided]

```mermaid
flowchart LR
  HK[HealthKit] -->|daily totals<br/>statistics query| SR[data: StepsRepository]
  OBS[Swift HKObserverQuery<br/>via Pigeon] -->|"steps changed"| SR
  SR -->|upsert user_id + local_date| DB[(Drift / SQLite<br/>local source of truth)]
  DB --> XP[domain: XP and levels<br/>pure functions of daily steps<br/>built]
  DB --> SYNC[data: sync]
  SYNC <-->|upsert, RLS| SB[(Supabase Postgres)]
  SB -->|Realtime| PARTNER[partner's position]
  XP --> P[presentation/providers]
  PARTNER --> P
  P --> UI[widgets: postcard, ring, bottom sheet]
```

Invariants the flow must keep (details in `docs/AGENT_RULES.md`):

- **Steps come from HealthKit only** and are never edited in the app (6).
- **A day is the user's local calendar day**, stored as
  `(user_id, local_date, timezone)` (4).
- **XP is recomputed from daily steps**, never stored as a counter
  (CLAUDE.md, Rules).
- **Drift is the source of truth; the app works offline.** Supabase is a
  sync target (6).
- **Sync is idempotent**: upsert on `(user_id, local_date)` (6).
- **Health data is never logged** (5).

## 4. HealthKit integration

Findings of the stage 1 spike (full ADR follows when the spike ends):

- **[decided]** Daily totals come from a statistics query
  (`health` plugin `getTotalStepsInInterval`, i.e. `HKStatisticsQuery`
  with cumulative sum). HealthKit deduplicates iPhone and Apple Watch by
  source priority; the result matches the Health app exactly, including
  truncated fractional steps. Summing raw samples double counts and is
  not allowed. The app does no deduplication of its own.
- **[decided]** Background delivery needs native Swift: `HKObserverQuery`
  registered in `didFinishLaunching`, `enableBackgroundDelivery`, exposed to
  Dart through Pigeon. The `health` plugin has no API for it.
- **[decided]** Entitlements: `com.apple.developer.healthkit` and
  `…healthkit.background-delivery`. Not `…healthkit.access` (health
  records), which a Personal Team cannot sign.
- **[open]** How often and when iOS wakes the app in the background. This
  decides whether data refreshes mainly in the background or on app open,
  and therefore how the sync is scheduled.

## 5. Cross-cutting concerns

| Concern | Approach | Status |
|---|---|---|
| Dependency injection | Riverpod (`riverpod_generator`); `ProviderScope` at the root, overrides in tests | [built] |
| Time | `Clock` injected (constructor in domain, `clockProvider` in UI) | [built] |
| Localization | gen-l10n, every user-facing string in ARB | [built] |
| Navigation | go_router behind `routerProvider` | [built] |
| Models | freezed + json_serializable | [decided] |
| Local storage | Drift | [decided] |
| Backend | Supabase: auth, Postgres with RLS on every table, Realtime | [decided] |
| Design tokens | `lib/core/`, extracted from the design (stage 3) | [decided] |
| Error handling | how data-layer errors become domain failures and UI states | [open] |
| Logging | what may be logged without health data or ids | [open] |

## 6. Quality gates [built]

CI (`.github/workflows/ci.yml`) on every PR to `main`; merging requires it
to pass (branch protection, admins included):

1. `dart format --output=none --set-exit-if-changed .`
2. `dart analyze --fatal-infos` (includes `riverpod_lint`; `flutter analyze`
   would skip it)
3. `flutter test --coverage`
4. `dart run tool/coverage/check_coverage.dart`: domain 100%, data and
   `presentation/providers/` ≥ 85%, overall ≥ 85%; a measured file with
   code that no test loads fails the check

Generated files are not committed and are regenerated by
`flutter pub get` (l10n) and build_runner (ADR 0001).

## 7. Decisions

| ADR | Decision |
|---|---|
| [0001](decisions/0001-generated-files-not-committed.md) | Generated files are not committed (Pigeon Swift output is) |
| [0002](decisions/0002-explicit-clock-injection.md) | Explicit clock injection |
| [0003](decisions/0003-material-app-base.md) | `MaterialApp.router` as the app root |
| [0004](decisions/0004-localization-en-template-fallback.md) | English template and fallback |

## 8. Open questions

- Background wake-up frequency (section 4) and the resulting sync
  schedule.
- Where the grammatical gender is stored before registration exists
  (`grammaticalGenderProvider` defaults to masculine for now).
- What the dot's position on the landscape represents (`docs/PRODUCT.md`).
- Error handling and logging policy (section 5).
- The main app and the spike share the bundle id
  `com.denyskorotin.shlyakh`: while the spike build is on the iPhone, the
  main app is tested on the simulator only.

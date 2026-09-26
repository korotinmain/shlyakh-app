# Rules Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Flutter template with a localized, Riverpod-based app bootstrap, add an injectable clock and riverpod_lint, and record the decisions as ADRs.

**Architecture:** `main.dart` wraps `App` in `ProviderScope`; `App` builds `MaterialApp.router` from `routerProvider` with gen-l10n delegates. Time is read only through `clockProvider` / constructor-injected `Clock`. Lints run through the analyzer plugin.

**Tech Stack:** Flutter 3.47 / Dart 3.13, flutter_riverpod 3.4 + riverpod_generator 4.0, go_router 18, gen-l10n, clock 1.1, mocktail 1.0, riverpod_lint 3.1.9.

**Spec:** `docs/superpowers/specs/2026-09-26-rules-infrastructure-design.md`

## Global Constraints

- Branch: `chore/rules-infrastructure`. Conventional Commits; end each commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Constructors use the Dart 3.13 `new(...)` syntax (enforced by `very_good_analysis`, see `lib/main.dart` in git history).
- Supported locales in this order: `en`, `uk`. English is the template and the fallback.
- Copy: `appTitle` = `Shlyakh` (en), `Шлях` (uk).
- Generated files are never committed: `*.g.dart`, `*.freezed.dart`, `lib/l10n/app_localizations*.dart`.
- No `DateTime.now()` in `lib/` outside `lib/core/time/clock_provider.dart`.
- Theme: minimal Material 3 `ThemeData`, no design tokens, no hardcoded colors beyond a single `ColorScheme.fromSeed` seed.
- **Do not install on the physical iPhone.** It runs the HealthKit spike release build for the background delivery test; the same bundle id would replace it. Launch checks use the iOS simulator (e.g. `iPhone 16 Pro`).
- Before using any package API, check its signature in `~/.pub-cache/hosted/pub.dev/` or via Dart MCP `read_package_uris` (CLAUDE.md, "Library versions").

## Review Focus

- System locale not supported (e.g. `pl`) → English title. Test in Task 1.
- Regional variant of a supported language (`uk_UA`) → Ukrainian title. Test in Task 1.
- Preferred-languages list where the first is unsupported and the second is supported (`[pl, uk]`) → Ukrainian, as iOS users expect their second language to win over the fallback. Test in Task 1.
- Fresh clone without generated files: `flutter test` / `flutter run` must regenerate l10n automatically (`generate: true`). Verified in Task 1 Step 7 by deleting generated l10n files before running tests.
- A lint plugin that silently does not load looks identical to a clean codebase. Verified in Task 3 by a temporary violation that must be reported.

---

### Task 1: Localized app bootstrap

**Files:**
- Modify: `pubspec.yaml` (add `flutter_localizations: sdk: flutter`, `intl: ^0.20.3` to dependencies; `flutter: generate: true`)
- Create: `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_uk.arb`
- Create: `lib/core/l10n/l10n_extension.dart`
- Create: `lib/app/app.dart`, `lib/app/router.dart`, `lib/app/theme.dart`
- Create: `lib/features/home/presentation/home_screen.dart`
- Modify: `lib/main.dart` (replace the template entirely)
- Modify: `.gitignore` (add `lib/l10n/app_localizations*.dart`)
- Modify: `ios/Runner/Info.plist` (add `CFBundleLocalizations` array: `en`, `uk`)
- Delete: `test/widget_test.dart`, `lib/app/.gitkeep`, `lib/core/.gitkeep`, `lib/features/.gitkeep`, `lib/l10n/.gitkeep`, untracked `lib/spike/` leftover
- Create: `test/helpers/pump_app.dart`, `test/app/app_test.dart`
- Create: `docs/decisions/0001-generated-files-not-committed.md`, `docs/decisions/0003-material-app-base.md`, `docs/decisions/0004-localization-en-template-fallback.md`
- Modify: `docs/AGENT_RULES.md` section 9 (replace "see decision in `docs/decisions/` (TBD; until decided, do not commit them)" with a link to ADR 0001)

**Interfaces:**
- Produces:
  - `class App extends ConsumerWidget` in `lib/app/app.dart` (`const new({super.key})`)
  - `@Riverpod(keepAlive: true) GoRouter router(Ref ref)` → generated `routerProvider`
  - `ThemeData buildAppTheme()` in `lib/app/theme.dart`
  - `extension L10nX on BuildContext { AppLocalizations get l10n; }`
  - `class HomeScreen extends StatelessWidget`
  - `Future<void> pumpApp(WidgetTester tester, {List<Locale> systemLocales = const [Locale('en')], List<Override> overrides = const []})` in `test/helpers/pump_app.dart`. It sets `tester.platformDispatcher.localesTestValue = systemLocales`, registers `addTearDown(tester.platformDispatcher.clearLocalesTestValue)`, pumps `ProviderScope(overrides: overrides, child: const App())` and calls `pumpAndSettle()`. It must NOT pass `locale:` to `MaterialApp`: the tests exercise real locale resolution. Check which library exports `Override` in flutter_riverpod 3.4.

- [ ] **Step 1: Write the failing tests** in `test/app/app_test.dart`, `group('App locale resolution', ...)`:

```dart
final cases = <(String, List<Locale>, String)>[
  ('shows English title for en', [Locale('en')], 'Shlyakh'),
  ('shows Ukrainian title for uk', [Locale('uk')], 'Шлях'),
  ('shows Ukrainian title for regional uk_UA', [Locale('uk', 'UA')], 'Шлях'),
  ('falls back to English for unsupported pl', [Locale('pl')], 'Shlyakh'),
  ('prefers a supported second language over the fallback',
      [Locale('pl'), Locale('uk')], 'Шлях'),
];
for (final (name, locales, title) in cases) {
  testWidgets(name, (tester) async {
    await pumpApp(tester, systemLocales: locales);
    expect(find.text(title), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/app/app_test.dart`
Expected: FAIL — compilation errors (`App`, `pumpApp` not defined).

- [ ] **Step 3: Add l10n config and ARB files**

`l10n.yaml`: `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `nullable-getter: false`. `app_en.arb` has `@@locale: en`, `appTitle` with an `@appTitle` description ("App name shown on the home screen"); `app_uk.arb` has `@@locale: uk`, `appTitle`. Run `flutter pub get && flutter gen-l10n` and confirm `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_uk.dart` exist and `git status` does not list them.

- [ ] **Step 4: Implement the bootstrap**

`App.build` returns `MaterialApp.router(onGenerateTitle: (c) => c.l10n.appTitle, theme: buildAppTheme(), routerConfig: ref.watch(routerProvider), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales)`. Confirm the generated `supportedLocales` lists `en` first; if not, pass `const [Locale('en'), Locale('uk')]`. `routerProvider` returns `GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())])`. `HomeScreen` renders a `Scaffold` whose body centers `Text(context.l10n.appTitle)`. `buildAppTheme()` returns `ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: ...))` with one seed constant. `main.dart`: `void main() => runApp(const ProviderScope(child: App()));`. Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/app/app_test.dart`
Expected: 5 tests PASS.

- [ ] **Step 6: Replace the template and clean up**

Delete `test/widget_test.dart`, the four `.gitkeep` files and the untracked `lib/spike/` leftover. Add the `.gitignore` line and `CFBundleLocalizations` (`plutil -lint ios/Runner/Info.plist` → OK). Write ADRs 0001, 0003, 0004 (Context / Decision / Consequences, under 30 lines each, content from the spec's Decisions table and the chat trade-offs: 0001 clean diffs vs regenerate after clone; 0003 custom design overrides Material look, packages expect Material ancestors; 0004 English template matches the fallback so gen-l10n reports no untranslated template keys). Update `AGENT_RULES.md` section 9.

- [ ] **Step 7: Verify from a clean state**

Run: `rm lib/l10n/app_localizations*.dart && flutter test && flutter analyze`
Expected: l10n regenerates, all tests PASS, "No issues found!".

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: add localized app bootstrap with go_router and Riverpod"
```

### Task 2: Injectable clock

**Files:**
- Modify: `pubspec.yaml` (add `clock: ^1.1.2` to dependencies; it is already transitive — pin to the lock's resolved version)
- Create: `lib/core/time/clock_provider.dart`
- Create: `docs/decisions/0002-explicit-clock-injection.md`

**Interfaces:**
- Produces: `@Riverpod(keepAlive: true) Clock clock(Ref ref) => const Clock();` → generated `clockProvider`. Import `package:clock/clock.dart` with `show Clock` so the package's global `clock` getter does not collide with the provider function. Domain classes receive `Clock` through their constructor; nothing in `lib/` calls `DateTime.now()` or the global `clock`.

- [ ] **Step 1: Add the dependency and provider; run** `dart run build_runner build --delete-conflicting-outputs`. Expected: `clock_provider.g.dart` generated, untracked.

- [ ] **Step 2: Write ADR 0002** (explicit injection vs zone-based `withClock` vs own interface; why: dependency visible in signatures, a forgotten override fails to compile instead of reading real time on some days; AGENT_RULES 4 and 8.4).

- [ ] **Step 3: Verify**

Run: `grep -rn "DateTime.now()" lib/ ; flutter analyze && flutter test`
Expected: grep prints nothing; "No issues found!"; all tests PASS.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add injectable clock provider"
```

### Task 3: riverpod_lint and mocktail

**Files:**
- Modify: `analysis_options.yaml` (top-level `plugins:` → `riverpod_lint: ^3.1.9`)
- Modify: `pubspec.yaml` (dev_dependencies: `mocktail: ^1.0.5`)
- Create then delete: `lib/core/lint_probe.dart` (temporary)

- [ ] **Step 1: Add the plugin and mocktail; run** `flutter pub get`.

Deviation from the spec: the spec lists `riverpod_lint` under dev_dependencies, but its README (3.1.9) installs it only via `plugins:` in `analysis_options.yaml` (analysis_server_plugin resolves it). Do not add it to `pubspec.yaml`.

- [ ] **Step 2: Prove the plugin loads.** Create a temporary file `lib/core/lint_probe.dart` with `@riverpod int lintProbe(Ref ref, BuildContext context) => 0;` (plus its `part` directive), run `dart run build_runner build --delete-conflicting-outputs && flutter analyze`.
Expected: `avoid_build_context_in_providers` reported. If `flutter analyze` does not report it, run `dart analyze`; record which command reports plugin lints (PR 2 CI depends on it).

- [ ] **Step 3: Delete `lib/core/lint_probe.dart` and verify**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test`
Expected: "No issues found!"; all tests PASS.

- [ ] **Step 4: Commit**

```bash
git add analysis_options.yaml pubspec.yaml pubspec.lock
git commit -m "chore: add riverpod_lint and mocktail"
```

### Task 4: Launch check on the simulator and PR

- [ ] **Step 1: Run on the simulator** — boot `iPhone 16 Pro`, `flutter run -d <simulator id>`. Expected: the home screen shows "Shlyakh". Take a screenshot.

- [ ] **Step 2: Switch the simulator language to Ukrainian** (`xcrun simctl spawn <id> defaults write -g AppleLanguages -array uk` then restart the app, or Settings → General → Language). Expected: "Шлях". Screenshot. Restore English afterwards.

- [ ] **Step 3: Update docs** — `CLAUDE.md` "Commands" already lists `flutter gen-l10n`; add nothing unless Task 3 showed that only `dart analyze` reports plugin lints (then note it under Commands). Tick nothing in `ROADMAP.md` (this PR is infrastructure, not a roadmap item).

- [ ] **Step 4: Push and open the PR** against `main` with What / Why / Verified / Not verified sections; "Not verified" must mention that the physical iPhone was intentionally not used.

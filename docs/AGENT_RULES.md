# Agent Rules

Hard rules for any AI agent working in this repository. They override
convenience. If a task seems to require breaking one, stop and ask.

## 1. Agent behavior

- Stay within the scope of the task. If you notice an unrelated problem,
  report it at the end instead of fixing it silently.
- Ask when a requirement is ambiguous. Do not guess on product decisions.
- Never delete, skip, or weaken a test to make it pass. If a test looks
  wrong, explain why and ask.
- Never swallow errors: no empty `catch`, no `catch (_) {}` without handling
  or rethrowing.
- Repositories catch only specific exceptions and rethrow a `Failure`;
  programmer errors are never caught (`docs/decisions/0005-error-handling.md`).
- In the final report, separate clearly:
  - what was changed,
  - what was verified (commands actually run and their result),
  - what is assumed to work but was not verified.
- Never claim a command succeeded without running it.
- Do not add dependencies without asking first.

## 2. Secrets and security

- Never commit secrets. `.env*` files are gitignored; use `.env.example`
  with placeholder values for documentation.
- Never read or print the contents of `.env` files.
- The Supabase `service_role` key must never appear in client code, in the
  Flutter app, or in the repository. The app uses only the anon key.
- Row Level Security is enabled on every table. Never disable RLS or add a
  permissive policy (`using (true)`) to make something work.
- Every new table ships with RLS policies in the same migration.

## 3. Database

- Schema changes only through migration files in `supabase/migrations/`.
- Never edit a migration that has already been applied. Add a new one.
- Destructive operations (`DROP`, `TRUNCATE`, `DELETE` without `WHERE`,
  `supabase db reset`, `supabase db push`) require explicit permission.
- Never run anything against the production project. Remote database
  changes are applied by the developer manually.
- Schema changes must stay backward compatible with the app version
  currently installed on devices (add columns before using them; remove
  only after the app no longer reads them).

## 4. Dates and time zones

- A "day" is the user's local calendar day, not a UTC day.
- Store daily step records as `(user_id, local_date, timezone)`.
- Never compute day boundaries with `DateTime.now().toUtc()` or by
  truncating UTC timestamps.
- XP/level tests must cover: DST transitions, a day in a different
  timezone (travel), and midnight boundaries.

## 5. Health data and privacy

- Step counts and any HealthKit data are sensitive.
- Never log health data, user ids, emails or tokens: not in `print`,
  not in debug logs, not in crash reports.
- Log only through `AppLogger` with events declared in
  `lib/core/logging/log_events.dart`; `LogValue.count` never carries
  steps, XP, dates or ids. Never log an exception's message
  (`docs/decisions/0006-logging.md`).
- Request only the HealthKit permissions actually used (read: step count).
- The data model must support full deletion of a user's account and data
  (required by the App Store when the app has account creation).

## 6. Sync

- Sync is idempotent: sending the same day twice must not duplicate data.
  Use upsert on `(user_id, local_date)`.
- The app works offline. Drift is the local source of truth; Supabase is
  synced when available.
- HealthKit is the source of truth for raw steps. Never modify step counts
  in the app.

## 7. Code quality

- `dart analyze --fatal-infos` must pass (exit code 0). It includes
  analyzer-plugin lints such as `riverpod_lint`, which `flutter analyze`
  skips; `--fatal-infos` is needed because those lints are info-level.
- No hardcoded user-facing strings (use l10n), no magic design values
  (use tokens).

## 8. Testing

Current scope: unit tests. Widget, golden and integration tests are added
later, when screens stabilize.

### 8.1 Definition of done

- Every change that adds or changes behavior ships with unit tests in the
  same commit. "Tests later" is not done.
- `flutter test` passes and coverage thresholds (8.5) hold.
- Every bug fix starts with a failing test that reproduces the bug.

### 8.2 What must be tested

- **Domain (highest priority):** XP formula, level curve, date/day logic,
  entities with behavior, validation. Every rule in `docs/PRODUCT.md` that
  the domain implements has a test that would fail if the rule changed.
- **Data:** repository implementations against fake data sources: mapping
  between DTOs, Drift rows and entities; sync decisions (upsert, idempotency,
  conflict handling); error translation into domain failures.
- **Presentation logic:** Riverpod notifiers and providers that hold state
  or derive values, tested through `ProviderContainer` with overridden
  dependencies. State transitions: loading, data, error.
- For each unit, cover: the happy path, boundaries (0, 1, max, exact
  threshold, threshold ± 1), invalid input, and the error path.

### 8.3 What not to test (no filler)

- Generated code (`*.g.dart`, `*.freezed.dart`, l10n output).
- Framework or package behavior: that Riverpod caches, that freezed
  implements `==`, that go_router navigates.
- Trivial code without logic: constructors, plain getters, constants,
  re-exports, pure widget composition.
- Private methods directly. Test them through the public API; if that is
  awkward, the code likely needs a separate unit.
- Implementation details: which private helper was called, how many times
  a mock was touched, when the order does not matter to the outcome.
- A test must be able to fail for a reason a product owner would care
  about. If it cannot, delete the idea before writing it.

### 8.4 How tests are written

- **Structure:** `test/` mirrors `lib/`: `lib/features/x/domain/foo.dart`
  → `test/features/x/domain/foo_test.dart`. Shared fakes and builders live
  in `test/helpers/`.
- **Naming:** `group` per unit or method, `test` names describe behavior:
  `'returns level 3 when XP equals the level 3 threshold'`, not
  `'test calculate'`.
- **Shape:** Arrange / Act / Assert, one behavior per test. Several
  `expect` calls are fine when they check one outcome.
- **Table-driven** tests for formulas and thresholds: a list of
  `(input, expected)` cases iterated in a loop, each with a readable name.
- **Test doubles:** prefer hand-written fakes for repositories and data
  sources (in-memory implementations of the domain interface). Use
  `mocktail` only for platform boundaries and for verifying that a side
  effect happened (a sync call was made). Never mock the unit under test
  or pure domain classes; use the real ones.
- **Test data:** use builders/factories with sensible defaults
  (`aDailySteps(steps: 10000)`), so each test states only what matters.
  No copy-pasted fixtures.
- **Determinism:** no real `DateTime.now()`, network, HealthKit,
  Supabase, file system or random numbers in unit tests. Time and
  randomness are injected. The time zone is pinned: tests run with
  `TZ=Europe/Kyiv` (CI sets it; `test/time_zone_test.dart` fails
  without it), so local `DateTime`s and DST cases are the same on every
  machine. Drift uses an in-memory database. No
  `Future.delayed` or sleeps to wait for results.
- **Independence:** tests do not share mutable state and pass in any order
  and in isolation (`flutter test --name`).
- **Speed:** the whole unit suite runs in seconds. A slow unit test is a
  sign of a missing fake.
- **Readability over DRY:** some duplication in tests is acceptable;
  hidden setup that forces reading three files to understand a test is not.

### 8.5 Coverage

Coverage is a floor that catches untested code, not a goal. A covered line
without a meaningful assertion does not count.

- Measure with `flutter test --coverage` (writes `coverage/lcov.info`).
- Excluded from the numbers: generated files, `lib/main.dart`, app
  bootstrap wiring, l10n output and pure widget files.
- Thresholds on line coverage:
  - `domain/`: **100%** (pure logic, no excuses).
  - `data/` and presentation logic (notifiers, providers): **≥ 85%**.
  - Whole measured codebase: **≥ 85%**.
- Checked automatically by `tool/coverage/check_coverage.dart` (runs in
  CI after `flutter test --coverage`). Layers are detected by path;
  presentation logic lives in `lib/features/*/presentation/providers/`.
  A measured file that no test loads fails the check.
- Coverage must not decrease in a change. This is checked in review, not
  by the script. If a line truly cannot be tested, say why in the final
  report instead of writing a hollow test.
- `// coverage:ignore-file` is for rare cases only (e.g. DI wiring) and
  must be followed by a comment with the reason.

### 8.6 Required edge cases for this product

- Dates and XP: see section 4 (DST, time zone change, midnight).
- Steps: zero steps, a partial day (today), a missing day, a very large
  value, a day whose step count changes after a later HealthKit sync.
- Sync: the same day sent twice, offline then online, a partial failure.

## 9. Git

- Small, focused commits with Conventional Commits messages
  (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
- Never force push, never rewrite pushed history, never `reset --hard`
  without permission.
- Generated files (`*.g.dart`, `*.freezed.dart`, l10n output) are never
  committed; they are regenerated locally and on CI. See
  `docs/decisions/0001-generated-files-not-committed.md`.

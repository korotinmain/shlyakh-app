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

- `flutter analyze` must report no issues.
- `flutter test` must pass before a task is considered done.
- Domain logic (XP, levels, date handling) requires unit tests.
- No hardcoded user-facing strings (use l10n), no magic design values
  (use tokens).

## 8. Git

- Small, focused commits with Conventional Commits messages
  (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
- Never force push, never rewrite pushed history, never `reset --hard`
  without permission.
- Generated files (`*.g.dart`, `*.freezed.dart`): see decision in
  `docs/decisions/` (TBD; until decided, do not commit them).

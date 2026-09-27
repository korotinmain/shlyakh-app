# Error handling and logging — design

Date: 2026-09-27
Status: approved in chat, pending spec review

## Goal

Decide, before the first repository exists, how failures travel from data
sources to the UI and what the app may log, so that no layer swallows
errors (AGENT_RULES 1) and nothing sensitive reaches a log (AGENT_RULES 5).

## Success criteria

- One sealed `Failure` type; the UI maps every variant to a localized
  message through an exhaustive switch.
- Logging is possible only through typed events whose fields are of safe
  types; failures are logged by type, never by message.
- Unhandled errors reach the logger instead of disappearing.
- ADR 0005 (errors) and ADR 0006 (logging) record the rules; AGENT_RULES
  and ARCHITECTURE point to them.

## Decisions

| Topic | Decision |
|---|---|
| How failures cross layers | Exceptions: repositories throw domain `Failure`s; providers let them become `AsyncValue.error`; UI switches over `Failure` |
| Programmer errors | `ArgumentError`, `StateError`, `TypeError` are never caught |
| Logging API | Typed `LogEvent`s with `LogValue` fields (flag, kind, duration, count); no free-form strings |
| Log sink | `dart:developer` in debug builds; nothing in release until a crash-reporting service is chosen (separate decision, new dependency) |

## Failures (`lib/core/error/failure.dart`)

```dart
sealed class Failure implements Exception {
  const Failure({this.cause});
  final Object? cause; // original exception, for debugging only
}
final class HealthAccessDenied extends Failure { const HealthAccessDenied({super.cause}); }
final class HealthUnavailable extends Failure { const HealthUnavailable({super.cause}); }
final class StorageFailure extends Failure { const StorageFailure({super.cause}); }
final class UnexpectedFailure extends Failure { const UnexpectedFailure({super.cause}); }
```

- `HealthAccessDenied`: HealthKit read access not granted or revoked.
- `HealthUnavailable`: HealthKit not available on the device.
- `StorageFailure`: Drift/SQLite failed (disk full, corrupt file).
- `UnexpectedFailure`: an unknown exception at a platform or SDK boundary.
- New variants are added with the code that throws them (e.g. network in
  stage 5); the sealed type makes every UI switch fail to compile until it
  handles them.
- `toString()` returns only the variant name, so an accidental
  interpolation cannot leak `cause`.

### Rules between layers

- **Data (repositories)** catch only the specific low-level exceptions of
  their sources and rethrow a `Failure` with the original as `cause`.
  Catch-all `catch (e)` is not allowed in repositories.
- **Programmer errors** are never caught; they fail loudly in development
  and tests.
- **Presentation (providers)** do not catch: exceptions from repositories
  become `AsyncValue.error` by themselves.
- **UI** shows `failureMessage(l10n, failure)`. An error that is not a
  `Failure` (a bug) shows the generic message and is logged with
  `AppLogger.error`.
- **App level:** `main.dart` sets `FlutterError.onError` and
  `PlatformDispatcher.instance.onError` to forward to `AppLogger.error`
  (and, for `FlutterError`, still to `FlutterError.presentError` in debug).

### Messages (`lib/core/error/failure_message.dart`)

`String failureMessage(AppLocalizations l10n, Object error)`: exhaustive
switch over `Failure`; anything else → `l10n.errorGeneric`. ARB keys:
`errorHealthAccessDenied`, `errorHealthUnavailable`, `errorStorage`,
`errorUnexpected`, `errorGeneric`, each in `en` and `uk`. The exact iOS
settings path is not named in the text: it differs across iOS versions and
is verified on a device before it is ever added.

| Key | en | uk |
|---|---|---|
| `errorHealthAccessDenied` | Shlyakh can't read your steps. Allow access to Steps in the Health settings. | Шлях не має доступу до кроків. Дозвольте доступ до кроків у налаштуваннях Здоров'я. |
| `errorHealthUnavailable` | Health data isn't available on this device. | Дані про здоров'я недоступні на цьому пристрої. |
| `errorStorage` | Couldn't save your data on this device. Try restarting the app. | Не вдалося зберегти дані на пристрої. Спробуйте перезапустити застосунок. |
| `errorUnexpected` | Something went wrong while reading your data. | Під час читання даних щось пішло не так. |
| `errorGeneric` | Something went wrong. | Щось пішло не так. |

## Logging

### Events (`lib/core/logging/log_events.dart`)

```dart
sealed class LogValue { ... }          // private subclasses, public factories:
  const LogValue.flag(bool value)
  const LogValue.kind(Enum value)       // rendered as value.name
  const LogValue.duration(Duration value)
  const LogValue.count(int value)       // a number of OBJECTS (days, rows); never steps, XP, dates, ids

sealed class LogEvent {
  String get name;
  Map<String, LogValue> get fields;
}
```

- All events live in this one file so every field is reviewed in one
  place. No event exists yet; the first ones arrive with the repository
  (e.g. `SyncFinished`, `HealthObserverWoke`). Tests use a test-only event.
- Known limit: the compiler cannot tell "3 days" from "3000 steps"; the
  name `count` and AGENT_RULES 5 carry the rule, review enforces it.

### Logger (`lib/core/logging/app_logger.dart`)

```dart
abstract interface class AppLogger {
  void log(LogEvent event);
  void failure(Failure failure);          // "StorageFailure (cause: SqliteException)" — types only
  void error(Object error, StackTrace stackTrace); // runtime type + stack trace, never the message
}

final class DeveloperLogger implements AppLogger {
  const DeveloperLogger({required bool enabled}); // enabled: kDebugMode at the call site
  // writes with dart:developer log(); does nothing when !enabled
}
```

- `loggerProvider` (`lib/core/logging/logger_provider.dart`, keepAlive):
  `DeveloperLogger(enabled: kDebugMode)`. DI wiring: coverage opt-out with
  a reason, like `clockProvider`.
- `dart:developer`'s `log` is used only inside `DeveloperLogger`.
- Output format (debug console): `event <name> key=value …`,
  `failure <Variant> cause=<CauseType>`, `error <ErrorType>` + stack
  trace. Values: flag `true`/`false`, kind `name`, duration in
  milliseconds (`1234ms`), count as the number.
- `DeveloperLogger` takes an optional sink `void Function(String message, {Object? stackTrace})`
  (defaults to `dart:developer` `log`) so tests can capture output.

## Testing

- `failure_message_test.dart`: every variant and a non-`Failure` in `en`
  and `uk` (table from this spec); `Failure.toString()` is the variant name
  and does not contain the cause's text.
- `app_logger_test.dart` (with a capturing sink):
  - `log` renders name and each value type as specified;
  - `failure` writes variant and cause type, and not a secret string
    placed in the cause's message;
  - `error` writes the type and stack trace, not the error's message;
  - `enabled: false` writes nothing for all three.
- `test/helpers/recording_logger.dart`: `RecordingLogger implements AppLogger`
  (lists of events, failures, errors) for future repository and provider
  tests.
- App-level handlers: a test that a `FlutterErrorDetails` passed to the
  installed handler reaches the logger (the handler is a function in
  `lib/app/error_handlers.dart` taking an `AppLogger`, so it is testable
  without running `main`).

## Docs

- `docs/decisions/0005-error-handling.md`, `docs/decisions/0006-logging.md`.
- AGENT_RULES 1 (no swallowing) and 5 (no sensitive logs) link the ADRs;
  5 adds: "log only through `AppLogger` with events from
  `lib/core/logging/log_events.dart`; `LogValue.count` never carries
  steps, XP, dates or ids".
- ARCHITECTURE section 5: error handling and logging → [built].

## Out of scope

- Crash reporting service (Sentry/Crashlytics): later, new dependency.
- Concrete events and repository translations: with the repository task.
- Network failures: stage 5.

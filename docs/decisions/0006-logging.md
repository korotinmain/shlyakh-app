# 0006. Logging: typed events, no messages

Date: 2026-09-27
Status: accepted

## Context

AGENT_RULES 5 forbids logging health data, user ids, emails and tokens.
Rules that depend on discipline fail quietly: one `'$day'` in a message
leaks a step count. Diagnosing background sync still needs some logs.
Options: typed events; the `logging` package with free-form messages and
a review rule; no logs at all.

## Decision

- Log only through `AppLogger` (`lib/core/logging/app_logger.dart`) with
  events declared in `lib/core/logging/log_events.dart`. Event fields are
  `LogValue`s: `flag`, `kind` (enum), `duration`, `count` (a number of
  objects; never steps, XP, dates or ids). No free-form strings.
- `failure()` logs the variant and the cause's type; `error()` logs the
  type and stack trace. Exception messages are never logged: they may
  contain SQL values, paths or user data.
- `DeveloperLogger` writes through `dart:developer` only in debug builds;
  release builds log nothing until a crash-reporting service is chosen (a
  separate decision with a new dependency, behind the same interface).
- `dart:developer` is imported nowhere else; `print` is forbidden by
  `avoid_print`, and `debugPrint` (which `avoid_print` does not catch) is
  forbidden too.
- `test/core/logging/logging_policy_test.dart` enforces this: it fails on
  `debugPrint(`, on `dart:developer` outside the logger, on a `LogEvent`
  declared outside `log_events.dart`, and on an interpolated event name.

## Consequences

- Most leaks are impossible by construction or fail the policy test; the
  remaining one (a step count passed as `count`) is caught by reviewing
  one file.
- In debug builds `FlutterError.presentError` still prints framework
  errors in full, as Flutter's own report; asynchronous errors are logged
  by type only. Our code never puts user data into exception messages.
- In release builds errors leave no trace until crash reporting replaces
  `DeveloperLogger`; that stage must also re-install the handlers in
  `main.dart`, which read the logger once at startup.
- Every new event costs a few lines in `log_events.dart`.
- Logs contain type names, which are obfuscated if release builds are
  ever obfuscated; they are for debugging, not analytics.

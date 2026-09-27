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
- `dart:developer` `log` is used nowhere else; `print` is already
  forbidden by `avoid_print`.

## Consequences

- Most leaks are impossible by construction; the remaining one (a step
  count passed as `count`) is caught by reviewing one file.
- Every new event costs a few lines in `log_events.dart`.
- Logs contain type names, which are obfuscated if release builds are
  ever obfuscated; they are for debugging, not analytics.

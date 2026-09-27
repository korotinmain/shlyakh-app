# 0005. Error handling: exceptions and a sealed Failure

Date: 2026-09-27
Status: accepted

## Context

Data comes from HealthKit, SQLite and later Supabase, each with its own
exception types. The UI must show a localized, understandable message;
AGENT_RULES 1 forbids swallowing errors. Riverpod already models async
state as `AsyncValue` (loading, data, error). Options: exceptions with a
typed domain failure, or a `Result<T, Failure>` return type.

## Decision

- Repositories catch only the specific low-level exceptions of their
  sources and throw a `Failure` (`lib/core/error/failure.dart`) with the
  original as `cause`. No catch-all in repositories.
- `Failure` is sealed: `HealthAccessDenied`, `HealthUnavailable`,
  `StorageFailure`, `UnexpectedFailure`. New variants arrive with the code
  that throws them.
- Programmer errors (`ArgumentError`, `StateError`, `TypeError`) are never
  caught.
- Providers do not catch; failures become `AsyncValue.error`.
- The UI shows `failureMessage(l10n, error)`: a specific message per
  variant, the generic one for anything else.
- `main.dart` routes `FlutterError.onError` and
  `PlatformDispatcher.instance.onError` to the logger (ADR 0006).

## Consequences

- Idiomatic with Riverpod; no wrapper type on every call.
- Adding a `Failure` variant breaks compilation of `failureMessage` until
  it has a message, so no failure reaches the UI without text.
- A failure is invisible in signatures (unlike `Result`); repository tests
  pin which exceptions become which failure.
- `Failure.toString()` is only the variant name, so interpolating a
  failure cannot leak its cause.

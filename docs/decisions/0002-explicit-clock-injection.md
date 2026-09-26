# 0002. Explicit clock injection

Date: 2026-09-26
Status: accepted

## Context

Days are local calendar days, and XP/level tests must cover DST
transitions, time zone changes and midnight (`docs/AGENT_RULES.md`,
sections 4 and 8.4). Tests therefore need full control over "now".
Options considered:

- A. Inject a `Clock` explicitly: through the constructor in domain code,
  through a Riverpod provider in presentation.
- B. Use the `clock` package's zone-based global `clock` and wrap tests in
  `withClock(...)`.
- C. Own `Clock` interface without the package.

## Decision

A. The type is `Clock` from `package:clock` (`Clock.fixed` for tests,
compatible with `fake_async`). `clockProvider` in
`lib/core/time/clock_provider.dart` is the only place that creates a real
clock. Code in `lib/` does not call `DateTime.now()` or the global `clock`.

## Consequences

- The dependency on time is visible in every signature that needs it.
- A test that forgets to provide a clock fails to compile instead of
  silently reading real time and failing only on some days (the risk of
  B).
- One extra constructor parameter for time-dependent domain classes.
- The "no `DateTime.now()` in lib/" rule is currently enforced by review;
  a custom lint or CI grep can enforce it later.

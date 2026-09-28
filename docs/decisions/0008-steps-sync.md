# 0008. Steps sync: journey start, window and background runs

Date: 2026-09-28
Status: accepted

## Context

ADR 0007 settled how to read daily totals and that iOS wakes the app
about hourly. The sync on top of it had to decide where a user's history
begins, which days to re-read and when a stored day may change, and it
depended on an open question: does Dart run at all when HealthKit
relaunches a closed app in the background? A throwaway probe on a real
iPhone (release build, Personal Team) answered it. Spec:
`docs/superpowers/specs/2026-09-28-healthkit-steps-sync-design.md`.

## Decision

- **Journey start.** The journey starts when the user taps "Allow" on the
  Health access screen: the UTC instant of the tap and the IANA zone are
  stored in `journey_start`, once per user, after the system prompt
  succeeds. Nothing before it is imported; the first day is partial
  (steps after the start only) and differs from the Health app's total.
- **What to query.** The first sync queries from the start. Later syncs
  re-read the last 7 days (Watch data arrives late, samples get
  deleted), or from the last stored day when that is older (no sync for
  over a week), never before the start.
- **What to write.** New days and days whose count changed, also to a
  lower value. A stored day counted in another time zone is kept, so a
  flight does not recount earlier days with new midnights; identical days
  are skipped.
- **When.** On launch, on return to the foreground and on each HealthKit
  wakeup, through one shared `StepsSync` that runs once at a time (a
  burst gives at most two runs). Failures are logged and never thrown.
- **Background.** Swift calls HealthKit's completion handler only after
  Dart's `onStepsChanged` replies (or after 20 s). Dart registers the
  handler in `main.dart` before `runApp`.

## Evidence

Probe journal, 2026-09-28 11:20:12, app closed:
`launch` in the background state → `flutter engine created` →
`observer fired` → `dart main` → `dart sync: 3 days written in 47 ms` →
`dart replied` → `completion after 0.1 s`. `FlutterImplicitEngineDelegate`
creates the engine without a scene; the wakeup sent before Dart had a
handler was held by the channel buffer. The same probe found that
`enumerateStatistics(from:to:)` includes the interval that contains the
end date, which had added tomorrow as a zero day (fixed in #19).

## Consequences

- Stored history is only as old as the journey. A reinstall before the
  backend exists starts a new journey (the database leaves with the app);
  an iCloud restore keeps it.
- The first day never matches the Health app. This is intended, not a bug.
- A day stored in another zone no longer receives late Watch data, and a
  renamed zone identifier after an OS update freezes the days in the
  window the same way. Accepted.
- On the travel day a slice of steps can be counted twice or missed, and
  a westward flight can create a partial day dated before the start's
  local date. Accepted; the UI tolerates it.
- The iOS prompt mentions Background App Refresh, but HealthKit delivery
  needs no `UIBackgroundModes`: the app is not listed there, and the
  probe was woken in the background all the same. Whether the
  system-wide switch or Low Power Mode stops the wakeups is not verified;
  without wakeups the app syncs on launch and in the foreground only.
- The hint a day after the start with no steps covers denied read access,
  which iOS never reports; it points to the Health app (profile → Apps),
  a path that works on every iOS version.
- Not verified: a relaunch after a force-quit or a reboot, and a sync
  while the device is locked (it fails with `HealthDataLocked` and the
  next trigger retries).

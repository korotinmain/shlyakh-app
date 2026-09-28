# 0007. HealthKit: daily totals and background delivery

Date: 2026-09-28
Status: accepted

## Context

Stage 1 of the roadmap checked on a real iPhone with an Apple Watch
(Personal Team signing, release build) how to read daily steps and
whether iOS wakes the app when new steps arrive. The probe lives on the
throwaway `spike/healthkit` branch. It compared three ways of counting a
day against the Health app: summing raw samples by hand, the `health`
plugin's `getTotalStepsInInterval` (`HKStatisticsQuery`, cumulative sum),
and a native `HKStatisticsCollectionQuery` via Pigeon. It also logged
every `HKObserverQuery` callback with the app state at that moment.

Findings:

- Summing raw samples double counts: iPhone and Watch both record the same
  walk, which gave up to about twice the Health total.
- Statistics queries deduplicate by per-interval source priority (the
  Watch wins over the iPhone), not by taking the larger device. The plugin
  result matched Health exactly, because both truncate fractional steps;
  the native query with `.rounded()` was one step higher on some days.
- Local midnight (`Calendar.current`) gives the same day boundaries as
  Health (tested in EEST).
- Background delivery works with a Personal Team. Over 36 hours
  (2026-09-26 20:00 to 2026-09-28 08:35) the observer fired 18 times with
  the app in the `background` state, without the app being opened. The
  gaps were usually 1 to 1.5 hours, the shortest 20 minutes, and there were
  none overnight while no steps were recorded (00:45 to 11:11,
  22:48 to 07:33). `.immediate` was requested; iOS limits step count
  deliveries to about once an hour.
- An observer started before the user grants access fails with an
  authorization error and must be started again after the permission
  prompt.
- The `health` plugin has no `HKObserverQuery` or background delivery API
  on iOS.

## Decision

- Daily totals come from a statistics query with a cumulative sum per
  local day. The app never sums raw samples and never deduplicates
  sources itself; fractional totals are truncated, like Health.
- Background delivery is native Swift: an `HKObserverQuery` on step count
  is registered in `application(_:didFinishLaunchingWithOptions:)` on
  every launch, with `enableBackgroundDelivery(for:frequency:)` requested
  at `.hourly`, which is what iOS delivers for steps anyway. It is started
  again right after the permission prompt. The callback only signals
  "steps changed" to Dart through Pigeon and always calls its completion
  handler, otherwise HealthKit backs off.
- Data is refreshed on three triggers: app launch, return to the
  foreground, and an observer callback. The foreground refresh keeps the
  screen current; background delivery keeps Drift (and later Supabase)
  at most about an hour behind while the app is closed.
- Entitlements: `com.apple.developer.healthkit` and
  `com.apple.developer.healthkit.background-delivery`. Not
  `com.apple.developer.healthkit.access` (clinical records), which is not
  used and which a Personal Team cannot sign.

## Consequences

- Спільно members see each other's steps with a delay of up to about an
  hour when the other person's app is closed. The product must not
  promise live positions of other members.
- The repository can be tested against a fake data source; deduplication
  and day totals are HealthKit's job, so there is no dedup logic to test.
- Not verified in the spike, to check when the real sync is built:
  whether Dart code (the Flutter engine) gets enough time in a background
  wakeup to query HealthKit and write to Drift; whether the app is
  relaunched after the user force-quits it or after a reboot; and data
  access while the phone is locked (HealthKit data is encrypted then).
  If Dart cannot run reliably in the background, the native side reads
  the totals and hands them over on the next launch.
- A Personal Team build expires after 7 days, so long background tests
  need reinstalling; the log in `UserDefaults` does not survive it.

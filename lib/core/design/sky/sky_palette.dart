import 'package:shlyakh/core/design/sky/oklab.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';
import 'package:shlyakh/core/design/sky/solar.dart';

/// Minutes each keyframe sits from its sun event (docs/DESIGN.md, "Sky").
const _preDawnBeforeSunrise = 60;
const _morningAfterSunrise = 90;
const _goldenBeforeSunset = 60;
const _blueAfterSunset = 20;
const _nightAfterSunset = 90;

/// Night blends into pre-dawn over this many minutes before pre-dawn.
const _nightToPreDawnMinutes = 60;

/// The sky at [wallClock], whose date and time fields are read as the
/// local wall-clock time at [utcOffset] (defaults to the value's own
/// offset). Pass the injected clock's time: never `DateTime.now()`.
///
/// Keyframes are placed by the sun of that local date at
/// [latitude]/[longitude]; colours between keyframes are interpolated.
SkyPalette skyAt(
  DateTime wallClock, {
  double latitude = kyivLatitude,
  double longitude = kyivLongitude,
  Duration? utcOffset,
}) {
  final offset = utcOffset ?? wallClock.timeZoneOffset;
  final instant = DateTime.utc(
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
    wallClock.millisecond,
  ).subtract(offset);

  final sun = sunTimesUtc(
    year: wallClock.year,
    month: wallClock.month,
    day: wallClock.day,
    latitude: latitude,
    longitude: longitude,
  );
  if (sun == null) {
    final summer = wallClock.month >= 4 && wallClock.month <= 9;
    final northern = latitude >= 0;
    return skyKeyframes[summer == northern
        ? SkyKeyframe.day
        : SkyKeyframe.night]!;
  }

  DateTime minutesFrom(DateTime event, int minutes) =>
      event.add(Duration(minutes: minutes));
  final keyframeTimes = <(SkyKeyframe, DateTime)>[
    (SkyKeyframe.preDawn, minutesFrom(sun.sunrise, -_preDawnBeforeSunrise)),
    (SkyKeyframe.dawn, sun.sunrise),
    (SkyKeyframe.morning, minutesFrom(sun.sunrise, _morningAfterSunrise)),
    (SkyKeyframe.day, sun.solarNoon),
    (SkyKeyframe.goldenHour, minutesFrom(sun.sunset, -_goldenBeforeSunset)),
    (SkyKeyframe.blueHour, minutesFrom(sun.sunset, _blueAfterSunset)),
    (SkyKeyframe.night, minutesFrom(sun.sunset, _nightAfterSunset)),
  ];

  final preDawn = keyframeTimes.first.$2;
  if (instant.isBefore(preDawn)) {
    final blendStart = minutesFrom(preDawn, -_nightToPreDawnMinutes);
    if (!instant.isAfter(blendStart)) return skyKeyframes[SkyKeyframe.night]!;
    return lerpPalette(
      skyKeyframes[SkyKeyframe.night]!,
      skyKeyframes[SkyKeyframe.preDawn]!,
      _fraction(instant, blendStart, preDawn),
    );
  }

  for (var i = 0; i < keyframeTimes.length - 1; i++) {
    final (from, fromTime) = keyframeTimes[i];
    final (to, toTime) = keyframeTimes[i + 1];
    if (instant.isBefore(toTime)) {
      return lerpPalette(
        skyKeyframes[from]!,
        skyKeyframes[to]!,
        _fraction(instant, fromTime, toTime),
      );
    }
  }
  return skyKeyframes[SkyKeyframe.night]!;
}

/// Blends every colour of [a] into [b] by [t]; text colour and surface
/// tone switch at the halfway point.
SkyPalette lerpPalette(SkyPalette a, SkyPalette b, double t) {
  if (t <= 0) return a;
  if (t >= 1) return b;
  List<int> blend(List<int> x, List<int> y) => [
    for (var i = 0; i < x.length; i++) lerpArgb(x[i], y[i], t),
  ];
  final second = t >= 0.5;
  return (
    sky: blend(a.sky, b.sky),
    hills: blend(a.hills, b.hills),
    accent: lerpArgb(a.accent, b.accent, t),
    onSky: second ? b.onSky : a.onSky,
    surfaceTone: second ? b.surfaceTone : a.surfaceTone,
  );
}

double _fraction(DateTime instant, DateTime from, DateTime to) =>
    instant.difference(from).inMilliseconds /
    to.difference(from).inMilliseconds;

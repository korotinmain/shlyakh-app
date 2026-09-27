// Sunrise, solar noon and sunset with the NOAA Solar Calculator equations
// (based on Meeus, "Astronomical Algorithms"): accurate to about a minute
// for any year. Pure Dart.
//
// Not the shorter "general solar position" (Spencer) series: it is fitted
// to a 1950 epoch and drifts by about a day in declination near the
// equinoxes today, which is minutes of sunrise error.
import 'dart:math' as math;

/// Default coordinates until location is a deliberate decision (privacy):
/// Kyiv. Anywhere in Ukraine the error is minutes, invisible in the sky.
const kyivLatitude = 50.45;
const kyivLongitude = 30.52;

/// Sun events of one day, in UTC.
typedef SunTimes = ({DateTime sunrise, DateTime solarNoon, DateTime sunset});

/// Sun times for the calendar day at [latitude]/[longitude] (degrees,
/// east positive), or null when the sun does not rise or set that day
/// (polar day or night).
SunTimes? sunTimesUtc({
  required int year,
  required int month,
  required int day,
  required double latitude,
  required double longitude,
}) {
  final midnight = DateTime.utc(year, month, day);
  // Evaluate the sun at local solar noon (UTC noon shifted by longitude).
  final sun = _sunAt(_julianDay(midnight) + 0.5 - longitude / 360);

  final lat = _rad(latitude);
  // Zenith 90.833°: the sun's upper limb on the horizon, with refraction.
  final cosHourAngle =
      math.cos(_rad(90.833)) / (math.cos(lat) * math.cos(sun.declination)) -
      math.tan(lat) * math.tan(sun.declination);
  if (cosHourAngle < -1 || cosHourAngle > 1) return null;
  final hourAngle = _deg(math.acos(cosHourAngle));

  DateTime at(double minutes) =>
      midnight.add(Duration(milliseconds: (minutes * 60000).round()));
  final noon = 720 - 4 * longitude - sun.equationOfTime;
  return (
    sunrise: at(noon - 4 * hourAngle),
    solarNoon: at(noon),
    sunset: at(noon + 4 * hourAngle),
  );
}

/// Declination (radians) and equation of time (minutes) at [julianDay].
({double declination, double equationOfTime}) _sunAt(double julianDay) {
  final t = (julianDay - 2451545) / 36525; // Julian centuries from J2000.
  final meanLongitude = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360;
  final meanAnomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  final eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  final m = _rad(meanAnomaly);
  final center =
      math.sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
      math.sin(2 * m) * (0.019993 - 0.000101 * t) +
      math.sin(3 * m) * 0.000289;
  final omega = _rad(125.04 - 1934.136 * t);
  final apparentLongitude = _rad(
    meanLongitude + center - 0.00569 - 0.00478 * math.sin(omega),
  );
  final meanObliquity =
      23 +
      (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60;
  final obliquity = _rad(meanObliquity + 0.00256 * math.cos(omega));

  final declination = math.asin(
    math.sin(obliquity) * math.sin(apparentLongitude),
  );
  final y = math.pow(math.tan(obliquity / 2), 2).toDouble();
  final l0 = _rad(meanLongitude);
  final e = eccentricity;
  final equationOfTime =
      4 *
      _deg(
        y * math.sin(2 * l0) -
            2 * e * math.sin(m) +
            4 * e * y * math.sin(m) * math.cos(2 * l0) -
            0.5 * y * y * math.sin(4 * l0) -
            1.25 * e * e * math.sin(2 * m),
      );
  return (declination: declination, equationOfTime: equationOfTime);
}

/// Julian day number at [utc].
double _julianDay(DateTime utc) =>
    utc.millisecondsSinceEpoch / 86400000 + 2440587.5;

double _rad(num degrees) => degrees * math.pi / 180;

double _deg(num radians) => radians * 180 / math.pi;

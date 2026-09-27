import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';
import 'package:shlyakh/core/design/sky/sky_palette.dart';
import 'package:shlyakh/core/design/sky/solar.dart';

const _summer = Duration(hours: 3); // Kyiv, EEST
const _winter = Duration(hours: 2); // Kyiv, EET

/// Wall-clock time [minutes] after midnight of 2026-[month]-[day]. The
/// fields are read as wall-clock time; the offset is passed separately.
DateTime _wall(int month, int day, int minutes) =>
    DateTime.utc(2026, month, day).add(Duration(minutes: minutes));

/// Wall-clock instant of a UTC instant at [offset].
DateTime _toWall(DateTime utc, Duration offset) {
  final wall = utc.add(offset);
  return DateTime.utc(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
    wall.second,
    wall.millisecond,
  );
}

SunTimes _sun(int month, int day) => sunTimesUtc(
  year: 2026,
  month: month,
  day: day,
  latitude: kyivLatitude,
  longitude: kyivLongitude,
)!;

/// Keyframe instants of 2026-06-21 in Kyiv, as wall-clock times.
Map<SkyKeyframe, DateTime> _instants() {
  final sun = _sun(6, 21);
  DateTime w(DateTime utc) => _toWall(utc, _summer);
  return {
    SkyKeyframe.preDawn: w(sun.sunrise.subtract(const Duration(minutes: 60))),
    SkyKeyframe.dawn: w(sun.sunrise),
    SkyKeyframe.morning: w(sun.sunrise.add(const Duration(minutes: 90))),
    SkyKeyframe.day: w(sun.solarNoon),
    SkyKeyframe.goldenHour: w(sun.sunset.subtract(const Duration(minutes: 60))),
    SkyKeyframe.blueHour: w(sun.sunset.add(const Duration(minutes: 20))),
    SkyKeyframe.night: w(sun.sunset.add(const Duration(minutes: 90))),
  };
}

/// Palettes are equal when every colour and flag is equal (records compare
/// their lists by identity, so `equals` on the record is not enough).
Matcher _samePalette(SkyPalette? expected) => predicate<SkyPalette>(
  (actual) =>
      expected != null &&
      _listEquals(actual.sky, expected.sky) &&
      _listEquals(actual.hills, expected.hills) &&
      actual.accent == expected.accent &&
      actual.onSky == expected.onSky &&
      actual.surfaceTone == expected.surfaceTone,
  'the same colours as $expected',
);

bool _listEquals(List<int> a, List<int> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((e) => e);

SkyPalette _at(DateTime wall, [Duration offset = _summer]) =>
    skyAt(wall, utcOffset: offset);

/// WCAG 2 contrast ratio of two opaque ARGB colours.
double _contrast(int a, int b) {
  double luminance(int argb) {
    double channel(int shift) {
      final c = ((argb >> shift) & 0xFF) / 255;
      return c <= 0.04045
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
  }

  final la = luminance(a);
  final lb = luminance(b);
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

int _maxChannelDiff(int a, int b) => [16, 8, 0]
    .map((s) => (((a >> s) & 0xFF) - ((b >> s) & 0xFF)).abs())
    .reduce((x, y) => x > y ? x : y);

void main() {
  group('skyAt on 2026-06-21 in Kyiv', () {
    final instants = _instants();

    for (final keyframe in SkyKeyframe.values) {
      test('is exactly ${keyframe.name} at its instant', () {
        expect(_at(instants[keyframe]!), _samePalette(skyKeyframes[keyframe]));
      });
    }

    test('is between day and golden hour halfway through', () {
      final day = instants[SkyKeyframe.day]!;
      final golden = instants[SkyKeyframe.goldenHour]!;
      final halfway = day.add(golden.difference(day) ~/ 2);
      final palette = _at(halfway);

      expect(palette, isNot(_samePalette(skyKeyframes[SkyKeyframe.day])));
      expect(
        palette,
        isNot(_samePalette(skyKeyframes[SkyKeyframe.goldenHour])),
      );
    });

    test('holds night after midnight', () {
      expect(
        _at(_wall(6, 21, 30)),
        _samePalette(skyKeyframes[SkyKeyframe.night]),
      );
    });

    test('holds night late in the evening', () {
      expect(
        _at(_wall(6, 21, 23 * 60 + 50)),
        _samePalette(skyKeyframes[SkyKeyframe.night]),
      );
    });

    test('is still night 60 minutes before pre-dawn', () {
      final preDawn = instants[SkyKeyframe.preDawn]!;

      expect(
        _at(preDawn.subtract(const Duration(minutes: 60))),
        skyKeyframes[SkyKeyframe.night],
      );
    });

    test('is almost pre-dawn one minute before it', () {
      final preDawn = instants[SkyKeyframe.preDawn]!;
      final palette = _at(preDawn.subtract(const Duration(minutes: 1)));
      final target = skyKeyframes[SkyKeyframe.preDawn]!;

      for (var i = 0; i < 3; i++) {
        expect(_maxChannelDiff(palette.sky[i], target.sky[i]), lessThan(6));
      }
    });
  });

  group('time zone offset', () {
    test('uses the given offset for the same wall-clock time', () {
      final sun = _sun(3, 29); // DST starts in Kyiv on 2026-03-29
      final dawnSummer = _toWall(sun.sunrise, _summer);

      expect(_at(dawnSummer), _samePalette(skyKeyframes[SkyKeyframe.dawn]));
      expect(
        _at(dawnSummer, _winter),
        isNot(_samePalette(skyKeyframes[SkyKeyframe.dawn])),
      );
    });

    test('the local dawn moves by the offset change across DST', () {
      final before = _toWall(_sun(3, 28).sunrise, _winter);
      final after = _toWall(_sun(3, 29).sunrise, _summer);
      final minutesBefore = before.hour * 60 + before.minute;
      final minutesAfter = after.hour * 60 + after.minute;

      // One hour later on the clock, minus the ~2 minutes the sun gains.
      expect(minutesAfter - minutesBefore, inInclusiveRange(55, 60));
      expect(_at(after), _samePalette(skyKeyframes[SkyKeyframe.dawn]));
    });
  });

  test('refuses a UTC time without an explicit offset', () {
    expect(() => skyAt(DateTime.utc(2026, 6, 21, 12)), throwsAssertionError);
  });

  group('polar latitudes', () {
    test('hold day in a polar summer', () {
      expect(
        skyAt(_wall(6, 21, 12 * 60), latitude: 80, utcOffset: Duration.zero),
        skyKeyframes[SkyKeyframe.day],
      );
    });

    test('hold night in a polar winter', () {
      expect(
        skyAt(_wall(12, 21, 12 * 60), latitude: 80, utcOffset: Duration.zero),
        skyKeyframes[SkyKeyframe.night],
      );
    });
  });

  group('keyframe table', () {
    final expected = <SkyKeyframe, (int, SurfaceTone)>{
      SkyKeyframe.preDawn: (0xFFFFFFFF, SurfaceTone.dark),
      SkyKeyframe.dawn: (0xFFFFFFFF, SurfaceTone.dark),
      SkyKeyframe.morning: (0xFF18293A, SurfaceTone.light),
      SkyKeyframe.day: (0xFF18293A, SurfaceTone.light),
      SkyKeyframe.goldenHour: (0xFF18293A, SurfaceTone.dark),
      SkyKeyframe.blueHour: (0xFFFFFFFF, SurfaceTone.dark),
      SkyKeyframe.night: (0xFFFFFFFF, SurfaceTone.dark),
    };
    for (final MapEntry(key: keyframe, value: (onSky, tone))
        in expected.entries) {
      test('${keyframe.name} has its text colour and surface tone', () {
        expect(skyKeyframes[keyframe]!.onSky, onSky);
        expect(skyKeyframes[keyframe]!.surfaceTone, tone);
      });
    }

    for (final MapEntry(key: keyframe, value: palette)
        in skyKeyframes.entries) {
      test('${keyframe.name} text on the sky meets WCAG AA contrast', () {
        expect(
          _contrast(palette.onSky, palette.sky.first),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    test('day has the spec colours', () {
      final day = skyKeyframes[SkyKeyframe.day]!;

      expect(day.sky, [0xFF6C9DCC, 0xFFA2C8E5, 0xFFE0EEF1]);
      expect(day.hills, [0xFFAECFC2, 0xFF7EAF85, 0xFF4D8259]);
      expect(day.accent, 0xFFE9B44C);
    });
  });
}

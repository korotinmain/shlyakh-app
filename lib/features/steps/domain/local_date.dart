import 'package:meta/meta.dart';

/// A calendar day in the user's local time zone, with no time and no UTC
/// offset (docs/AGENT_RULES.md, section 4). Stored as `YYYY-MM-DD`.
@immutable
final class LocalDate implements Comparable<LocalDate> {
  const new _(this.year, this.month, this.day);

  /// Parses exactly `YYYY-MM-DD` of a real calendar date.
  ///
  /// Throws [FormatException] otherwise, including impossible dates such
  /// as `2026-02-29` that `DateTime.parse` would roll over silently.
  factory parse(String iso) {
    final match = _isoPattern.firstMatch(iso);
    if (match == null) {
      throw FormatException('Expected YYYY-MM-DD', iso);
    }
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    if (month < 1 || month > 12 || day < 1 || day > _daysInMonth(year, month)) {
      throw FormatException('Not a calendar date', iso);
    }
    return LocalDate._(year, month, day);
  }

  /// The calendar day of [local], read from its fields as wall-clock
  /// time (no time-zone conversion).
  factory fromDateTime(DateTime local) =>
      LocalDate._(local.year, local.month, local.day);

  /// Inverse of [_epochDay] (H. Hinnant, "civil_from_days").
  factory _fromEpochDay(int epochDay) {
    final z = epochDay + 719468;
    final era = (z >= 0 ? z : z - 146096) ~/ 146097;
    final dayOfEra = z - era * 146097;
    final yearOfEra =
        (dayOfEra -
            dayOfEra ~/ 1460 +
            dayOfEra ~/ 36524 -
            dayOfEra ~/ 146096) ~/
        365;
    final dayOfYear =
        dayOfEra - (365 * yearOfEra + yearOfEra ~/ 4 - yearOfEra ~/ 100);
    final mp = (5 * dayOfYear + 2) ~/ 153;
    final day = dayOfYear - (153 * mp + 2) ~/ 5 + 1;
    final month = mp < 10 ? mp + 3 : mp - 9;
    final year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0);
    return LocalDate._(year, month, day);
  }

  static final _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  /// The following calendar day.
  LocalDate next() {
    if (day < _daysInMonth(year, month)) {
      return LocalDate._(year, month, day + 1);
    }
    if (month < 12) return LocalDate._(year, month + 1, 1);
    return LocalDate._(year + 1, 1, 1);
  }

  /// The day [days] calendar days later (earlier when negative).
  LocalDate addDays(int days) => LocalDate._fromEpochDay(_epochDay + days);

  /// ISO weekday: 1 is Monday, 7 is Sunday.
  int get weekday => (_epochDay + 3) % 7 + 1;

  /// Days since 1970-01-01 (a Thursday), proleptic Gregorian calendar.
  /// Algorithm: H. Hinnant, "days_from_civil".
  int get _epochDay {
    final y = month <= 2 ? year - 1 : year;
    final era = (y >= 0 ? y : y - 399) ~/ 400;
    final yearOfEra = y - era * 400;
    final dayOfYear = (153 * (month + (month > 2 ? -3 : 9)) + 2) ~/ 5 + day - 1;
    final dayOfEra =
        yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
    return era * 146097 + dayOfEra - 719468;
  }

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  String toIsoString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIsoString();

  static int _daysInMonth(int year, int month) => switch (month) {
    2 => _isLeapYear(year) ? 29 : 28,
    4 || 6 || 9 || 11 => 30,
    _ => 31,
  };

  static bool _isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
}

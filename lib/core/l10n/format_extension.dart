import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware number and date formatting for widgets.
extension FormatX on BuildContext {
  String get _locale => Localizations.localeOf(this).toLanguageTag();

  /// `6,870` in English, `6 870` (non-breaking space) in Ukrainian.
  String formatInt(int value) =>
      NumberFormat.decimalPattern(_locale).format(value);

  /// Kilometres with one decimal from [meters]: `5.1`, `5,1`.
  String formatKm(int meters) => NumberFormat.decimalPatternDigits(
    locale: _locale,
    decimalDigits: 1,
  ).format(meters / 1000);

  /// Weekday and date: `Monday, September 28`, `понеділок, 28 вересня`.
  String formatLongDate(DateTime date) =>
      DateFormat.MMMMEEEEd(_locale).format(date);

  /// Day and month: `September 24`, `24 вересня`.
  String formatDayMonth(DateTime date) =>
      DateFormat.MMMMd(_locale).format(date);

  /// Short weekday: `Mon`, `пн`.
  String formatShortWeekday(DateTime date) =>
      DateFormat.E(_locale).format(date);
}

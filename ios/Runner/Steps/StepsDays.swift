import Foundation

/// Pure date and number helpers for the daily steps query, kept apart from
/// HealthKit so XCTest can cover them.
enum StepsDays {
  /// The span to query from `from` to the end of the day containing `now`.
  /// `dayStart` is the start of the day containing `from`: the query's
  /// anchor and first enumerated interval. `lastDayStart` is the start of
  /// today, the last interval to enumerate: `enumerateStatistics(from:to:)`
  /// includes the interval containing `to`, so enumerating to `end` would
  /// add tomorrow. Nil when `from` is not before the end of today (a start
  /// in the future).
  static func queryRange(from: Date, now: Date, calendar: Calendar)
    -> (dayStart: Date, from: Date, end: Date, lastDayStart: Date)?
  {
    let dayStart = calendar.startOfDay(for: from)
    let lastDayStart = calendar.startOfDay(for: now)
    guard
      let end = calendar.date(byAdding: .day, value: 1, to: lastDayStart),
      from < end
    else { return nil }
    return (dayStart, from, end, lastDayStart)
  }

  /// `yyyy-MM-dd` for `date` in the calendar's time zone.
  static func localDateString(_ date: Date, calendar: Calendar) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  /// Whole steps, dropping the fraction like the Health app (ADR 0007).
  static func truncatedSteps(_ sum: Double) -> Int64 {
    Int64(sum.rounded(.towardZero))
  }
}

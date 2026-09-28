import XCTest

@testable import Runner

final class StepsDaysTests: XCTestCase {
  private var calendar: Calendar!

  override func setUp() {
    super.setUp()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Kyiv")!
  }

  private func local(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0)
    -> Date
  {
    calendar.date(
      from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
  }

  func testRangeFromMidday() {
    let from = local(2026, 9, 28, 15, 30)
    let range = StepsDays.queryRange(
      from: from, now: local(2026, 9, 28, 18), calendar: calendar)

    XCTAssertEqual(range?.dayStart, local(2026, 9, 28))
    XCTAssertEqual(range?.from, from)
    XCTAssertEqual(range?.end, local(2026, 9, 29))
  }

  func testRangeOverSeveralDays() {
    let range = StepsDays.queryRange(
      from: local(2026, 9, 21), now: local(2026, 9, 28, 9), calendar: calendar)

    XCTAssertEqual(range?.dayStart, local(2026, 9, 21))
    XCTAssertEqual(range?.end, local(2026, 9, 29))
  }

  func testRangeFromFutureIsNil() {
    let range = StepsDays.queryRange(
      from: local(2026, 9, 29), now: local(2026, 9, 28, 23, 59), calendar: calendar)

    XCTAssertNil(range)
  }

  func testDstDayHasItsOwnDate() {
    let start = local(2026, 10, 25)
    let next = calendar.date(byAdding: .day, value: 1, to: start)!

    XCTAssertEqual(StepsDays.localDateString(start, calendar: calendar), "2026-10-25")
    XCTAssertEqual(
      StepsDays.localDateString(local(2026, 10, 25, 23, 30), calendar: calendar), "2026-10-25")
    XCTAssertEqual(StepsDays.localDateString(next, calendar: calendar), "2026-10-26")
    XCTAssertEqual(next.timeIntervalSince(start), 25 * 3600)
  }

  func testTruncation() {
    XCTAssertEqual(StepsDays.truncatedSteps(0.9), 0)
    XCTAssertEqual(StepsDays.truncatedSteps(1234.99), 1234)
    XCTAssertEqual(StepsDays.truncatedSteps(0), 0)
  }
}

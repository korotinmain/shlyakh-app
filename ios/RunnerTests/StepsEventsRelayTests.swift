import XCTest

@testable import Runner

@MainActor
private final class FakeEvents: StepsEventsApiProtocol {
  var calls = 0
  var error: Error?

  func onStepsChanged() async throws {
    calls += 1
    if let error { throw error }
  }
}

@MainActor
final class StepsEventsRelayTests: XCTestCase {
  func testAttachedRelayCallsDartThenCompletes() async {
    let relay = StepsEventsRelay(timeout: 10)
    let events = FakeEvents()
    relay.attach(events)
    let done = expectation(description: "completion")

    relay.stepsChanged {
      XCTAssertEqual(events.calls, 1, "completion only after Dart was called")
      done.fulfill()
    }

    await fulfillment(of: [done], timeout: 1)
  }

  func testChangesBeforeAttachWaitForDart() async {
    let relay = StepsEventsRelay(timeout: 10)
    let events = FakeEvents()
    var completed = false
    let done = expectation(description: "completion after attach")

    relay.stepsChanged {
      completed = true
      done.fulfill()
    }
    XCTAssertFalse(completed)
    relay.attach(events)

    await fulfillment(of: [done], timeout: 1)
    XCTAssertEqual(events.calls, 1)
  }

  func testDartErrorStillCompletes() async {
    let relay = StepsEventsRelay(timeout: 10)
    let events = FakeEvents()
    events.error = PigeonError(code: "channel-error", message: nil, details: nil)
    relay.attach(events)
    let done = expectation(description: "completion despite the error")

    relay.stepsChanged { done.fulfill() }

    await fulfillment(of: [done], timeout: 1)
  }

  func testUnattachedRelayCompletesAfterTimeout() async {
    let relay = StepsEventsRelay(timeout: 0.05)
    let done = expectation(description: "completion after the timeout")

    relay.stepsChanged { done.fulfill() }

    await fulfillment(of: [done], timeout: 1)
  }
}

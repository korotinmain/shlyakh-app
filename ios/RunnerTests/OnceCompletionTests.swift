import XCTest

@testable import Runner

final class OnceCompletionTests: XCTestCase {
  func testOnceCompletionFiresOnce() {
    var calls = 0
    let once = OnceCompletion(timeout: 10, queue: .main) { calls += 1 }

    once.fire()
    once.fire()

    XCTAssertEqual(calls, 1)
  }

  func testOnceCompletionTimesOut() {
    var calls = 0
    let timedOut = expectation(description: "completion after the timeout")
    let once = OnceCompletion(timeout: 0.05, queue: .main) {
      calls += 1
      timedOut.fulfill()
    }

    wait(for: [timedOut], timeout: 1)
    once.fire()

    XCTAssertEqual(calls, 1)
  }

  func testOnceCompletionTimesOutWithoutAnOwner() {
    let timedOut = expectation(description: "completion although nothing keeps the object")
    _ = OnceCompletion(timeout: 0.05, queue: .main) { timedOut.fulfill() }

    wait(for: [timedOut], timeout: 1)
  }
}

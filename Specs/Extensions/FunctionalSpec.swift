//
//  FunctionalSpec.swift
//  Ello
//
//  Created by Colin Gray on 2/17/2015.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Ello
import XCTest


class FunctionalTests: XCTestCase {

    func wait(timeout: NSTimeInterval, _ description: String = "waiting", tests: ()->()) {
        let assertion = expectationWithDescription(description)
        let proc = Functional.Proc() {
            tests()
            assertion.fulfill()
        }
        let timer = NSTimer.scheduledTimerWithTimeInterval(timeout, target: proc, selector: "run", userInfo: nil, repeats: false)
    }

    func testTimes() {
        var counter = 0
        Functional.times(5) {
            counter += 1
        }
        XCTAssertEqual(counter, 5, "calls the block 5 times")
    }

    func testTimesWithIndex() {
        var counter = 0
        Functional.times(5) { index in
            counter += index
        }
        XCTAssertEqual(counter, 10, "calls the block 5 times, passing in the index")
    }

    func testAfter() {
        var called = 0
        var after = Functional.after(2) { called += 1 }
        XCTAssertEqual(called, 0, "still 0")
        after()
        XCTAssertEqual(called, 0, "still 0")
        after()
        XCTAssertEqual(called, 1, "gets called after(2)")
    }

    func testAfterCalledOnce() {
        var called = 0
        var after = Functional.after(2) { called += 1 }
        XCTAssertEqual(called, 0, "still 0")
        after()
        XCTAssertEqual(called, 0, "still 0")
        after()
        XCTAssertEqual(called, 1, "gets called after(2)")
        after()
        XCTAssertEqual(called, 1, "only gets called once")
    }

    func testAfterCalledImmediately() {
        var called = 0
        var after = Functional.after(0) { called += 1 }
        XCTAssertEqual(called, 1, "gets called immediately after(0)")
    }

    func testUntil() {
        var called = 0
        var until = Functional.until(2) { called += 1 }
        XCTAssertEqual(called, 0, "should get called until(2) (0)")
        until()
        XCTAssertEqual(called, 1, "should get called until(2) (1)")
        until()
        XCTAssertEqual(called, 2, "should get called until(2) (2)")
        until()
        XCTAssertEqual(called, 2, "should not be called until(2) (3)")
    }

    func testUntilNeverCalled() {
        var called = 0
        var until = Functional.until(0) { called += 1 }
        XCTAssertEqual(called, 0, "should not be called until(0) (0)")
        until()
        XCTAssertEqual(called, 0, "should not be called until(0) (1)")
    }

    func testOnce() {
        var called = 0
        var once = Functional.once { called += 1 }
        XCTAssertEqual(called, 0, "should not be called yet")
        once()
        XCTAssertEqual(called, 1, "should be called once")
        once()
        XCTAssertEqual(called, 1, "should be called again")
    }

    func testTimeout() {
        var called = 0
        var timeout = Functional.timeout(0.1) { called += 1 }
        XCTAssertEqual(called, 0, "value starts out as 0")
        wait(0.11) { error in
            XCTAssertEqual(called, 1, "value ends as 1")
        }
        waitForExpectationsWithTimeout(0.2) { error in }
    }

    func testTimeoutOnlyOnce() {
        var called = 0
        var timeout = Functional.timeout(0.1) { called += 1 }
        XCTAssertEqual(called, 0, "value starts out as 0")
        wait(0.11) {
            XCTAssertEqual(called, 1, "value ends as 1")
            timeout()
            XCTAssertEqual(called, 1, "value remains 1 after block is called")
        }
        waitForExpectationsWithTimeout(0.2) { error in }
    }

    func testTimeoutCalledImmediatelyAndOnlyOnce() {
        var called = 0
        var timeout = Functional.timeout(0.1) { called += 1 }
        XCTAssertEqual(called, 0, "value starts out as 0")
        timeout()
        XCTAssertEqual(called, 1, "value is 1 after block is called")
        timeout()
        XCTAssertEqual(called, 1, "value remains 1 after block is called")
        wait(0.11) { error in
            XCTAssertEqual(called, 1, "value remains 1 after timeout")
        }
        waitForExpectationsWithTimeout(0.2) { error in }
    }

    func testDebounce() {
        var called = 0
        var debounced = Functional.debounce(0.1) { called += 1 }
        XCTAssertEqual(called, 0, "value starts out as 0")

        debounced()
        XCTAssertEqual(called, 0, "value remains 0 after block is called")

        // reset the timer
        Functional.delay(0.05) { debounced() }
        wait(0.1, "value is still 0") {
            XCTAssertEqual(called, 0, "value is still 0, because it has debounced")
        }
        wait(0.3,  "value is 1") {
            XCTAssertEqual(called, 1, "value is 1, because timer expired")
        }
        waitForExpectationsWithTimeout(0.5) { error in }
    }

    func testThrottle() {
        var called = 0
        var throttled = Functional.throttle(0.1) { called += 1 }
        XCTAssertEqual(called, 0, "value starts out as 0")
        throttled()
        XCTAssertEqual(called, 0, "value is still 0")
        wait(0.11) {
            XCTAssertEqual(called, 1, "value is now 1")
            throttled()
            XCTAssertEqual(called, 1, "value is still 1")
        }
        wait(0.22) {
            XCTAssertEqual(called, 2, "value is now 2")
            throttled()
            XCTAssertEqual(called, 2, "value is still 2")
        }
        wait(0.33) {
            XCTAssertEqual(called, 3, "value is now 3")
        }
        wait(0.44) {
            XCTAssertEqual(called, 3, "value is still 3")
        }
        waitForExpectationsWithTimeout(0.5) { error in }
    }

    func testDelay() {
        var called = 0
        Functional.delay(0.1) { called += 1 }
        XCTAssertEqual(called, 0, "value starts out as 0")
        wait(0.11) {
            XCTAssertEqual(called, 1, "value is now 1")
        }
        waitForExpectationsWithTimeout(0.2) { error in }
    }

    func testCancelableDelay() {
        var called = 0
        let cancel = Functional.cancelableDelay(0.1) { called += 1 }
        XCTAssertEqual(called, 0, "value starts out as 0")
        wait(0.11) {
            XCTAssertEqual(called, 1, "value is now 1")
        }
        waitForExpectationsWithTimeout(0.2) { error in }
    }

    func testCancelableDelayIsCancelable() {
        var called = 0
        let cancel = Functional.cancelableDelay(0.1) { called += 1 }
        XCTAssertEqual(called, 0, "value starts out as 0")
        cancel()
        wait(0.11) {
            XCTAssertEqual(called, 0, "value is still 0")
        }
        waitForExpectationsWithTimeout(0.2) { error in }
    }

}

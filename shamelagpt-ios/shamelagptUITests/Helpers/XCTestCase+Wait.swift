//
//  XCTestCase+Wait.swift
//  shamelagptUITests
//
//  Small helpers to wait for UI stability without using arbitrary sleeps.
//

import XCTest

extension XCTestCase {
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        if !exists {
            let description = element.debugDescription.replacingOccurrences(of: "\n", with: " ")
            XCTFail("Element not found: \(description)", file: file, line: line)
        }
        return exists
    }

    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = expectation(for: predicate, evaluatedWith: element, handler: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        if result != .completed {
            XCTFail("Element did not disappear: \(element.debugDescription)", file: file, line: line)
        }
    }
}

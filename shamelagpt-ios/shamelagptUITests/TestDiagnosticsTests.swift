import XCTest

final class TestDiagnosticsTests: XCTestCase {
    func testDiagnosticEventDictionaryContainsRequiredFields() {
        let event = UITestDiagnosticEvent(
            testName: "exampleTest",
            platform: "ios_simulator:iPhone17,1|18.6",
            locale: "en",
            selectorOrTag: "sendButton",
            scenarioID: "offline",
            observedState: "not_found",
            failureClass: "selector_mismatch"
        )

        let dict = event.asDictionary()
        XCTAssertEqual(dict["test_name"], "exampleTest")
        XCTAssertEqual(dict["platform"], "ios_simulator:iPhone17,1|18.6")
        XCTAssertEqual(dict["locale"], "en")
        XCTAssertEqual(dict["selector_or_tag"], "sendButton")
        XCTAssertEqual(dict["scenario_id"], "offline")
        XCTAssertEqual(dict["observed_state"], "not_found")
        XCTAssertEqual(dict["failure_class"], "selector_mismatch")
    }
}

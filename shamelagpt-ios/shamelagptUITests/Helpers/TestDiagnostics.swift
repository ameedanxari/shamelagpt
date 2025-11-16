import Foundation
import XCTest

struct UITestDiagnosticEvent {
    let testName: String
    let platform: String
    let locale: String
    let selectorOrTag: String
    let scenarioID: String
    let observedState: String
    let failureClass: String

    func asDictionary() -> [String: String] {
        [
            "test_name": testName,
            "platform": platform,
            "locale": locale,
            "selector_or_tag": selectorOrTag,
            "scenario_id": scenarioID,
            "observed_state": observedState,
            "failure_class": failureClass
        ]
    }
}

enum UITestDiagnostics {
    static func emit(_ event: UITestDiagnosticEvent) {
        guard let data = try? JSONSerialization.data(withJSONObject: event.asDictionary(), options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8)
        else {
            print("UITEST_DIAGNOSTIC: failed_to_encode")
            return
        }
        print("UITEST_DIAGNOSTIC: \(json)")
    }

    static func currentPlatformLabel() -> String {
        let env = ProcessInfo.processInfo.environment
        let model = env["SIMULATOR_MODEL_IDENTIFIER"] ?? "unknown_model"
        let runtime = env["SIMULATOR_RUNTIME_VERSION"] ?? "unknown_runtime"
        return "ios_simulator:\(model)|\(runtime)"
    }
}

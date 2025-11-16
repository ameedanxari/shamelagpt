import Foundation
@testable import ShamelaGPT

enum MockScenarioID: String, CaseIterable {
    case success = "success"
    case http400 = "http_400"
    case http401 = "http_401"
    case http403 = "http_403"
    case http404 = "http_404"
    case http429 = "http_429"
    case http500 = "http_500"
    case timeout = "timeout"
    case offline = "offline"
}

/// Shared scenario matrix for iOS unit/integration tests.
enum MockScenarioMatrix {
    static func apply(_ scenario: MockScenarioID, to api: MockAPIClient) {
        api.shouldFail = false
        api.errorToThrow = NetworkError.noConnection

        switch scenario {
        case .success:
            api.shouldFail = false
        case .http400:
            fail(api, with: .httpError(statusCode: 400))
        case .http401:
            fail(api, with: .httpError(statusCode: 401))
        case .http403:
            fail(api, with: .httpError(statusCode: 403))
        case .http404:
            fail(api, with: .httpError(statusCode: 404))
        case .http429:
            fail(api, with: .httpError(statusCode: 429))
        case .http500:
            fail(api, with: .httpError(statusCode: 500))
        case .timeout:
            fail(api, with: .timeout)
        case .offline:
            fail(api, with: .noConnection)
        }
    }

    private static func fail(_ api: MockAPIClient, with error: NetworkError) {
        api.shouldFail = true
        api.errorToThrow = error
    }
}

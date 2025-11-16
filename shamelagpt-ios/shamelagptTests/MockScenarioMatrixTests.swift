import XCTest
@testable import ShamelaGPT

final class MockScenarioMatrixTests: XCTestCase {
    func testSuccessScenarioDoesNotFail() {
        let api = MockAPIClient()
        MockScenarioMatrix.apply(.success, to: api)

        XCTAssertFalse(api.shouldFail)
    }

    func testErrorScenariosMapToExpectedNetworkErrors() {
        let api = MockAPIClient()

        MockScenarioMatrix.apply(.http400, to: api)
        XCTAssertEqual(api.errorToThrow as? NetworkError, .httpError(statusCode: 400))

        MockScenarioMatrix.apply(.http401, to: api)
        XCTAssertEqual(api.errorToThrow as? NetworkError, .httpError(statusCode: 401))

        MockScenarioMatrix.apply(.http403, to: api)
        XCTAssertEqual(api.errorToThrow as? NetworkError, .httpError(statusCode: 403))

        MockScenarioMatrix.apply(.http404, to: api)
        XCTAssertEqual(api.errorToThrow as? NetworkError, .httpError(statusCode: 404))

        MockScenarioMatrix.apply(.http429, to: api)
        XCTAssertEqual(api.errorToThrow as? NetworkError, .httpError(statusCode: 429))

        MockScenarioMatrix.apply(.http500, to: api)
        XCTAssertEqual(api.errorToThrow as? NetworkError, .httpError(statusCode: 500))

        MockScenarioMatrix.apply(.timeout, to: api)
        XCTAssertEqual(api.errorToThrow as? NetworkError, .timeout)

        MockScenarioMatrix.apply(.offline, to: api)
        XCTAssertEqual(api.errorToThrow as? NetworkError, .noConnection)
    }
}

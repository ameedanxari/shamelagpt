//
//  AuthenticatedRouteGuardTests.swift
//  ShamelaGPTTests
//

import XCTest
@testable import ShamelaGPT

/// Guest is a distinct auth state, not "signed in with nothing in it". Dispatching an
/// authenticated route without a session produces a 403 — a *successful* HTTP exchange,
/// so it raises no exception, no 5xx and no crash report. These pin the guard that stops
/// such a request leaving the device.
///
/// The guard also calls `assertionFailure`, which traps in a Debug build. Tests therefore
/// only exercise routes through the thrown error, never by asserting on the trap.
final class AuthenticatedRouteGuardTests: XCTestCase {

    private var session: URLSession!

    override func setUpWithError() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.error = nil
    }

    override func tearDownWithError() throws {
        MockURLProtocol.requestHandler = nil
        session = nil
    }

    private func makeSUT(token: String?) -> APIClient {
        APIClient(
            baseURL: URL(string: "https://test.api.com")!,
            session: session,
            authTokenProvider: { token }
        )
    }

    /// The live bug this guard exists for: History sync calls the authenticated
    /// conversation list, and a guest reaching it got a quiet 403 rather than an error
    /// anyone would notice.
    func testAuthenticatedRouteIsNotDispatchedWithoutASession() async {
        var requestWasSent = false
        MockURLProtocol.requestHandler = { request in
            requestWasSent = true
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("[]".utf8))
        }

        do {
            _ = try await makeSUT(token: nil).listConversations()
            XCTFail("Expected the guard to refuse an authenticated route with no session")
        } catch {
            XCTAssertEqual(error as? NetworkError, .httpError(statusCode: 403))
        }

        XCTAssertFalse(requestWasSent, "the request must not reach the network at all")
    }

    func testAuthenticatedRouteIsDispatchedNormallyWithASession() async throws {
        var sentAuthorizationHeader: String?
        MockURLProtocol.requestHandler = { request in
            sentAuthorizationHeader = request.value(forHTTPHeaderField: "Authorization")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("[]".utf8))
        }

        _ = try await makeSUT(token: "valid-token").listConversations()

        XCTAssertEqual(sentAuthorizationHeader, "Bearer valid-token")
    }

    /// Login has to work before a token exists, so the allowlist must let it through.
    /// If this fails the guard has locked users out of signing in.
    func testUnauthenticatedRoutesStillWorkWithoutASession() async throws {
        let response = AuthResponse(token: "t", refreshToken: "r", expiresIn: "3600", user: [:])
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(response)

        MockURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let result = try await makeSUT(token: nil).login(LoginRequest(email: "a@b.com", password: "pw"))

        XCTAssertEqual(result.token, "t")
    }

    /// Guest chat is the counterpart of the route above: it is the endpoint a signed-out
    /// user is *supposed* to reach, so the guard must not block it either.
    func testGuestStreamRouteIsAllowedWithoutASession() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/guest/chat/stream")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
        }

        _ = try await makeSUT(token: nil).streamGuestMessage(
            ChatRequest(question: "Hello", threadId: nil, promptConfig: nil,
                        languagePreference: nil, customSystemPrompt: nil,
                        sessionId: "guest-1", enableThinking: false)
        )
    }
}

//
//  SessionExpiryTests.swift
//  ShamelaGPTTests
//

import XCTest
@testable import ShamelaGPT

/// `expires_in` is a string on the wire because it is forwarded from Firebase unchanged.
/// A parse failure used to fall back to 0, which stamped the expiry at the current instant
/// and made `token()` discard a token the server still considered valid — every request
/// after it would then go out with no Authorization header.
final class SessionExpiryTests: XCTestCase {

    private let suiteName = "SessionExpiryTests"
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
    }

    private func makeSUT() -> SessionManager {
        SessionManager(defaults: defaults, useKeychain: false)
    }

    func testZeroLifetimeDoesNotExpireTheTokenImmediately() {
        let sut = makeSUT()

        sut.saveSession(token: "t", refreshToken: "r", expiresInSeconds: 0)

        XCTAssertEqual(sut.token(), "t", "a zero lifetime must not discard a usable token")
        XCTAssertTrue(sut.isLoggedIn())
    }

    func testNegativeLifetimeDoesNotExpireTheTokenImmediately() {
        let sut = makeSUT()

        sut.saveSession(token: "t", refreshToken: "r", expiresInSeconds: -1)

        XCTAssertEqual(sut.token(), "t")
    }

    /// A session saved without a usable lifetime must not inherit the previous session's
    /// expiry, or a short-lived token could look long-lived.
    func testMissingLifetimeClearsAnExpiryLeftByAnEarlierSession() {
        let sut = makeSUT()
        sut.saveSession(token: "first", refreshToken: "r", expiresInSeconds: 3600)
        XCTAssertNotNil(defaults.object(forKey: "expires_at"))

        sut.saveSession(token: "second", refreshToken: "r", expiresInSeconds: nil)

        XCTAssertNil(defaults.object(forKey: "expires_at"),
                     "the stale expiry must be cleared, not left in place")
        XCTAssertEqual(sut.token(), "second")
    }

    func testPositiveLifetimeStillRecordsAnExpiry() {
        let sut = makeSUT()

        sut.saveSession(token: "t", refreshToken: "r", expiresInSeconds: 3600)

        let expiresAt = defaults.double(forKey: "expires_at")
        XCTAssertGreaterThan(expiresAt, Date().timeIntervalSince1970,
                             "a real lifetime must still produce a future expiry")
        XCTAssertEqual(sut.token(), "t")
    }

    func testAlreadyElapsedExpiryStillDiscardsTheToken() {
        let sut = makeSUT()
        sut.saveSession(token: "t", refreshToken: "r", expiresInSeconds: 1)
        // Rewrite the stored expiry into the past rather than sleeping.
        defaults.set(Date().timeIntervalSince1970 - 60, forKey: "expires_at")

        XCTAssertNil(sut.token(), "a genuinely elapsed expiry must still be honoured")
    }
}

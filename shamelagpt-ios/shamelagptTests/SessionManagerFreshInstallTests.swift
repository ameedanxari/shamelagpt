//
//  SessionManagerFreshInstallTests.swift
//  ShamelaGPTTests
//

import XCTest
@testable import ShamelaGPT

/// iOS keeps keychain entries when an app is deleted, so a reinstall used to come back
/// already signed in. UserDefaults is wiped on delete, which is what makes it usable as
/// a "this install is new" marker.
final class SessionManagerFreshInstallTests: XCTestCase {

    private let suiteName = "SessionManagerFreshInstallTests"
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
        // useKeychain: false routes storage through the same defaults suite, so the test
        // stays deterministic and never touches the real keychain.
        SessionManager(defaults: defaults, useKeychain: false)
    }

    func testFreshInstallDiscardsSessionLeftBehindByPreviousInstall() {
        let sut = makeSUT()
        sut.saveSession(token: "leftover", refreshToken: "leftover_refresh", expiresInSeconds: 3600)
        XCTAssertTrue(sut.isLoggedIn(), "precondition: a session survives the uninstall")

        // Marker absent => this is a fresh install.
        sut.clearKeychainResidueIfFreshInstall()

        XCTAssertFalse(sut.isLoggedIn(), "a fresh install must land on the login screen")
        XCTAssertNil(sut.refreshToken(), "the refresh token must not survive a reinstall")
    }

    func testSubsequentLaunchKeepsSession() {
        let sut = makeSUT()
        // First launch consumes the fresh-install branch and drops the marker.
        sut.clearKeychainResidueIfFreshInstall()

        sut.saveSession(token: "current", refreshToken: "current_refresh", expiresInSeconds: 3600)
        sut.clearKeychainResidueIfFreshInstall()

        XCTAssertTrue(sut.isLoggedIn(), "an ordinary relaunch must not sign the user out")
        XCTAssertEqual(sut.token(), "current")
    }

    func testFreshInstallPurgesLegacyCredentialsFromOlderBuilds() {
        // Simulate residue written by a build that persisted email/password.
        defaults.set("user@example.com", forKey: "mock_keychain_auth_email")
        defaults.set("hunter2", forKey: "mock_keychain_auth_password")

        makeSUT().clearKeychainResidueIfFreshInstall()

        XCTAssertNil(defaults.string(forKey: "mock_keychain_auth_password"))
        XCTAssertNil(defaults.string(forKey: "mock_keychain_auth_email"))
    }
}

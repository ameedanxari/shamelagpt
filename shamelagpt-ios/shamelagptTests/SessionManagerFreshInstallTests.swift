//
//  SessionManagerFreshInstallTests.swift
//  ShamelaGPTTests
//

import XCTest
@testable import ShamelaGPT

/// iOS keeps keychain entries when an app is deleted, so a reinstall used to come back
/// already signed in. UserDefaults is wiped on delete, which is what makes it usable as
/// evidence that an install is new.
///
/// With `useKeychain: false` both stores live in the same defaults suite, keychain items
/// behind a `mock_keychain_` prefix. Deleting only the unprefixed keys therefore models
/// an uninstall: UserDefaults gone, keychain surviving.
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
        SessionManager(defaults: defaults, useKeychain: false)
    }

    /// Drops every non-keychain key, the way deleting the app drops its container.
    private func simulateUninstallKeepingKeychain() {
        for key in defaults.dictionaryRepresentation().keys where !key.hasPrefix("mock_keychain_") {
            defaults.removeObject(forKey: key)
        }
    }

    func testFreshInstallDiscardsSessionLeftBehindByPreviousInstall() {
        let sut = makeSUT()
        sut.saveSession(token: "leftover", refreshToken: "leftover_refresh", expiresInSeconds: 3600)
        simulateUninstallKeepingKeychain()
        XCTAssertNotNil(defaults.string(forKey: "mock_keychain_id_token"),
                        "precondition: the keychain survives an uninstall")

        sut.clearKeychainResidueIfFreshInstall()

        XCTAssertFalse(sut.isLoggedIn(), "a fresh install must land on the login screen")
        XCTAssertNil(sut.refreshToken(), "the refresh token must not survive a reinstall")
    }

    /// The marker ships for the first time in this build, so an upgrading install is also
    /// missing it. Signing those users out would be a regression, not a fix.
    func testUpgradeInPlaceFromABuildWithoutTheMarkerKeepsSession() {
        let sut = makeSUT()
        sut.saveSession(token: "current", refreshToken: "current_refresh", expiresInSeconds: 3600)
        XCTAssertFalse(defaults.bool(forKey: "install_marker"),
                       "precondition: pre-upgrade installs have no marker")

        sut.clearKeychainResidueIfFreshInstall()

        XCTAssertTrue(sut.isLoggedIn(), "an in-place upgrade must not sign the user out")
        XCTAssertEqual(sut.token(), "current")
        XCTAssertTrue(defaults.bool(forKey: "install_marker"), "the marker is written either way")
    }

    func testSubsequentLaunchKeepsSession() {
        let sut = makeSUT()
        sut.clearKeychainResidueIfFreshInstall()

        sut.saveSession(token: "current", refreshToken: "current_refresh", expiresInSeconds: 3600)
        sut.clearKeychainResidueIfFreshInstall()

        XCTAssertTrue(sut.isLoggedIn(), "an ordinary relaunch must not sign the user out")
        XCTAssertEqual(sut.token(), "current")
    }

    func testFreshInstallPurgesLegacyCredentialsFromOlderBuilds() {
        // Residue written by a build that persisted email/password, with the app's own
        // UserDefaults gone because the user deleted the app.
        defaults.set("user@example.com", forKey: "mock_keychain_auth_email")
        defaults.set("hunter2", forKey: "mock_keychain_auth_password")

        makeSUT().clearKeychainResidueIfFreshInstall()

        XCTAssertNil(defaults.string(forKey: "mock_keychain_auth_password"))
        XCTAssertNil(defaults.string(forKey: "mock_keychain_auth_email"))
    }

    /// A logged-out user reinstalling has neither store populated; the purge must be a
    /// no-op rather than throwing or leaving the marker unset.
    func testFreshInstallWithNothingStoredIsHarmless() {
        let sut = makeSUT()

        sut.clearKeychainResidueIfFreshInstall()

        XCTAssertFalse(sut.isLoggedIn())
        XCTAssertTrue(defaults.bool(forKey: "install_marker"))
    }
}

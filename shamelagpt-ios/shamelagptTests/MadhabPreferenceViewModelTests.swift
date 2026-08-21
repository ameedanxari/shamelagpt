//
//  MadhabPreferenceViewModelTests.swift
//  shamelagptTests
//
//  Covers the school-of-thought preference: mapping the API response, writing a
//  selection through to the server, and refusing to show a school the server
//  never accepted.
//

import XCTest
@testable import ShamelaGPT

@MainActor
final class MadhabPreferenceViewModelTests: XCTestCase {

    var sut: MadhabPreferenceViewModel!
    var mockAuthRepo: MockAuthRepository!

    override func setUp() {
        super.setUp()
        mockAuthRepo = MockAuthRepository()
        mockAuthRepo.mockIsLoggedIn = true
        sut = MadhabPreferenceViewModel(authRepository: mockAuthRepo)
    }

    override func tearDown() {
        sut = nil
        mockAuthRepo = nil
        super.tearDown()
    }

    // MARK: - Mapping

    func testNormalizedMapsKnownSlugs() {
        XCTAssertEqual(MadhabPreference.normalized("hanafi"), .hanafi)
        XCTAssertEqual(MadhabPreference.normalized("maliki"), .maliki)
        XCTAssertEqual(MadhabPreference.normalized("shafii"), .shafii)
        XCTAssertEqual(MadhabPreference.normalized("hanbali"), .hanbali)
        XCTAssertEqual(MadhabPreference.normalized("all"), .all)
    }

    func testNormalizedIsCaseAndWhitespaceInsensitive() {
        XCTAssertEqual(MadhabPreference.normalized("  Hanafi "), .hanafi)
        XCTAssertEqual(MadhabPreference.normalized("SHAFII"), .shafii)
    }

    func testNormalizedFallsBackToAllForUnknownOrMissingValues() {
        // The backend default is "all", so an unrecognised value must never
        // leave the picker with nothing selected.
        XCTAssertEqual(MadhabPreference.normalized("jafari"), .all)
        XCTAssertEqual(MadhabPreference.normalized(""), .all)
        XCTAssertEqual(MadhabPreference.normalized(nil), .all)
    }

    func testEveryCaseHasDistinctLocalizationKeys() {
        let titleKeys = Set(MadhabPreference.allCases.map(\.titleKey))
        let arabicKeys = Set(MadhabPreference.allCases.map(\.arabicNameKey))
        let descriptionKeys = Set(MadhabPreference.allCases.map(\.descriptionKey))

        XCTAssertEqual(titleKeys.count, MadhabPreference.allCases.count)
        XCTAssertEqual(arabicKeys.count, MadhabPreference.allCases.count)
        XCTAssertEqual(descriptionKeys.count, MadhabPreference.allCases.count)
    }

    // MARK: - Load

    func testLoadAdoptsServerValue() async {
        // Given a value set elsewhere (e.g. on the web)
        mockAuthRepo.mockMadhabPreferenceResponse = MadhabPreferenceResponse(
            madhabPreference: "shafii",
            madhabName: "Shafi'i"
        )

        // When
        await sut.load()

        // Then
        XCTAssertEqual(sut.selection, .shafii)
        XCTAssertEqual(mockAuthRepo.getMadhabPreferenceCallCount, 1)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadMapsUnknownServerValueToAll() async {
        // Given
        mockAuthRepo.mockMadhabPreferenceResponse = MadhabPreferenceResponse(
            madhabPreference: "zahiri",
            madhabName: nil
        )

        // When
        await sut.load()

        // Then
        XCTAssertEqual(sut.selection, .all)
    }

    func testLoadIsSkippedForGuests() async {
        // Given
        mockAuthRepo.mockIsLoggedIn = false

        // When
        await sut.load()

        // Then — the preference is per-account, so a guest must not hit the API
        XCTAssertEqual(mockAuthRepo.getMadhabPreferenceCallCount, 0)
        XCTAssertEqual(sut.selection, .all)
    }

    func testLoadDoesNotRefetchUnlessForced() async {
        // When
        await sut.load()
        await sut.load()

        // Then
        XCTAssertEqual(mockAuthRepo.getMadhabPreferenceCallCount, 1)

        // And when forced
        await sut.load(force: true)
        XCTAssertEqual(mockAuthRepo.getMadhabPreferenceCallCount, 2)
    }

    func testLoadFailureSurfacesErrorAndKeepsDefaultSelection() async {
        // Given
        mockAuthRepo.madhabErrorToThrow = NetworkError.noConnection

        // When
        await sut.load()

        // Then
        XCTAssertEqual(sut.selection, .all)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Select

    func testSelectPersistsToServerAndAdoptsEchoedValue() async {
        // When
        await sut.select(.hanbali)

        // Then
        XCTAssertEqual(mockAuthRepo.setMadhabPreferenceCallCount, 1)
        XCTAssertEqual(mockAuthRepo.lastSetMadhabPreferenceRequest?.madhabPreference, "hanbali")
        XCTAssertEqual(sut.selection, .hanbali)
        XCTAssertNil(sut.errorMessage)
    }

    func testSelectAdoptsServerEchoRatherThanTheRequestedValue() async {
        // Given a server that coerces the request to something else
        mockAuthRepo.mockMadhabPreferenceResponse = MadhabPreferenceResponse(
            madhabPreference: "all",
            madhabName: "All Schools"
        )
        let coercingRepo = CoercingMadhabAuthRepository(coercedValue: "all")
        sut = MadhabPreferenceViewModel(authRepository: coercingRepo)

        // When
        await sut.select(.maliki)

        // Then — the server is authoritative
        XCTAssertEqual(sut.selection, .all)
    }

    func testSelectIsANoOpWhenAlreadySelected() async {
        // When
        await sut.select(.all)

        // Then
        XCTAssertEqual(mockAuthRepo.setMadhabPreferenceCallCount, 0)
    }

    func testSelectIsSkippedForGuests() async {
        // Given
        mockAuthRepo.mockIsLoggedIn = false

        // When
        await sut.select(.hanafi)

        // Then
        XCTAssertEqual(mockAuthRepo.setMadhabPreferenceCallCount, 0)
        XCTAssertEqual(sut.selection, .all)
    }

    /// The core failure requirement: a rejected PUT must not leave the picker
    /// showing a school the server never accepted.
    func testFailedSelectLeavesPreviousSelectionIntact() async {
        // Given a preference already established on the server
        mockAuthRepo.mockMadhabPreferenceResponse = MadhabPreferenceResponse(
            madhabPreference: "hanafi",
            madhabName: "Hanafi"
        )
        await sut.load()
        XCTAssertEqual(sut.selection, .hanafi)

        // When the write fails
        mockAuthRepo.madhabErrorToThrow = NetworkError.serverError(500)
        await sut.select(.maliki)

        // Then the UI still shows what the server actually has
        XCTAssertEqual(sut.selection, .hanafi)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isSaving)
    }

    func testSuccessfulSelectAfterAFailureClearsTheError() async {
        // Given
        mockAuthRepo.madhabErrorToThrow = NetworkError.noConnection
        await sut.select(.hanafi)
        XCTAssertNotNil(sut.errorMessage)

        // When
        mockAuthRepo.madhabErrorToThrow = nil
        await sut.select(.hanafi)

        // Then
        XCTAssertEqual(sut.selection, .hanafi)
        XCTAssertNil(sut.errorMessage)
    }

    func testCanEditPreferenceReflectsAuthState() {
        mockAuthRepo.mockIsLoggedIn = true
        XCTAssertTrue(sut.canEditPreference)

        mockAuthRepo.mockIsLoggedIn = false
        XCTAssertFalse(sut.canEditPreference)

        let unresolved = MadhabPreferenceViewModel(authRepository: nil)
        XCTAssertFalse(unresolved.canEditPreference)
    }
}

/// Stands in for a backend that stores something other than what was asked for
/// (e.g. an unrecognised slug coerced back to the default).
private final class CoercingMadhabAuthRepository: MockAuthRepository {
    private let coercedValue: String

    init(coercedValue: String) {
        self.coercedValue = coercedValue
        super.init()
        mockIsLoggedIn = true
    }

    override func setMadhabPreference(_ request: MadhabPreferenceRequest) async throws -> MadhabPreferenceResponse {
        MadhabPreferenceResponse(madhabPreference: coercedValue, madhabName: coercedValue)
    }
}

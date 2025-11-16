import XCTest
import Combine
@testable import ShamelaGPT

@MainActor
final class SettingsViewModelTests: XCTestCase {
    
    var sut: SettingsViewModel!
    var mockPreferencesRepo: MockPreferencesRepository!
    var mockAuthRepo: MockAuthRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockPreferencesRepo = MockPreferencesRepository()
        mockAuthRepo = MockAuthRepository()
        sut = SettingsViewModel(preferencesRepository: mockPreferencesRepo, authRepository: mockAuthRepo)
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        mockPreferencesRepo = nil
        mockAuthRepo = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testLoadPreferencesSuccess() async {
        // Given
        mockPreferencesRepo.mockPreferences = UserPreferencesModel(
            languagePreference: "en",
            customSystemPrompt: "Test Prompt",
            responsePreferences: ResponsePreferencesRequest(length: "short", style: "academic", focus: "practical")
        )
        
        // When
        await sut.loadPreferences()
        
        // Then
        XCTAssertEqual(sut.customPrompt, "Test Prompt")
        XCTAssertEqual(sut.lengthPref, "short")
        XCTAssertEqual(sut.stylePref, "academic")
        XCTAssertEqual(sut.focusPref, "practical")
        XCTAssertEqual(mockPreferencesRepo.fetchCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testLoadPreferencesFailure() async {
        // Given
        mockPreferencesRepo.shouldFail = true
        mockPreferencesRepo.errorToThrow = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Fetch failed"])
        
        // When
        await sut.loadPreferences()
        
        // Then
        XCTAssertEqual(mockPreferencesRepo.fetchCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.error, NSLocalizedString(LocalizationKeys.preferencesLoadFailed, comment: ""))
    }
    
    func testSavePreferences() async {
        // Given
        sut.customPrompt = "New Prompt"
        sut.lengthPref = "detailed"
        
        // When
        await sut.savePreferences()
        
        // Then
        XCTAssertEqual(mockPreferencesRepo.updateCallCount, 1)
        XCTAssertEqual(mockPreferencesRepo.mockPreferences.customSystemPrompt, "New Prompt")
        XCTAssertEqual(mockPreferencesRepo.mockPreferences.responsePreferences?.length, "detailed")
    }
    
    func testDeleteAccount() async {
        // Given
        let expectation = XCTestExpectation(description: "Delete success")
        
        // When
        await sut.deleteAccount {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(mockAuthRepo.deleteCurrentUserCallCount, 1)
        XCTAssertFalse(sut.isDeletingAccount)
        XCTAssertNil(sut.deleteAccountError)
    }
}

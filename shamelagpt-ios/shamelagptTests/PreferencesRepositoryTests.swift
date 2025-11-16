import XCTest
@testable import ShamelaGPT

final class PreferencesRepositoryTests: XCTestCase {
    
    var sut: PreferencesRepositoryImpl!
    var mockAPIClient: MockAPIClient!
    var testDefaults: UserDefaults!
    let cacheKey = "cached_user_preferences"
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        testDefaults = UserDefaults(suiteName: "PreferencesRepositoryTests")
        testDefaults.removePersistentDomain(forName: "PreferencesRepositoryTests")
        sut = PreferencesRepositoryImpl(apiClient: mockAPIClient, userDefaults: testDefaults)
    }
    
    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "PreferencesRepositoryTests")
        mockAPIClient = nil
        sut = nil
        super.tearDown()
    }
    
    func testFetchPreferencesFromAPIWhenNoCache() async throws {
        // Given
        let expectedResponse = UserPreferencesRequest(
            languagePreference: "en",
            customSystemPrompt: "Test Prompt",
            responsePreferences: ResponsePreferencesRequest(length: "short", style: "academic", focus: "practical")
        )
        mockAPIClient.mockUserPreferencesResponse = expectedResponse
        
        // When
        let result = try await sut.fetchPreferences()
        
        // Then
        XCTAssertEqual(result.customSystemPrompt, "Test Prompt")
        XCTAssertEqual(mockAPIClient.getPreferencesCallCount, 1)
        
        // Verify cache was updated
        XCTAssertNotNil(testDefaults.data(forKey: cacheKey))
    }
    
    func testFetchPreferencesFromCacheImmediately() async throws {
        // Given
        let cachedResponse = UserPreferencesRequest(
            languagePreference: "ar",
            customSystemPrompt: "Cached Prompt",
            responsePreferences: nil
        )
        let data = try JSONEncoder().encode(cachedResponse)
        testDefaults.set(data, forKey: cacheKey)
        
        // When
        let result = try await sut.fetchPreferences()
        
        // Then
        XCTAssertEqual(result.customSystemPrompt, "Cached Prompt")
        // API call is fired-and-forget, so we don't necessarily wait for it in this test 
        // but we verify the cache hit.
    }
    
    func testUpdatePreferences() async throws {
        // Given
        let model = UserPreferencesModel(
            languagePreference: "en",
            customSystemPrompt: "New Prompt",
            responsePreferences: nil
        )
        
        // When
        try await sut.updatePreferences(model)
        
        // Then
        XCTAssertEqual(mockAPIClient.setPreferencesCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastSetPreferencesRequest?.customSystemPrompt, "New Prompt")
        
        // Verify cache was updated
        XCTAssertNotNil(testDefaults.data(forKey: cacheKey))
    }
}

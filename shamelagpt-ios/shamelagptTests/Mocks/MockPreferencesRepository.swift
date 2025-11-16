import Foundation
@testable import ShamelaGPT

class MockPreferencesRepository: PreferencesRepository {
    var shouldFail = false
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: nil)
    var fetchCallCount = 0
    var updateCallCount = 0
    
    var mockPreferences = UserPreferencesModel(languagePreference: "en", customSystemPrompt: "", responsePreferences: nil)
    
    func fetchPreferences() async throws -> UserPreferencesModel {
        fetchCallCount += 1
        if shouldFail { throw errorToThrow }
        return mockPreferences
    }
    
    func updatePreferences(_ prefs: UserPreferencesModel) async throws {
        updateCallCount += 1
        if shouldFail { throw errorToThrow }
        mockPreferences = prefs
    }
}

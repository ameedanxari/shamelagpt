import Foundation
import Combine
@testable import ShamelaGPT

class MockAuthRepository: AuthRepository {
    var shouldFail = false
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: nil)
    
    // Call tracking
    var signupCallCount = 0
    var loginCallCount = 0
    var forgotPasswordCallCount = 0
    var googleSignInCallCount = 0
    var appleSignInCallCount = 0
    var logoutCallCount = 0
    var isLoggedInCallCount = 0
    var refreshTokenCallCount = 0
    var deleteCurrentUserCallCount = 0
    var getModePreferenceCallCount = 0
    var setModePreferenceCallCount = 0
    
    // Stub Results
    var mockAuthResponse = AuthResponse(token: "mock-token", refreshToken: "mock-refresh", expiresIn: "3600", user: ["uid": AnyCodable("123")])
    var mockUserResponse = UserResponse(id: "123", firebaseUid: "fb123", email: "test@example.com", displayName: "Test User", createdAt: "", updatedAt: "", lastLogin: "")
    var mockIsLoggedIn = false
    var mockModePreferenceResponse = ModePreferenceResponse(modePreference: 1, modeName: "research")
    
    func signup(request: SignupRequest) async throws -> AuthResponse {
        signupCallCount += 1
        if shouldFail { throw errorToThrow }
        return mockAuthResponse
    }
    
    func login(request: LoginRequest) async throws -> AuthResponse {
        loginCallCount += 1
        if shouldFail { throw errorToThrow }
        return mockAuthResponse
    }
    
    func forgotPassword(email: String) async throws {
        forgotPasswordCallCount += 1
        if shouldFail { throw errorToThrow }
    }
    
    func googleSignIn(request: GoogleSignInRequest) async throws -> AuthResponse {
        googleSignInCallCount += 1
        if shouldFail { throw errorToThrow }
        return mockAuthResponse
    }

    func appleSignIn(request: AppleSignInRequest) async throws -> AuthResponse {
        appleSignInCallCount += 1
        if shouldFail { throw errorToThrow }
        return mockAuthResponse
    }
    
    func refreshToken(request: RefreshTokenRequest) async throws -> AuthResponse {
        refreshTokenCallCount += 1
        if shouldFail { throw errorToThrow }
        return mockAuthResponse
    }
    
    func getCurrentUser() async throws -> UserResponse {
        if shouldFail { throw errorToThrow }
        return mockUserResponse
    }
    
    func updateCurrentUser(request: UpdateUserRequest) async throws -> UserResponse {
        if shouldFail { throw errorToThrow }
        return mockUserResponse
    }
    
    func deleteCurrentUser() async throws {
        deleteCurrentUserCallCount += 1
        if shouldFail { throw errorToThrow }
    }
    
    func verifyToken() async throws {
        if shouldFail { throw errorToThrow }
    }
    
    func getPreferences() async throws -> UserPreferencesRequest {
        if shouldFail { throw errorToThrow }
        return UserPreferencesRequest(languagePreference: "en", customSystemPrompt: nil, responsePreferences: nil)
    }
    
    func setPreferences(_ request: UserPreferencesRequest) async throws {
        if shouldFail { throw errorToThrow }
    }

    func getModePreference() async throws -> ModePreferenceResponse {
        getModePreferenceCallCount += 1
        if shouldFail { throw errorToThrow }
        return mockModePreferenceResponse
    }

    func setModePreference(_ request: ModePreferenceRequest) async throws -> ModePreferenceResponse {
        setModePreferenceCallCount += 1
        if shouldFail { throw errorToThrow }
        mockModePreferenceResponse = ModePreferenceResponse(
            modePreference: request.modePreference,
            modeName: request.modePreference == 2 ? "fact_check" : "research"
        )
        return mockModePreferenceResponse
    }
    
    func logout() {
        logoutCallCount += 1
        mockIsLoggedIn = false
    }
    
    func token() -> String? {
        return "mock-token"
    }
    
    func isLoggedIn() -> Bool {
        isLoggedInCallCount += 1
        return mockIsLoggedIn
    }
}

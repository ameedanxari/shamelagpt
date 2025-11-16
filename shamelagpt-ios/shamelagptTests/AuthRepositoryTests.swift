import XCTest
@testable import ShamelaGPT

final class AuthRepositoryTests: XCTestCase {
    
    var sut: AuthRepositoryImpl!
    var apiClient: APIClient!
    var mockSession: URLSession!
    var sessionManager: SessionManager!
    
    override func setUpWithError() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        
        // Use a test UserDefaults domain to avoid messing with app data
        let defaults = UserDefaults(suiteName: "AuthRepositoryTests")!
        defaults.removePersistentDomain(forName: "AuthRepositoryTests")
        sessionManager = SessionManager(defaults: defaults)
        
        // Clear Keychain
        sessionManager.clearSession()
        sessionManager.clearCredentials()
        
        apiClient = APIClient(baseURL: URL(string: "https://test.api.com")!, session: mockSession)
        sut = AuthRepositoryImpl(apiClient: apiClient, sessionManager: sessionManager)
        
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.error = nil
    }
    
    override func tearDownWithError() throws {
        sessionManager.clearSession()
        sessionManager.clearCredentials()
        UserDefaults(suiteName: "AuthRepositoryTests")?.removePersistentDomain(forName: "AuthRepositoryTests")
        
        sut = nil
        apiClient = nil
        mockSession = nil
        sessionManager = nil
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.error = nil
    }
    
    func testLoginSuccess() async throws {
        // Given
        let expectedResponse = AuthResponse(token: "token123", refreshToken: "refresh123", expiresIn: "3600", user: ["email": AnyCodable("test@example.com")])
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/auth/login")
            XCTAssertEqual(request.httpMethod, "POST")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseData)
        }
        
        // When
        let result = try await sut.login(request: LoginRequest(email: "test@example.com", password: "password"))
        
        // Then
        XCTAssertEqual(result.token, "token123")
        XCTAssertTrue(sut.isLoggedIn())
        XCTAssertEqual(sut.token(), "token123")
    }
    
    func testSignupSuccess() async throws {
        // Given
        let expectedResponse = AuthResponse(token: "tokenXYZ", refreshToken: "refreshXYZ", expiresIn: "3600", user: ["email": AnyCodable("new@example.com")])
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/auth/signup")
            XCTAssertEqual(request.httpMethod, "POST")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseData)
        }
        
        // When
        let result = try await sut.signup(request: SignupRequest(email: "new@example.com", password: "password", displayName: "New User"))
        
        // Then
        XCTAssertEqual(result.token, "tokenXYZ")
        XCTAssertTrue(sut.isLoggedIn())
    }
    
    func testLogout() {
        // Given
        sessionManager.saveSession(token: "token", refreshToken: nil, expiresInSeconds: nil)
        XCTAssertTrue(sut.isLoggedIn())
        
        // When
        sut.logout()
        
        // Then
        XCTAssertFalse(sut.isLoggedIn())
        XCTAssertNil(sut.token())
    }
    
    func testGoogleSignIn() async throws {
        // Given
        let expectedResponse = AuthResponse(token: "gToken", refreshToken: "gRefresh", expiresIn: "3600", user: ["email": AnyCodable("g@example.com")])
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/auth/google")
            XCTAssertEqual(request.httpMethod, "POST")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseData)
        }
        
        // When
        let result = try await sut.googleSignIn(request: GoogleSignInRequest(idToken: "id_token_google"))
        
        // Then
        XCTAssertEqual(result.token, "gToken")
        XCTAssertTrue(sut.isLoggedIn())
    }
}

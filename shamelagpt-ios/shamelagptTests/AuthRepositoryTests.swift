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
        // The refresh token is enough to restore a session; keeping the password would
        // let the app silently re-authenticate and would outlive a server-side logout.
        XCTAssertNil(KeychainHelper.get("auth_password"), "login must not persist the password")
        XCTAssertNil(KeychainHelper.get("auth_email"), "login must not persist the email")
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

    func testAppleSignIn() async throws {
        // Given
        let expectedResponse = AuthResponse(token: "aToken", refreshToken: "aRefresh", expiresIn: "3600", user: ["email": AnyCodable("a@example.com")])
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(expectedResponse)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/auth/apple")
            XCTAssertEqual(request.httpMethod, "POST")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseData)
        }

        // When
        let result = try await sut.appleSignIn(request: AppleSignInRequest(idToken: "id_token_apple"))

        // Then
        XCTAssertEqual(result.token, "aToken")
        XCTAssertTrue(sut.isLoggedIn())
    }

    func testGetModePreferenceSuccess() async throws {
        // Given
        let expectedResponse = ModePreferenceResponse(modePreference: 2, modeName: "fact_check")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(expectedResponse)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/auth/me/mode")
            XCTAssertEqual(request.httpMethod, "GET")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseData)
        }

        // When
        let result = try await sut.getModePreference()

        // Then
        XCTAssertEqual(result.modePreference, 2)
        XCTAssertEqual(result.modeName, "fact_check")
    }

    func testSetModePreferenceSuccess() async throws {
        // Given
        let requestPayload = ModePreferenceRequest(modePreference: 1)
        let expectedResponse = ModePreferenceResponse(modePreference: 1, modeName: "research")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(expectedResponse)
        var capturedBody: Data?

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/auth/me/mode")
            XCTAssertEqual(request.httpMethod, "PUT")
            // URLSession hands a URLProtocol the body as `httpBodyStream`, not
            // `httpBody` — reading only `httpBody` here always yielded nil, so
            // this test could never have passed. APIClientTests already drains
            // the stream the same way.
            capturedBody = Self.requestBody(from: request)
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, responseData)
        }

        // When
        let result = try await sut.setModePreference(requestPayload)

        // Then
        XCTAssertEqual(result.modePreference, 1)
        XCTAssertEqual(result.modeName, "research")
        // XCTUnwrap, not `capturedBody!`. XCTAssertNotNil records a failure but
        // does NOT stop execution, so the force-unwrap on the next line ran
        // anyway when the body was nil and took the whole test PROCESS down
        // with a fatal error — which XCTest reports as "unexpected exit", losing
        // the results of every test that had not run yet. Unwrapping this way
        // fails just this test instead.
        let body = try XCTUnwrap(capturedBody)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["mode_preference"] as? Int, 1)
    }

    /// Reads a request body regardless of whether URLSession delivered it as
    /// `httpBody` or (as it does for a URLProtocol) an `httpBodyStream`.
    private static func requestBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }
        stream.open()
        defer { stream.close() }
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        var data = Data()
        while true {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 { data.append(buffer, count: read) } else { break }
        }
        return data
    }
}

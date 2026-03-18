import XCTest
import Combine
@testable import ShamelaGPT

@MainActor
final class AuthViewModelTests: XCTestCase {
    
    var sut: AuthViewModel!
    var mockRepository: MockAuthRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAuthRepository()
        sut = AuthViewModel(authRepository: mockRepository)
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertTrue(sut.email.isEmpty)
        XCTAssertTrue(sut.password.isEmpty)
        XCTAssertTrue(sut.isLoginMode)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testToggleMode() {
        sut.toggleMode()
        XCTAssertFalse(sut.isLoginMode)
        
        sut.toggleMode()
        XCTAssertTrue(sut.isLoginMode)
    }
    
    func testLoginSuccess() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.isLoginMode = true
        
        let expectation = XCTestExpectation(description: "Login success callback")
        
        // When
        sut.authenticate {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(mockRepository.loginCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testSignupSuccess() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.displayName = "Test User"
        sut.isLoginMode = false
        
        let expectation = XCTestExpectation(description: "Signup success callback")
        
        // When
        sut.authenticate {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(mockRepository.signupCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testAuthenticationFailure() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server exploded"])
        
        let expectation = XCTestExpectation(description: "Should fail")
        expectation.isInverted = true // Should NOT be called
        
        // When
        sut.authenticate {
            expectation.fulfill()
        }
        
        // Wait briefly for the async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockRepository.loginCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        let expectedMessage = UserErrorFormatter.format(
            messageKey: LocalizationKeys.somethingWentWrong,
            code: "E-APP-000"
        )
        XCTAssertEqual(sut.errorMessage, expectedMessage)
        
        await fulfillment(of: [expectation], timeout: 0.1)
    }

    func testLoginInvalidCredentialsShowsFriendlyMessage() async {
        sut.email = "test@example.com"
        sut.password = "wrong-password"
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = NetworkError.httpError(statusCode: 401)

        let expectation = XCTestExpectation(description: "Should fail")
        expectation.isInverted = true

        sut.authenticate {
            expectation.fulfill()
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockRepository.loginCallCount, 1)
        XCTAssertEqual(sut.errorMessage, LocalizationKeys.authInvalidCredentials.localized)

        await fulfillment(of: [expectation], timeout: 0.1)
    }
    
    func testForgotPassword() async {
        // Given
        sut.email = "test@example.com"
        
        // When
        sut.forgotPassword()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockRepository.forgotPasswordCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testGoogleSignInSuccess() async {
        let expectation = XCTestExpectation(description: "Google Sign-In success callback")

        sut.googleSignIn(idToken: "google-id-token") {
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(mockRepository.googleSignInCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testGoogleSignInFailureShowsUserFacingError() async {
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = NSError(
            domain: "test",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Google failed"]
        )
        let expectation = XCTestExpectation(description: "Google Sign-In should fail")
        expectation.isInverted = true

        sut.googleSignIn(idToken: "google-id-token") {
            expectation.fulfill()
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockRepository.googleSignInCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        let expectedMessage = UserErrorFormatter.format(
            messageKey: LocalizationKeys.somethingWentWrong,
            code: "E-APP-000"
        )
        XCTAssertEqual(sut.errorMessage, expectedMessage)

        await fulfillment(of: [expectation], timeout: 0.1)
    }

    func testAppleSignInSuccess() async {
        let expectation = XCTestExpectation(description: "Apple Sign-In success callback")

        sut.appleSignIn(idToken: "apple-id-token") {
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(mockRepository.appleSignInCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testAppleSignInFailureShowsUserFacingError() async {
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = NSError(
            domain: "test",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Apple failed"]
        )
        let expectation = XCTestExpectation(description: "Apple Sign-In should fail")
        expectation.isInverted = true

        sut.appleSignIn(idToken: "apple-id-token") {
            expectation.fulfill()
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockRepository.appleSignInCallCount, 1)
        XCTAssertFalse(sut.isLoading)
        let expectedMessage = UserErrorFormatter.format(
            messageKey: LocalizationKeys.somethingWentWrong,
            code: "E-APP-000"
        )
        XCTAssertEqual(sut.errorMessage, expectedMessage)

        await fulfillment(of: [expectation], timeout: 0.1)
    }
}

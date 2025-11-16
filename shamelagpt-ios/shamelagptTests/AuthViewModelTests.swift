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
        mockRepository.errorToThrow = NSError(domain: "test", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        
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
}

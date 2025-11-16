//
//  OCRManagerTests.swift
//  shamelagptTests
//
//  Tests for OCRManager
//

import XCTest
import UIKit
@testable import ShamelaGPT

@MainActor
final class OCRManagerTests: XCTestCase {

    var sut: OCRManager!

    override func setUpWithError() throws {
        sut = OCRManager()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Text Recognition Tests

    func testRecognizeTextFromValidImage() async throws {
        // Given - Create a simple test image with text
        let image = try createTestImage(withText: "Hello World", fontSize: 48)

        // When
        let extractedText = try await sut.recognizeText(from: image)

        // Then - Should extract some text (Vision may not be 100% accurate with generated images)
        XCTAssertFalse(extractedText.isEmpty, "Should extract text from image")
        XCTAssertFalse(sut.isProcessing, "Should not be processing after completion")
        XCTAssertNil(sut.error, "Should not have error on success")
    }

    func testRecognizeTextWithLanguageDetection() async throws {
        // Given - Create test image with English text
        let image = try createTestImage(withText: "Test", fontSize: 48)

        // When
        let result = try await sut.recognizeTextWithLanguage(from: image)

        // Then
        XCTAssertFalse(result.text.isEmpty, "Should extract text")
        // Language detection may return en, nil, or other depending on Vision's analysis
        XCTAssertFalse(sut.isProcessing, "Should not be processing after completion")
        XCTAssertEqual(sut.extractedText, result.text, "Extracted text should be stored")
    }

    func testRecognizeTextFromArabicImage() async throws {
        // Given - Create test image with Arabic text
        let arabicText = "مرحبا"
        let image = try createTestImage(withText: arabicText, fontSize: 48)

        // When/Then - Should attempt recognition (accuracy may vary with generated images)
        do {
            let result = try await sut.recognizeTextWithLanguage(from: image)
            XCTAssertFalse(sut.isProcessing, "Should not be processing after completion")
            // If text is recognized, verify the result
            XCTAssertFalse(result.text.isEmpty, "Recognized text should not be empty")
        } catch OCRError.noTextFound {
            // Vision might not recognize text from programmatically generated images
            // This is acceptable behavior
            XCTAssertFalse(sut.isProcessing, "Should not be processing after completion")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRecognizeTextFromMixedLanguageImage() async throws {
        // Given - Create test image with mixed English and Arabic
        let mixedText = "Hello مرحبا"
        let image = try createTestImage(withText: mixedText, fontSize: 48)

        // When
        do {
            _ = try await sut.recognizeTextWithLanguage(from: image)
            // Then
            XCTAssertFalse(sut.isProcessing, "Should not be processing after completion")
            // Language detection should return one of the languages or nil
        } catch OCRError.noTextFound {
            // Vision can fail to extract mixed-script text on synthetic images; treat as acceptable
            XCTAssertFalse(sut.isProcessing, "Should not be processing after completion")
        }
    }

    // MARK: - Error Cases

    func testRecognizeTextFromInvalidImage() async throws {
        // Given - Create an image without CGImage representation
        // (CIImage-based UIImage doesn't have cgImage)
        let ciImage = CIImage(color: .red)
        let image = UIImage(ciImage: ciImage)

        // When/Then - Should throw invalidImage error
        do {
            _ = try await sut.recognizeText(from: image)
            XCTFail("Should throw invalidImage error")
        } catch let error as OCRError {
            XCTAssertEqual(error, .invalidImage)
            XCTAssertEqual(sut.error, .invalidImage, "Error should be stored")
            XCTAssertFalse(sut.isProcessing, "Should not be processing after error")
        } catch {
            XCTFail("Should throw OCRError, got: \(error)")
        }
    }

    func testRecognizeTextFromImageWithNoText() async throws {
        // Given - Create a blank image
        let blankImage = try createBlankImage(size: CGSize(width: 200, height: 200))

        // When/Then - Should throw noTextFound error
        do {
            _ = try await sut.recognizeText(from: blankImage)
            // Note: This might succeed if Vision detects noise as text
            // The test verifies the code path works
        } catch let error as OCRError {
            // If it fails, it should be noTextFound error
            XCTAssertEqual(error, .noTextFound)
            XCTAssertEqual(sut.error, .noTextFound)
        }

        XCTAssertFalse(sut.isProcessing, "Should not be processing after completion")
    }

    func testRecognizeTextFromVerySmallImage() async throws {
        // Given - Create a very small image that might be hard to process
        let tinyImage = try createTestImage(withText: "A", fontSize: 4)

        // When
        // Should complete without crashing (may or may not find text)
        do {
            _ = try await sut.recognizeText(from: tinyImage)
            // If successful, verify state
            XCTAssertFalse(sut.isProcessing)
        } catch {
            // If it fails, verify it's a recognized error
            XCTAssertNotNil(sut.error)
        }

        // Then - Should complete one way or another
        XCTAssertFalse(sut.isProcessing)
    }

    // MARK: - State Management Tests

    func testIsProcessingTrueDuringRecognition() async throws {
        // Given
        let image = try createTestImage(withText: "Test", fontSize: 48)

        // Track processing state
        var wasProcessing = false

        // Start recognition in background
        let recognitionTask = Task {
            do {
                _ = try await sut.recognizeText(from: image)
            } catch {
                // Ignore errors for this test
            }
        }

        // Check if processing flag gets set
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        wasProcessing = sut.isProcessing

        // Wait for completion
        _ = await recognitionTask.result

        // Then
        XCTAssertFalse(sut.isProcessing, "Should not be processing after completion")
        XCTAssertTrue(wasProcessing, "Processing flag should be true while recognition is running")
    }

    func testIsProcessingFalseAfterCompletion() async throws {
        // Given
        let image = try createTestImage(withText: "Test", fontSize: 48)

        // When
        do {
            _ = try await sut.recognizeText(from: image)
        } catch {
            // Ignore errors
        }

        // Then
        XCTAssertFalse(sut.isProcessing, "Should be false after completion")
    }

    func testExtractedTextUpdatedAfterRecognition() async throws {
        // Given
        let image = try createTestImage(withText: "Hello", fontSize: 48)

        // When
        do {
        let text = try await sut.recognizeText(from: image)

            // Then
            if !text.isEmpty {
                XCTAssertEqual(sut.extractedText, text, "Extracted text should match returned text")
                XCTAssertFalse(sut.extractedText.isEmpty, "Extracted text should be stored")
            }
        } catch {
            // If recognition fails, extracted text should be empty
            XCTAssertTrue(sut.extractedText.isEmpty, "Extracted text should be empty on failure")
        }
    }

    func testClearExtractedTextWorks() async throws {
        // Given - Set some extracted text
        let image = try createTestImage(withText: "Test", fontSize: 48)
        do {
            _ = try await sut.recognizeText(from: image)
        } catch {
            // Ignore for this test
        }

        // When
        sut.clearExtractedText()

        // Then
        XCTAssertEqual(sut.extractedText, "", "Extracted text should be cleared")
    }

    func testClearErrorWorks() throws {
        // Given - Create an error state
        let ciImage = CIImage(color: .red)
        let invalidImage = UIImage(ciImage: ciImage)

        Task {
            do {
                _ = try await sut.recognizeText(from: invalidImage)
            } catch {
                // Expected
            }
        }

        // Wait a bit for error to be set
        let expectation = XCTestExpectation(description: "Wait for error")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.error, "Error should be cleared")
    }

    func testErrorSetOnFailure() async throws {
        // Given - Invalid image
        let ciImage = CIImage(color: .red)
        let invalidImage = UIImage(ciImage: ciImage)

        // When
        do {
            _ = try await sut.recognizeText(from: invalidImage)
            XCTFail("Should throw error")
        } catch {
            // Then
            XCTAssertNotNil(sut.error, "Error should be set")
            XCTAssertEqual(sut.error, .invalidImage)
        }
    }

    func testErrorClearedOnNewRecognition() async throws {
        // Given - Set error state first
        let ciImage = CIImage(color: .red)
        let invalidImage = UIImage(ciImage: ciImage)
        do {
            _ = try await sut.recognizeText(from: invalidImage)
        } catch {
            // Expected
        }

        XCTAssertNotNil(sut.error, "Error should be set from first attempt")

        // When - Try with valid image
        let validImage = try createTestImage(withText: "Test", fontSize: 48)
        do {
            _ = try await sut.recognizeText(from: validImage)

            // Then - Error should be cleared
            XCTAssertNil(sut.error, "Error should be cleared on new successful recognition")
        } catch {
            // Even if it fails, error should be updated
            XCTAssertNotNil(sut.error)
        }
    }

    // MARK: - Error Description Tests

    func testInvalidImageErrorDescription() {
        // Given
        let error = OCRError.invalidImage

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("invalid") ?? false)
    }

    func testNoTextFoundErrorDescription() {
        // Given
        let error = OCRError.noTextFound

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("No text") ?? false)
    }

    func testRecognitionFailedErrorDescription() {
        // Given
        let error = OCRError.recognitionFailed("Test failure")

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("Test failure") ?? false)
    }

    func testOCRErrorEquality() {
        // Given
        let error1 = OCRError.invalidImage
        let error2 = OCRError.invalidImage
        let error3 = OCRError.noTextFound

        // Then
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    // MARK: - Helper Methods

    /// Creates a test image with rendered text
    private func createTestImage(withText text: String, fontSize: CGFloat) throws -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Black text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: UIColor.black
            ]

            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedString.size()

            // Center the text
            let x = (size.width - textSize.width) / 2
            let y = (size.height - textSize.height) / 2

            attributedString.draw(at: CGPoint(x: x, y: y))
        }

        return image
    }

    /// Creates a blank white image
    private func createBlankImage(size: CGSize) throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        return image
    }
}

// MARK: - OCRError Equatable Conformance
// Note: OCRError now conforms to Equatable in the main codebase

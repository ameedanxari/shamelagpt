//
//  FactCheckIntegrationTests.swift
//  shamelagptTests
//
//  Integration tests for fact-check flow with OCR
//

import XCTest
import UIKit
@testable import ShamelaGPT

@MainActor
final class FactCheckIntegrationTests: XCTestCase {

    var chatRepository: ChatRepositoryImpl!
    var sendMessageUseCase: SendMessageUseCase!
    var ocrManager: OCRManager!
    var mockAPIClient: MockAPIClient!
    var mockNetworkMonitor: MockNetworkMonitor!
    var testCoreDataStack: TestCoreDataStack!

    override func setUpWithError() throws {
        // Set up in-memory Core Data stack
        testCoreDataStack = TestCoreDataStack()

        // Set up mock network components
        mockAPIClient = MockAPIClient()
        mockNetworkMonitor = MockNetworkMonitor()
        mockNetworkMonitor.mockIsConnected = true

        // Create real repository with in-memory stack
        chatRepository = ChatRepositoryImpl(
            coreDataStack: testCoreDataStack,
            conversationDAO: ConversationDAO(),
            messageDAO: MessageDAO(),
            apiClient: mockAPIClient,
            networkMonitor: mockNetworkMonitor
        )

        // Create real use case
        sendMessageUseCase = SendMessageUseCase(
            chatRepository: chatRepository,
            apiClient: mockAPIClient,
            networkMonitor: mockNetworkMonitor
        )

        // Create real OCR manager
        ocrManager = OCRManager()
    }

    override func tearDownWithError() throws {
        ocrManager = nil
        sendMessageUseCase = nil
        chatRepository = nil
        mockNetworkMonitor = nil
        mockAPIClient = nil
        testCoreDataStack = nil
    }

    // MARK: - Helper Methods

    private func createTestImage(withText text: String, fontSize: CGFloat = 40) throws -> UIImage {
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
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            attributedString.draw(in: textRect)
        }

        guard image.cgImage != nil else {
            throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create test image"])
        }

        return image
    }

    // MARK: - Fact-Check Flow Integration Tests

    func testCompleteFactCheckFlow() async throws {
        // Given - Create conversation
        let conversation = try await chatRepository.createConversation(title: "Fact Check Test")

        // Create test image with text
        let testImage = try createTestImage(withText: "Test text for fact checking")

        // Perform OCR (this is the real OCR manager)
        let ocrResult = try await ocrManager.recognizeTextWithLanguage(from: testImage)

        // Convert image to data
        let imageData = testImage.jpegData(compressionQuality: 0.8)

        // Configure mock API response
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Fact-check result: The text has been verified.",
            threadId: "fact-check-thread"
        )

        // When - Send fact-check message with OCR result and image data
        let result = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: ocrResult.text,
            imageData: imageData,
            detectedLanguage: ocrResult.detectedLanguage,
            isFactCheckMessage: true,
            saveUserMessage: true
        )

        // Then - Verify complete fact-check flow
        XCTAssertTrue(result.userMessage.isFactCheckMessage, "User message should be marked as fact-check")
        XCTAssertNotNil(result.userMessage.imageData, "User message should have image data")
        XCTAssertNotNil(result.userMessage.detectedLanguage, "User message should have detected language")

        // Verify assistant response
        XCTAssertEqual(result.assistantMessage.content, "Fact-check result: The text has been verified.")

        // Verify persistence
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
        XCTAssertEqual(messages.count, 2)

        let factCheckMessage = messages.first(where: { $0.isFactCheckMessage })
        XCTAssertNotNil(factCheckMessage)
        XCTAssertNotNil(factCheckMessage?.imageData)
    }

    func testFactCheckMessageWithImageData() async throws {
        // Given
        let conversation = try await chatRepository.createConversation(title: "Image Data Test")
        let testImage = try createTestImage(withText: "Sample text")
        let imageData = testImage.jpegData(compressionQuality: 0.8)

        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Response",
            threadId: "thread"
        )

        // When - Send fact-check message with image data
        let result = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "Check this text",
            imageData: imageData,
            detectedLanguage: nil,
            isFactCheckMessage: true,
            saveUserMessage: true
        )

        // Then - Verify image data persisted
        XCTAssertNotNil(result.userMessage.imageData)
        XCTAssertEqual(result.userMessage.imageData?.count, imageData?.count)

        // Fetch from repository to verify persistence
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
        let persistedMessage = messages.first(where: { $0.isFactCheckMessage })

        XCTAssertNotNil(persistedMessage?.imageData)
        XCTAssertEqual(persistedMessage?.imageData?.count, imageData?.count)
    }

    func testFactCheckMessageWithLanguage() async throws {
        // Given
        let conversation = try await chatRepository.createConversation(title: "Language Test")
        let testImage = try createTestImage(withText: "Arabic text example")

        // Simulate Arabic language detection
        let detectedLanguage = "ar"

        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Response in Arabic context",
            threadId: "lang-thread"
        )

        // When - Send fact-check message with detected language
        let result = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "النص العربي",
            imageData: testImage.jpegData(compressionQuality: 0.8),
            detectedLanguage: detectedLanguage,
            isFactCheckMessage: true,
            saveUserMessage: true
        )

        // Then - Verify language persisted
        XCTAssertEqual(result.userMessage.detectedLanguage, "ar")
        XCTAssertTrue(result.userMessage.isFactCheckMessage)

        // Fetch from repository
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
        let factCheckMessage = messages.first(where: { $0.isFactCheckMessage })

        XCTAssertEqual(factCheckMessage?.detectedLanguage, "ar")
        XCTAssertNotNil(factCheckMessage?.languageDisplayName, "Should have language display name")
    }

    func testFactCheckAPICallFormatted() async throws {
        // Given
        let conversation = try await chatRepository.createConversation(title: "API Format Test")
        let testText = "Verify this statement"
        let testImage = try createTestImage(withText: testText)

        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Verification complete",
            threadId: "api-thread"
        )

        // When - Send fact-check message
        _ = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: testText,
            imageData: testImage.jpegData(compressionQuality: 0.8),
            detectedLanguage: "en",
            isFactCheckMessage: true,
            saveUserMessage: true
        )

        // Then - Verify API was called correctly
        XCTAssertEqual(mockAPIClient.sendMessageCallCount, 1, "API should be called once")

        let lastRequest = mockAPIClient.lastSendMessageRequest
        XCTAssertNotNil(lastRequest)
        XCTAssertEqual(lastRequest?.question, testText, "API should receive the extracted text")

        // Verify the message was stored as fact-check message
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
        let userMessage = messages.first(where: { $0.isUserMessage })

        XCTAssertTrue(userMessage?.isFactCheckMessage ?? false)
        XCTAssertNotNil(userMessage?.imageData)
        XCTAssertNotNil(userMessage?.detectedLanguage)
    }
}

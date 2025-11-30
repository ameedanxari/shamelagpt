//
//  ChatViewModel.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine
import SwiftUI
import UIKit

/// ViewModel for the chat screen
@MainActor
final class ChatViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var errorMessage: String?
    @Published private(set) var conversationId: String
    @Published private(set) var threadId: String?

    // Voice input properties
    @Published var isRecording: Bool = false
    @Published var voiceInputError: VoiceInputError?

    // OCR properties
    @Published var isProcessingOCR: Bool = false
    @Published var ocrError: OCRError?
    @Published var showImageSourceSheet: Bool = false
    @Published var showCameraPicker: Bool = false
    @Published var showPhotoLibraryPicker: Bool = false
    @Published var selectedImage: UIImage?

    // Fact-checking properties
    @Published var showOCRConfirmation: Bool = false
    @Published var ocrExtractedText: String = ""
    @Published var ocrDetectedLanguage: String?
    @Published var ocrImageData: Data?

    // MARK: - Private Properties

    private let sendMessageUseCase: SendMessageUseCaseProtocol
    private let chatRepository: ChatRepository
    private let voiceInputManager: any VoiceInputManagerProtocol
    private let ocrManager: any OCRManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        conversationId: String,
        sendMessageUseCase: SendMessageUseCaseProtocol,
        chatRepository: ChatRepository,
        voiceInputManager: any VoiceInputManagerProtocol,
        ocrManager: any OCRManagerProtocol
    ) {
        self.conversationId = conversationId
        self.sendMessageUseCase = sendMessageUseCase
        self.chatRepository = chatRepository
        self.voiceInputManager = voiceInputManager
        self.ocrManager = ocrManager

        // Load messages on initialization
        Task {
            await loadMessages()
        }

        // Observe voice input transcription
        voiceInputManager.transcribedTextPublisher
            .sink { [weak self] text in
                guard let self = self, !text.isEmpty else { return }
                self.inputText = text
            }
            .store(in: &cancellables)

        // Observe voice input recording state
        voiceInputManager.isRecordingPublisher
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)

        // Observe voice input errors
        voiceInputManager.errorPublisher
            .sink { [weak self] error in
                self?.voiceInputError = error
            }
            .store(in: &cancellables)

        // Observe OCR processing state
        ocrManager.isProcessingPublisher
            .sink { [weak self] isProcessing in
                self?.isProcessingOCR = isProcessing
            }
            .store(in: &cancellables)

        // Observe OCR errors
        ocrManager.errorPublisher
            .sink { [weak self] error in
                self?.ocrError = error
            }
            .store(in: &cancellables)

        // Handle selected image for OCR
        $selectedImage
            .compactMap { $0 }
            .sink { [weak self] image in
                Task {
                    await self?.processImageWithOCR(image)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Sends a message to the assistant
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !isLoading,
              !isRecording,
              !isProcessingOCR else {
            AppLogger.chat.logDebug("SendMessage ignored: invalid state (empty=\(inputText.isEmpty), loading=\(isLoading), recording=\(isRecording), ocr=\(isProcessingOCR))")
            return
        }

        let messageText = inputText
        inputText = "" // Clear input immediately for better UX

        AppLogger.chat.logInfo("Sending message: '\(messageText.prefix(50))...' in conversation: \(conversationId)")

        // Create optimistic user message and add to UI immediately
        let optimisticUserMessage = Message(
            id: "temp-\(UUID().uuidString)",
            conversationId: conversationId,
            content: messageText,
            isUserMessage: true,
            timestamp: Date(),
            sources: []
        )
        messages.append(optimisticUserMessage)
        AppLogger.chat.logDebug("Added optimistic user message to UI - Total messages now: \(messages.count)")
        AppLogger.chat.logDebug("Current messages array: \(messages.map { "\($0.id): \($0.content.prefix(20))..." })")

        isLoading = true
        error = nil
        errorMessage = nil

        Task {
            do {
                // Ensure conversation exists in database before sending
                await ensureConversationExistsBeforeSending()

                let result = try await sendMessageUseCase.execute(
                    conversationId: conversationId,
                    message: messageText
                )

                AppLogger.chat.logInfo("Message sent successfully, thread ID: \(result.conversation.threadId ?? "nil")")

                // Update thread ID if needed
                if threadId == nil {
                    threadId = result.conversation.threadId
                    AppLogger.chat.logDebug("Updated thread ID to: \(result.conversation.threadId ?? "nil")")
                }

                // Reload messages to replace optimistic message with real ones
                await loadMessages()

                isLoading = false

            } catch {
                AppLogger.chat.logError("Failed to send message", error: error)
                handleError(error)
                isLoading = false

                // Remove optimistic message and put text back in input field
                if let index = messages.firstIndex(where: { $0.id == optimisticUserMessage.id }) {
                    messages.remove(at: index)
                }
                inputText = messageText
            }
        }
    }

    /// Ensures conversation exists in database before sending message
    /// Creates a new conversation on-the-fly if the current one doesn't exist
    private func ensureConversationExistsBeforeSending() async {
        do {
            // Check if current conversation exists
            if let _ = try await chatRepository.fetchConversation(byId: conversationId) {
                AppLogger.chat.logDebug("Conversation exists: \(conversationId)")
                return
            }

            // Conversation doesn't exist - this shouldn't happen with the new validation
            // but we log it for debugging
            AppLogger.chat.logWarning("Conversation \(conversationId) doesn't exist in database")
            AppLogger.chat.logWarning("This should have been handled by MainTabView.validateCurrentConversation()")

        } catch {
            AppLogger.chat.logError("Error checking conversation existence", error: error)
        }
    }

    /// Loads messages for the current conversation
    func loadMessages() async {
        AppLogger.chat.logDebug("Loading messages for conversation: \(conversationId)")
        AppLogger.chat.logDebug("Current message count before load: \(messages.count)")

        do {
            let fetchedMessages = try await chatRepository.fetchMessages(
                forConversation: conversationId
            )
            AppLogger.chat.logDebug("Fetched \(fetchedMessages.count) messages from repository")

            let hasOptimisticMessages = messages.contains { $0.id.hasPrefix("temp-") }
            AppLogger.chat.logDebug("Has optimistic messages: \(hasOptimisticMessages), isLoading: \(isLoading)")

            // ENHANCED: Only skip reload if we're loading AND have optimistic messages
            // AND the fetch returned fewer messages than we currently have
            if isLoading && hasOptimisticMessages && fetchedMessages.count < messages.count {
                AppLogger.chat.logDebug("Skipping reload - preserving \(messages.count) messages, fetch returned \(fetchedMessages.count)")
                return
            }

            // ENHANCED: Merge instead of replace when loading with optimistic messages
            if hasOptimisticMessages && isLoading {
                var mergedMessages = fetchedMessages
                for optimisticMsg in messages where optimisticMsg.id.hasPrefix("temp-") {
                    // Check if this optimistic message was persisted
                    let isPersisted = fetchedMessages.contains {
                        $0.content == optimisticMsg.content &&
                        $0.isUserMessage == optimisticMsg.isUserMessage
                    }
                    if !isPersisted {
                        mergedMessages.append(optimisticMsg)
                    }
                }
                messages = mergedMessages.sorted { $0.timestamp < $1.timestamp }
                AppLogger.chat.logInfo("Merged messages: \(mergedMessages.count) total (\(fetchedMessages.count) from DB, \(mergedMessages.count - fetchedMessages.count) optimistic)")
                AppLogger.chat.logDebug("Final messages array: \(messages.map { "\($0.id): \($0.content.prefix(20))..." })")
            } else {
                messages = fetchedMessages
                AppLogger.chat.logInfo("Loaded \(fetchedMessages.count) messages")
                AppLogger.chat.logDebug("Final messages array: \(messages.map { "\($0.id): \($0.content.prefix(20))..." })")
            }

            AppLogger.chat.logDebug("Message count after load: \(messages.count)")

            // Also update thread ID from conversation
            if let conversation = try await chatRepository.fetchConversation(byId: conversationId),
               let fetchedThreadId = conversation.threadId {
                threadId = fetchedThreadId
                AppLogger.chat.logDebug("Updated thread ID from conversation: \(fetchedThreadId)")
            }
        } catch {
            AppLogger.chat.logError("Failed to load messages", error: error)
            handleError(error)
        }
    }

    /// Updates the input text
    func updateInputText(_ text: String) {
        inputText = text
    }

    /// Clears the current error
    func clearError() {
        error = nil
        errorMessage = nil
    }

    /// Returns whether the send button should be enabled
    var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isRecording && !isProcessingOCR
    }

    // MARK: - Voice Input Methods

    /// Toggles voice input recording
    func toggleVoiceInput() {
        if isRecording {
            stopVoiceInput()
        } else {
            Task {
                await startVoiceInput()
            }
        }
    }

    /// Starts voice input recording
    func startVoiceInput() async {
        AppLogger.voiceInput.logInfo("Starting voice input")

        // Request permission if needed
        let hasPermission = await voiceInputManager.requestPermission()

        guard hasPermission else {
            AppLogger.voiceInput.logWarning("Voice input permission denied")
            voiceInputError = .permissionDenied
            return
        }

        AppLogger.voiceInput.logDebug("Voice input permission granted")

        // Determine locale based on app settings or default to English
        // For Arabic support, we can detect or allow user to choose
        let locale = Locale(identifier: "en-US") // Could be "ar-SA" for Arabic

        do {
            try await voiceInputManager.startRecording(locale: locale)
            AppLogger.voiceInput.logInfo("Voice input recording started successfully with locale: \(locale.identifier)")
        } catch {
            AppLogger.voiceInput.logError("Failed to start voice input recording", error: error)
            if let voiceError = error as? VoiceInputError {
                voiceInputError = voiceError
            }
        }
    }

    /// Stops voice input recording
    func stopVoiceInput() {
        AppLogger.voiceInput.logInfo("Stopping voice input")
        voiceInputManager.stopRecording()
    }

    /// Clears voice input error
    func clearVoiceInputError() {
        voiceInputError = nil
        voiceInputManager.clearError()
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        AppLogger.chat.logError("handleError called with error: \(error)")
        self.error = error
        if let networkError = error as? NetworkError {
            errorMessage = networkError.userMessage
            AppLogger.chat.logInfo("Set errorMessage from NetworkError: \(networkError.userMessage)")
        } else {
            errorMessage = error.localizedDescription
            AppLogger.chat.logInfo("Set errorMessage from error.localizedDescription: \(error.localizedDescription)")
        }
    }

    // MARK: - OCR Methods

    /// Handles camera button tap
    func handleCameraButtonTap() {
        AppLogger.ocr.logInfo("Camera button tapped, showing image source sheet")
        showImageSourceSheet = true
    }

    /// Selects camera as image source
    func selectCamera() {
        AppLogger.ocr.logInfo("Camera selected as image source")
        showCameraPicker = true
    }

    /// Selects photo library as image source
    func selectPhotoLibrary() {
        AppLogger.ocr.logInfo("Photo library selected as image source")
        showPhotoLibraryPicker = true
    }

    /// Processes image with OCR and shows confirmation dialog
    private func processImageWithOCR(_ image: UIImage) async {
        AppLogger.ocr.logInfo("Starting OCR processing for image with size: \(image.size)")

        do {
            let ocrResult = try await ocrManager.recognizeTextWithLanguage(from: image)

            AppLogger.ocr.logInfo("OCR completed successfully, extracted \(ocrResult.text.count) characters, language: \(ocrResult.detectedLanguage ?? "unknown")")

            // Compress image for storage (max 200KB)
            let imageData = compressImage(image, maxSizeKB: 200)

            // Store OCR result and show confirmation dialog
            ocrExtractedText = ocrResult.text
            ocrDetectedLanguage = ocrResult.detectedLanguage
            ocrImageData = imageData
            showOCRConfirmation = true

            // Clear the selected image
            selectedImage = nil
        } catch {
            AppLogger.ocr.logError("OCR processing failed", error: error)
            if let ocrError = error as? OCRError {
                self.ocrError = ocrError
            }
        }
    }

    /// Confirms fact-check text and sends message
    func confirmFactCheck(text: String) {
        // Dismiss confirmation dialog
        showOCRConfirmation = false

        // Store the fact-check data temporarily
        let imageData = ocrImageData
        let language = ocrDetectedLanguage

        // Clear OCR state
        ocrExtractedText = ""
        ocrDetectedLanguage = nil
        ocrImageData = nil

        // Send fact-check message
        Task {
            await sendFactCheckMessage(text: text, imageData: imageData, detectedLanguage: language)
        }
    }

    /// Sends a fact-check message with image data and language metadata
    private func sendFactCheckMessage(text: String, imageData: Data?, detectedLanguage: String?) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            AppLogger.chat.logDebug("Attempted to send empty fact-check message, ignoring")
            return
        }

        AppLogger.chat.logInfo("Sending fact-check message: '\(text.prefix(50))...' in conversation: \(conversationId)")

        // Create optimistic user message with fact-check metadata
        let optimisticUserMessage = Message(
            id: "temp-\(UUID().uuidString)",
            conversationId: conversationId,
            content: text,
            isUserMessage: true,
            timestamp: Date(),
            sources: [],
            imageData: imageData,
            detectedLanguage: detectedLanguage,
            isFactCheckMessage: true
        )
        messages.append(optimisticUserMessage)
        AppLogger.chat.logDebug("Added optimistic fact-check user message to UI")

        isLoading = true
        error = nil

        do {
            // Ensure conversation exists in database before sending
            await ensureConversationExistsBeforeSending()

            // Save user message with fact-check metadata to database
            let savedUserMessage = try await chatRepository.addFactCheckMessage(
                toConversation: conversationId,
                content: text,
                isUserMessage: true,
                sources: [],
                imageData: imageData,
                detectedLanguage: detectedLanguage,
                isFactCheckMessage: true
            )

            AppLogger.chat.logInfo("Saved fact-check message to database: \(savedUserMessage.id)")

            // Wrap the text for API with fact-check prompt
            let factCheckPrompt = "Please fact-check this statement: \(text)"

            // Send to API (don't save user message again - we already saved it with metadata)
            let result = try await sendMessageUseCase.execute(
                conversationId: conversationId,
                message: factCheckPrompt,
                saveUserMessage: false
            )

            AppLogger.chat.logInfo("Fact-check message sent successfully, thread ID: \(result.conversation.threadId ?? "nil")")

            // Update thread ID if needed
            if threadId == nil {
                threadId = result.conversation.threadId
                AppLogger.chat.logDebug("Updated thread ID to: \(result.conversation.threadId ?? "nil")")
            }

            // Reload messages to replace optimistic message with real ones
            await loadMessages()

            isLoading = false

        } catch {
            AppLogger.chat.logError("Failed to send fact-check message", error: error)
            self.error = error
            isLoading = false

            // Remove optimistic message on error
            if let index = messages.firstIndex(where: { $0.id == optimisticUserMessage.id }) {
                messages.remove(at: index)
            }
        }
    }

    /// Dismisses OCR confirmation dialog
    func dismissOCRConfirmation() {
        showOCRConfirmation = false
        ocrExtractedText = ""
        ocrDetectedLanguage = nil
        ocrImageData = nil
    }

    /// Compresses image to target size
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)

        while let data = imageData, data.count > maxBytes, compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        return imageData
    }

    /// Clears OCR error
    func clearOCRError() {
        ocrError = nil
        ocrManager.clearError()
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension ChatViewModel {
    static var preview: ChatViewModel {
        let mockSendMessageUseCase = MockSendMessageUseCase()
        let mockChatRepository = MockChatRepository()
        let voiceInputManager = VoiceInputManager()
        let ocrManager = OCRManager()

        return ChatViewModel(
            conversationId: "preview-conversation",
            sendMessageUseCase: mockSendMessageUseCase,
            chatRepository: mockChatRepository,
            voiceInputManager: voiceInputManager,
            ocrManager: ocrManager
        )
    }
}

// Mock implementations for previews
class MockSendMessageUseCase: SendMessageUseCaseProtocol {
    func execute(
        conversationId: String,
        message: String,
        imageData: Data? = nil,
        detectedLanguage: String? = nil,
        isFactCheckMessage: Bool = false,
        saveUserMessage: Bool = true
    ) async throws -> SendMessageUseCase.Result {
        fatalError("Mock implementation - not for production use")
    }
    
    func executePublisher(
        conversationId: String,
        message: String,
        imageData: Data? = nil,
        detectedLanguage: String? = nil,
        isFactCheckMessage: Bool = false,
        saveUserMessage: Bool = true
    ) -> AnyPublisher<SendMessageUseCase.Result, Error> {
        fatalError("Mock implementation - not for production use")
    }
}

class MockChatRepository: ChatRepository {
    func fetchMostRecentEmptyConversation() async throws -> Conversation? {
        return nil
    }
    
    var conversationsPublisher: AnyPublisher<[Conversation], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func createConversation(title: String) async throws -> Conversation {
        fatalError("Mock implementation")
    }

    func fetchAllConversations() async throws -> [Conversation] {
        return []
    }

    func fetchConversation(byId id: String) async throws -> Conversation? {
        return nil
    }

    func fetchConversation(byThreadId threadId: String) async throws -> Conversation? {
        return nil
    }

    func updateConversationTitle(id: String, title: String) async throws {}

    func updateConversationThreadId(id: String, threadId: String) async throws {}

    func deleteConversation(id: String) async throws {}

    func deleteAllConversations() async throws {}

    func addMessage(toConversation conversationId: String, content: String, isUserMessage: Bool, sources: [Source]) async throws -> Message {
        fatalError("Mock implementation")
    }

    func addFactCheckMessage(toConversation conversationId: String, content: String, isUserMessage: Bool, sources: [Source], imageData: Data?, detectedLanguage: String?, isFactCheckMessage: Bool) async throws -> Message {
        fatalError("Mock implementation")
    }

    func fetchMessages(forConversation conversationId: String) async throws -> [Message] {
        return [Message.preview, Message.previewAssistant]
    }

    func updateMessageContent(id: String, content: String) async throws {}

    func deleteMessage(id: String) async throws {}
}
#endif

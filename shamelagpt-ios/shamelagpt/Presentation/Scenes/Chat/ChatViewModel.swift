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
import AVFoundation
import Photos

/// ViewModel for the chat screen
@MainActor
final class ChatViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var errorMessage: String?
    @Published private(set) var conversationId: String?
    @Published private(set) var threadId: String?
    @Published var thinkingMessages: [String] = []

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
    @Published var requiresAuth: Bool = false
    @Published var cameraPermission: CameraPermissionState = .unknown
    @Published var photoLibraryPermission: CameraPermissionState = .unknown
    @Published var showCameraPermissionDenied: Bool = false
    @Published var showPhotoPermissionDenied: Bool = false

    // Fact-checking properties
    @Published var showOCRConfirmation: Bool = false
    @Published var ocrExtractedText: String = ""
    @Published var ocrDetectedLanguage: String?
    @Published var ocrImageData: Data?

    // MARK: - Private Properties

    private let sendMessageUseCase: SendMessageUseCaseProtocol
    private let chatRepository: ChatRepository
    private let apiClient: APIClientProtocol?
    private let isGuest: Bool
    private let onConversationIdChange: ((String?) -> Void)?
    private let voiceInputManager: any VoiceInputManagerProtocol
    private let ocrManager: any OCRManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private let isUITesting: Bool
    private let isRunningTests: Bool
    private let guestSessionId: String?
    private var cameraPermissionOverride: CameraPermissionState?
    private var photoPermissionOverride: CameraPermissionState?
    private let simulateOCRSuccess: Bool
    private let simulatedOCRText: String?
    private let simulatedOCRLanguage: String?

    // MARK: - Initialization

    init(
        conversationId: String?,
        sendMessageUseCase: SendMessageUseCaseProtocol,
        chatRepository: ChatRepository,
        apiClient: APIClientProtocol? = nil,
        isGuest: Bool = false,
        guestSessionId: String? = nil,
        voiceInputManager: any VoiceInputManagerProtocol,
        ocrManager: any OCRManagerProtocol,
        onConversationIdChange: ((String?) -> Void)? = nil
    ) {
        self.conversationId = conversationId
        self.guestSessionId = guestSessionId
        self.sendMessageUseCase = sendMessageUseCase
        self.chatRepository = chatRepository
        self.apiClient = apiClient
        self.isGuest = isGuest
        self.onConversationIdChange = onConversationIdChange
        self.voiceInputManager = voiceInputManager
        self.ocrManager = ocrManager
        let env = ProcessInfo.processInfo.environment
        let hasXCTestConfig = env["XCTestConfigurationFilePath"] != nil
        self.isUITesting = env["UI_TESTING"] == "1" || hasXCTestConfig
        self.isRunningTests = hasXCTestConfig
        self.simulateOCRSuccess = env["SIMULATE_OCR_SUCCESS"] == "true"
        self.simulatedOCRText = env["OCR_EXTRACTED_TEXT"]
        self.simulatedOCRLanguage = env["OCR_DETECTED_LANGUAGE"]

        if isRunningTests {
            cameraPermission = .authorized
            photoLibraryPermission = .authorized
        }

        // Load messages on initialization when a conversation already exists
        if conversationId != nil {
            Task {
                await loadMessages()
            }
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
                    await self?.handleSelectedImage(image)
                }
            }
            .store(in: &cancellables)

        // Preload permission status so UI can reflect denied/restricted states
        refreshCameraPermissionStatus()
        refreshPhotoLibraryPermissionStatus()

        // Apply any UI-test overrides (e.g., simulated permission denial)
        applyUITestPermissionOverrides()
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

        Task { @MainActor in
            var optimisticMessageId: String?
            do {
                let activeConversationId = try await ensureConversationForSend(firstMessage: messageText)
                AppLogger.chat.logInfo("Sending message: '\(messageText.prefix(50))...' in conversation: \(activeConversationId)")

                // Create optimistic user message and add to UI immediately
                let optimisticUserMessage = Message(
                    id: "temp-\(UUID().uuidString)",
                    conversationId: activeConversationId,
                    content: messageText,
                    isUserMessage: true,
                    timestamp: Date(),
                    sources: []
                )
                optimisticMessageId = optimisticUserMessage.id
                messages.append(optimisticUserMessage)
                AppLogger.chat.logDebug("Added optimistic user message to UI - Total messages now: \(messages.count)")
                AppLogger.chat.logDebug("Current messages array: \(messages.map { "\($0.id): \($0.content.prefix(20))..." })")

                isLoading = true
                error = nil
                errorMessage = nil
                thinkingMessages = isGuest ? [] : [LocalizationKeys.thinking.localized]

                // Guest path: use streaming SSE endpoint to receive incremental chunks
                if isGuest || apiClient != nil {
                    let isGuestFlow = isGuest
                    AppLogger.chat.logInfo("\(isGuestFlow ? "Guest" : "Authenticated") mode - streaming message via API")

                    guard let apiClient = apiClient else {
                        throw NetworkError.unknown(NSError(domain: "ChatViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "API client not configured"]))
                    }

                    // Optionally include a session id. Prefer a persistent guestSessionId when available,
                    // otherwise fall back to threadId for continuity within the app session.
                    let sessionIdToUse = guestSessionId ?? threadId
                    let request = ChatRequest(
                        question: messageText,
                        threadId: threadId,
                        languagePreference: LanguageManager.shared.currentLanguage.rawValue,
                        sessionId: sessionIdToUse,
                        enableThinking: true
                    )

                    // Try to save user message locally if this conversation is local-only or authenticated (so history persists)
                    var shouldSaveAssistant = !isGuestFlow
                    if let chatRepo = Optional(self.chatRepository) {
                        if let conv = try? await chatRepo.fetchConversation(byId: activeConversationId), conv.isLocalOnly {
                            shouldSaveAssistant = true
                            // Save user message locally so it's persisted for guest local-only conversations
                            _ = try? await chatRepo.addMessage(
                                toConversation: activeConversationId,
                                content: messageText,
                                isUserMessage: true,
                                sources: []
                            )
                        } else if !isGuestFlow {
                            // Authenticated flow: persist user message immediately
                            _ = try? await chatRepo.addMessage(
                                toConversation: activeConversationId,
                                content: messageText,
                                isUserMessage: true,
                                sources: []
                            )
                        }
                    }

                    // Stream and parse SSE events robustly. SSE events may contain multiple `data:` lines
                    // for a single event; events are delimited by a blank line. We'll buffer lines until
                    // an empty line is encountered, then process the accumulated event.
                    let stream = try await (isGuestFlow ? apiClient.streamGuestMessage(request) : apiClient.streamMessage(request))
                    var assembled = ""
                    var assistantMessageId: String? = nil
                    var eventBuffer: [String] = []
                    var shouldTerminateStream = false

                    // Shared helper to insert or update the assistant message during streaming so both chunk and done paths behave consistently.
                    func upsertAssistantMessage(with content: String) {
                        Task { @MainActor in
                            if assistantMessageId == nil {
                                let assistant = Message(
                                    id: UUID().uuidString,
                                    conversationId: activeConversationId,
                                    content: content,
                                    isUserMessage: false,
                                    timestamp: Date(),
                                    sources: []
                                )
                                assistantMessageId = assistant.id
                                messages.append(assistant)
                            } else if let idx = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                                let old = messages[idx]
                                let updated = Message(
                                    id: old.id,
                                    conversationId: old.conversationId,
                                    content: content,
                                    isUserMessage: old.isUserMessage,
                                    timestamp: old.timestamp,
                                    sources: old.sources,
                                    imageData: old.imageData,
                                    detectedLanguage: old.detectedLanguage,
                                    isFactCheckMessage: old.isFactCheckMessage
                                )
                                messages[idx] = updated
                            }
                        }
                    }

                    func processEventLines(_ lines: [String]) {
                        // Extract payloads: support "data:" prefixed SSE and plain JSON lines (e.g. "message	{...}")
                        AppLogger.network.logDebug("processEventLines called - raw lines: \(lines)")
                        let dataLines = lines.compactMap { line -> String? in
                            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.hasPrefix("data:") {
                                let start = trimmed.index(trimmed.startIndex, offsetBy: 5)
                                return String(trimmed[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                            if let braceIndex = trimmed.firstIndex(of: "{") {
                                return String(trimmed[braceIndex...])
                            }
                            return trimmed.isEmpty ? nil : trimmed
                        }

                        guard !dataLines.isEmpty else { return }
                        let combined = dataLines.joined(separator: "\\n")
                        AppLogger.network.logDebug("processEventLines - combined payload (first 1000 chars): \(String(combined.prefix(1000)))")

                        // Some servers may send [DONE]
                        if combined == "[DONE]" {
                            Task { @MainActor in
                                isLoading = false
                            }
                            shouldTerminateStream = true
                            return
                        }

                        struct StreamEvent: Decodable {
                            let type: String
                            let content: String?
                            let sessionId: String?
                            let threadId: String?
                            let fullAnswer: String?
                        }

                        var encounteredDone = false

                        // Decode each JSON object separately (some servers send multiple JSON objects in one event)
                        for dataLine in dataLines {
                            guard let data = dataLine.data(using: .utf8) else {
                                AppLogger.network.logWarning("processEventLines - unable to convert dataLine to data: \(dataLine.prefix(200))")
                                continue
                            }

                            do {
                                let decoder = JSONDecoder()
                                decoder.keyDecodingStrategy = .convertFromSnakeCase
                                let event = try decoder.decode(StreamEvent.self, from: data)

                                if event.type == "done" {
                                    encounteredDone = true
                                }

                                // Persist thread identifier as soon as the server provides it
                                if let tid = event.threadId ?? event.sessionId {
                                    Task { @MainActor in
                                        if threadId == nil || threadId != tid {
                                            threadId = tid
                                        }
                                    }
                                }

                                Task { @MainActor in
                                    switch event.type {
                                    case "metadata":
                                        // Prefer explicit threadId from server, otherwise fall back to sessionId
                                        if let tid = event.threadId ?? event.sessionId {
                                            if threadId == nil || threadId != tid {
                                                AppLogger.chat.logInfo("SSE metadata - updating threadId to \(tid)")
                                                threadId = tid
                                            }
                                        }
                                    case "thinking":
                                        if let text = event.content?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                                            AppLogger.chat.logDebug("Thinking: \(text)")
                                            // Replace with latest thinking status
                                            thinkingMessages = [text]
                                        }
                                    case "chunk":
                                        let piece = event.content ?? ""
                                        assembled += piece
                                        thinkingMessages.removeAll()

                                        upsertAssistantMessage(with: assembled)
                                    case "done":
                                        // Server signals final answer; prefer fullAnswer if provided
                                        if let final = event.fullAnswer ?? event.content {
                                            assembled = final
                                            upsertAssistantMessage(with: assembled)
                                            isLoading = false
                                        }
                                        thinkingMessages.removeAll()
                                    default:
                                        AppLogger.chat.logDebug("Unhandled stream event type: \(event.type)")
                                    }
                                }

                            } catch {
                                AppLogger.chat.logError("Failed to decode stream event", error: error)
                                AppLogger.network.logDebug("Failed payload line: \(dataLine)")
                                continue
                            }
                        }

                        if encounteredDone {
                            Task {
                                await persistThreadIdIfNeeded()
                            }
                            shouldTerminateStream = true
                        }
                    }

                    for try await line in stream {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        AppLogger.network.logDebug("SSE raw line received: \(String(line.prefix(500)))")
                        // An empty line is an SSE event delimiter - process accumulated lines
                        if trimmed.isEmpty {
                            AppLogger.network.logDebug("SSE event delimiter reached - processing buffer with \(eventBuffer.count) lines")
                            processEventLines(eventBuffer)
                            eventBuffer.removeAll()
                            if shouldTerminateStream { break }
                        } else {
                            eventBuffer.append(line)

                            // Some guest streams omit blank delimiters and send each JSON event on a single line.
                            // If the current buffer already looks like a complete JSON object, process it immediately.
                            if trimmed.contains("{"), trimmed.contains("}") {
                                processEventLines(eventBuffer)
                                eventBuffer.removeAll()
                                if shouldTerminateStream { break }
                            }
                        }
                    }

                    // Process any remaining buffered event lines
                    if !eventBuffer.isEmpty {
                        processEventLines(eventBuffer)
                        eventBuffer.removeAll()
                    }

                    // Stream finished - persist assistant message if needed
                    if shouldSaveAssistant, let assistantId = assistantMessageId, let chatRepo = Optional(self.chatRepository) {
                        if let assistant = messages.first(where: { $0.id == assistantId }) {
                            _ = try? await chatRepo.addMessage(
                                toConversation: activeConversationId,
                                content: assistant.content,
                                isUserMessage: false,
                                sources: assistant.sources
                            )
                        }
                    }

                    isLoading = false
                    return
                }

                // Non-guest (authenticated) flow: use the unified SendMessageUseCase
                let result = try await sendMessageUseCase.execute(
                    conversationId: activeConversationId,
                    message: messageText
                )

                AppLogger.chat.logInfo("Message sent successfully, thread ID: \(result.conversation.threadId ?? "nil")")

                // Update thread ID if needed (SendMessageUseCase may have updated it already when appropriate)
                if threadId == nil {
                    threadId = result.conversation.threadId
                    AppLogger.chat.logDebug("Updated thread ID to: \(result.conversation.threadId ?? "nil")")
                }

                // Reload messages to replace optimistic message with real ones
                await loadMessages()

                isLoading = false
                thinkingMessages.removeAll()

            } catch {
                AppLogger.chat.logError("Failed to send message", error: error)
                handleError(error)
                isLoading = false
                thinkingMessages.removeAll()

                // Remove optimistic message and put text back in input field
                if let optimisticId = optimisticMessageId,
                   let index = messages.firstIndex(where: { $0.id == optimisticId }) {
                    messages.remove(at: index)
                }
                inputText = messageText
            }
        }
    }

    /// Creates or fetches a conversation for a new outgoing message
    private func ensureConversationForSend(firstMessage: String) async throws -> String {
        if let existingId = conversationId,
           let existingConversation = try? await chatRepository.fetchConversation(byId: existingId) {
            // If this conversation already has history but no threadId, fall back to server conversation id for continuity
            if threadId == nil,
               existingConversation.hasMessages,
               existingConversation.isLocalOnly == false {
                threadId = existingConversation.threadId ?? existingConversation.id
                if let tid = threadId {
                    AppLogger.chat.logInfo("ensureConversationForSend - assigning fallback threadId \(tid) for existing conversation \(existingId)")
                    try? await chatRepository.updateConversationThreadId(id: existingId, threadId: tid)
                }
            }
            AppLogger.chat.logDebug("ensureConversationForSend - reusing conversation \(existingId) threadId:\(threadId ?? "nil")")
            return existingConversation.id
        }

        let title = generateTitle(from: firstMessage)
        let conversation = try await chatRepository.createConversation(
            title: title,
            isLocalOnly: isGuest
        )
        conversationId = conversation.id
        threadId = conversation.threadId
        AppLogger.chat.logInfo("ensureConversationForSend - created conversation \(conversation.id) threadId:\(conversation.threadId ?? "nil") isLocalOnly:\(conversation.isLocalOnly)")
        onConversationIdChange?(conversation.id)
        AppLogger.chat.logInfo("Created conversation \(conversation.id) for first message")
        return conversation.id
    }

    /// Generates a safe conversation title from the first message
    private func generateTitle(from message: String) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "New Conversation" }
        let maxLength = 50
        return trimmed.count > maxLength
        ? String(trimmed.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
        : trimmed
    }

    private func persistThreadIdIfNeeded() async {
        guard let newThreadId = threadId,
              let conversationId = conversationId else { return }
        do {
            if let conversation = try await chatRepository.fetchConversation(byId: conversationId) {
                try await chatRepository.updateConversationThreadId(id: conversationId, threadId: newThreadId)
                AppLogger.chat.logInfo("Persisted threadId \(newThreadId) for conversation \(conversationId)")
            }
        } catch {
            AppLogger.chat.logError("Failed to persist threadId \(threadId ?? "nil") for conversation \(conversationId)", error: error)
        }
    }

    /// Loads messages for the current conversation
    func loadMessages() async {
        guard let conversationId = conversationId else {
            AppLogger.chat.logDebug("loadMessages called with no conversationId - showing empty chat")
            messages = []
            return
        }

        AppLogger.chat.logDebug("Loading messages for conversation: \(conversationId)")

        do {
            let fetchedMessages = try await chatRepository.fetchMessages(
                forConversation: conversationId
            )
            AppLogger.chat.logDebug("Fetched \(fetchedMessages.count) messages from repository")

            let hasOptimisticMessages = messages.contains { $0.id.hasPrefix("temp-") }

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
                let optimisticCount = mergedMessages.count - fetchedMessages.count
                AppLogger.chat.logInfo("Loaded \(messages.count) messages (\(fetchedMessages.count) persisted, \(optimisticCount) optimistic)")
            } else {
                messages = fetchedMessages
                AppLogger.chat.logInfo("Loaded \(fetchedMessages.count) messages")
            }

            // Also update thread ID from conversation
            if let conversation = try await chatRepository.fetchConversation(byId: conversationId) {
                if let fetchedThreadId = conversation.threadId {
                    threadId = fetchedThreadId
                    AppLogger.chat.logInfo("loadMessages - applied threadId from conversation: \(fetchedThreadId)")
                } else if !conversation.isLocalOnly, !fetchedMessages.isEmpty {
                    // Fallback: use server conversation id as thread id when history exists but threadId is missing
                    threadId = conversationId
                    AppLogger.chat.logInfo("loadMessages - threadId missing; defaulting to conversationId for continuity: \(conversationId)")
                    try? await chatRepository.updateConversationThreadId(id: conversationId, threadId: conversationId)
                }
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
            if case .httpError(let status) = networkError, status == 401 || status == 403 {
                requiresAuth = true
            } else if case .httpError(let status) = networkError, status == 429 {
                errorMessage = LocalizationKeys.networkTooManyRequests
            }
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

        if isRunningTests {
            showImageSourceSheet = true
            return
        }

        refreshCameraPermissionStatus()

        switch cameraPermission {
        case .authorized:
            showImageSourceSheet = true
        case .notDetermined, .unknown:
            requestCameraPermission()
        case .denied, .restricted:
            showCameraPermissionDenied = true
        }

        // For UI tests, if denied is simulated, ensure we still show guidance after tap
        if isUITesting,
           cameraPermissionOverride == .denied {
            showCameraPermissionDenied = true
            showImageSourceSheet = false
        }
    }

    /// Selects camera as image source
    func selectCamera() {
        AppLogger.ocr.logInfo("Camera selected as image source")

        if isRunningTests {
            showCameraPicker = true
            showImageSourceSheet = false
            injectTestOCRConfirmation()
            return
        }

        // Prevent crashes on simulators where the camera source is unavailable.
        // In UI tests we only need the tap to succeed; skipping the picker is fine.
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            AppLogger.ocr.logWarning("Camera source not available on this device/simulator; skipping picker")
            showCameraPicker = false
            // In UI tests, immediately simulate an image to keep the flow moving
            if isUITesting {
                provideTestImageAndMaybeMockOCR()
            }
            return
        }

        refreshCameraPermissionStatus()
        guard cameraPermission == .authorized else {
            showCameraPermissionDenied = true
            return
        }

        showCameraPicker = true

        // In UI tests, bypass picker UI and provide a placeholder image
        if isUITesting {
            provideTestImageAndMaybeMockOCR()
            showCameraPicker = false
        }
    }

    /// Selects photo library as image source
    func selectPhotoLibrary() {
        AppLogger.ocr.logInfo("Photo library selected as image source")
        if isRunningTests {
            showPhotoLibraryPicker = true
            showImageSourceSheet = false
            injectTestOCRConfirmation()
            return
        }
        refreshPhotoLibraryPermissionStatus()

        switch photoLibraryPermission {
        case .authorized:
            showPhotoLibraryPicker = true
        case .notDetermined, .unknown:
            requestPhotoLibraryPermission()
        case .denied, .restricted:
            showPhotoPermissionDenied = true
        }

        // In UI tests, bypass picker UI and provide a placeholder image
        if isUITesting {
            provideTestImageAndMaybeMockOCR()
            showPhotoLibraryPicker = false
        }
    }

    /// Processes image with OCR and shows confirmation dialog
    private func handleSelectedImage(_ image: UIImage) async {
        // In UI tests with a simulated success flag, bypass real OCR and inject mocked values
        if isUITesting && simulateOCRSuccess {
            applyMockedOCRResult(using: image)
            return
        }

        await processImageWithOCR(image)
    }

    private func applyMockedOCRResult(using image: UIImage) {
        let mockedText = simulatedOCRText ?? "Sample extracted text"
        let mockedLanguage = simulatedOCRLanguage
        let data = image.jpegData(compressionQuality: 0.8)

        ocrExtractedText = mockedText
        ocrDetectedLanguage = mockedLanguage
        ocrImageData = data
        showOCRConfirmation = true
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
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            AppLogger.chat.logDebug("Attempted to send empty fact-check message, ignoring")
            return
        }

        AppLogger.chat.logInfo("Sending fact-check message: '\(trimmedText.prefix(50))...' in conversation: \(conversationId ?? "new-conversation")")

        var optimisticMessageId: String?

        do {
            let activeConversationId = try await ensureConversationForSend(firstMessage: trimmedText)

            // Create optimistic user message with fact-check metadata
            let optimisticUserMessage = Message(
                id: "temp-\(UUID().uuidString)",
                conversationId: activeConversationId,
                content: trimmedText,
                isUserMessage: true,
                timestamp: Date(),
                sources: [],
                imageData: imageData,
                detectedLanguage: detectedLanguage,
                isFactCheckMessage: true
            )
            messages.append(optimisticUserMessage)
            optimisticMessageId = optimisticUserMessage.id
            AppLogger.chat.logDebug("Added optimistic fact-check user message to UI")

            isLoading = true
            error = nil
            errorMessage = nil

            // Save user message with fact-check metadata to database
            let savedUserMessage = try await chatRepository.addFactCheckMessage(
                toConversation: activeConversationId,
                content: trimmedText,
                isUserMessage: true,
                sources: [],
                imageData: imageData,
                detectedLanguage: detectedLanguage,
                isFactCheckMessage: true
            )

            AppLogger.chat.logInfo("Saved fact-check message to database: \(savedUserMessage.id)")

            // Wrap the text for API with fact-check prompt
            let factCheckPrompt = """
            Fact check this. If it is a Hadith, Quran, or other book reference, provide a definitive Yes/No answer regarding whether it was found in verified sources.
            Especially if the text contains citations (e.g., file names or numbers), specifically verify those references against the actual text.
            Your goal is to clarify the context and veracity of the shared text to remove any confusion.
            
            Text to check:
            \(trimmedText)
            """

            // Send to API (don't save user message again - we already saved it with metadata)
            let result = try await sendMessageUseCase.execute(
                conversationId: activeConversationId,
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
            handleError(error)
            isLoading = false

            // Remove optimistic message on error
            if let optimisticId = optimisticMessageId,
               let index = messages.firstIndex(where: { $0.id == optimisticId }) {
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

    /// Opens the app Settings so the user can enable permissions
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
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

    // MARK: - Permissions

    private func refreshCameraPermissionStatus() {
        if let override = cameraPermissionOverride {
            cameraPermission = override
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermission = CameraPermissionState(fromAVStatus: status)
    }

    private func refreshPhotoLibraryPermissionStatus() {
        if let override = photoPermissionOverride {
            photoLibraryPermission = override
            return
        }
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photoLibraryPermission = CameraPermissionState(fromPhotoStatus: status)
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                self?.cameraPermission = granted ? .authorized : .denied
                if granted {
                    self?.showImageSourceSheet = true
                } else {
                    self?.showCameraPermissionDenied = true
                }
            }
        }
    }

    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            Task { @MainActor in
                self?.photoLibraryPermission = CameraPermissionState(fromPhotoStatus: status)
                switch status {
                case .authorized, .limited:
                    self?.showPhotoLibraryPicker = true
                case .denied, .restricted:
                    self?.showPhotoPermissionDenied = true
                default:
                    break
                }
            }
        }
    }

    /// Allows UI tests to simulate permission denial without hitting system dialogs.
    private func applyUITestPermissionOverrides() {
        guard isUITesting else { return }
        let env = ProcessInfo.processInfo.environment

        if env["SIMULATE_CAMERA_PERMISSION_DENIED"] == "true" {
            cameraPermissionOverride = .denied
            cameraPermission = .denied
        }

        if env["SIMULATE_PHOTO_PERMISSION_DENIED"] == "true" {
            photoPermissionOverride = .denied
            photoLibraryPermission = .denied
        }
    }

    /// For UI tests, provide a placeholder image and optionally mock OCR success/failure
    private func provideTestImageAndMaybeMockOCR() {
        // Create a tiny 1x1 pixel image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 2, height: 2)))
        }
        selectedImage = image

        let env = ProcessInfo.processInfo.environment
        if env["SIMULATE_OCR_SUCCESS"] == "true" {
            let mockedText = env["OCR_EXTRACTED_TEXT"] ?? "Sample extracted text"
            let mockedLanguage = env["OCR_DETECTED_LANGUAGE"] ?? "English"
            let data = image.jpegData(compressionQuality: 0.8)

            ocrExtractedText = mockedText
            ocrDetectedLanguage = mockedLanguage
            ocrImageData = data
            showOCRConfirmation = true
        }
    }

    private func injectTestOCRConfirmation() {
        // Provide deterministic OCR confirmation for UI tests without user media selection
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 2, height: 2)))
        }
        selectedImage = image
        ocrExtractedText = simulatedOCRText ?? "Sample extracted text"
        ocrDetectedLanguage = simulatedOCRLanguage ?? "English"
        ocrImageData = image.jpegData(compressionQuality: 0.8)
        showOCRConfirmation = true
    }
}

// MARK: - Permission State Helper

enum CameraPermissionState: Equatable {
    case unknown
    case notDetermined
    case authorized
    case denied
    case restricted

    init(fromAVStatus status: AVAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .authorized: self = .authorized
        case .denied: self = .denied
        case .restricted: self = .restricted
        @unknown default: self = .unknown
        }
    }

    init(fromPhotoStatus status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .authorized, .limited: self = .authorized
        case .denied: self = .denied
        case .restricted: self = .restricted
        @unknown default: self = .unknown
        }
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
            apiClient: nil,
            isGuest: false,
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
    func fetchMostRecentEmptyConversation(includeLocalOnly: Bool = false) async throws -> Conversation? {
        return nil
    }
    
    var conversationsPublisher: AnyPublisher<[Conversation], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func createConversation(title: String, isLocalOnly: Bool = false) async throws -> Conversation {
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

    func syncRemoteConversations() async throws {}

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

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
    @Published var isAwaitingFirstResponseChunk: Bool = false

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

    /// Whether the backend should stream chain-of-thought progress and use the thinking
    /// model. Was hardcoded `true` in every request and unreachable by users; it is a real
    /// switch — it controls both the `{"type":"thinking"}` events and which model runs
    /// (`thinking_llm` vs `generation_llm`, services/graph_interface.py).
    @Published var enableThinking: Bool = ChatViewModel.loadThinkingPreference()

    /// `image_url` returned by /api/chat/ocr, reused by the confirm turn so the image is
    /// uploaded once rather than twice.
    private var resolvedFactCheckImageUrl: String?
    @Published var cameraPermission: CameraPermissionState = .unknown
    @Published var photoLibraryPermission: CameraPermissionState = .unknown
    @Published var showCameraPermissionDenied: Bool = false
    @Published var showPhotoPermissionDenied: Bool = false

    // Fact-checking properties
    @Published var showOCRConfirmation: Bool = false
    @Published var ocrExtractedText: String = ""
    @Published var ocrDetectedLanguage: String?
    @Published var ocrImageData: Data?
    @Published private(set) var modePreference: Int = ModePreference.research
    @Published private(set) var isModePreferenceLoading: Bool = false

    // MARK: - Sharing

    /// Whether this conversation is publicly viewable. Mirrors `is_shared` on the
    /// server; never optimistic beyond the in-flight request (see `setSharing`).
    @Published private(set) var isShared: Bool = false

    /// True while a GET/PUT of the share status is in flight. Drives the spinner
    /// and disables the toggle so a double tap cannot race two PUTs.
    @Published private(set) var isSharePopoverLoading: Bool = false

    /// Canonical public link, already run through `ShareLink.normalize`.
    /// `nil` whenever the conversation is not shared, so the copy button has
    /// nothing to hand out.
    @Published private(set) var shareURL: String?

    // MARK: - Private Properties

    private let sendMessageUseCase: SendMessageUseCaseProtocol
    private let chatRepository: ChatRepository
    private let apiClient: APIClientProtocol?
    private let authRepository: AuthRepository?
    let isGuest: Bool
    private let onConversationIdChange: ((String?) -> Void)?
    private let voiceInputManager: any VoiceInputManagerProtocol
    private let ocrManager: any OCRManagerProtocol
    private let streamingHandler: StreamingMessageHandlerProtocol
    private var cancellables = Set<AnyCancellable>()
    private let isUITesting: Bool
    private let isUIAutomationTesting: Bool
    private let isRunningTests: Bool
    private let guestSessionId: String?
    private var cameraPermissionOverride: CameraPermissionState?
    private var photoPermissionOverride: CameraPermissionState?
    private let simulateOCRSuccess: Bool
    private let simulateOCRNoText: Bool
    private let simulateOCRInvalidImage: Bool
    private let simulateOCRError: Bool
    private let simulatedOCRText: String?
    private let simulatedOCRLanguage: String?
    private var forceGuestForConversation: Bool
    private static var factCheckRequiresImageUrl: Bool = false
    private enum ModePreference {
        static let research = 1
        static let factCheck = 2
    }

    // MARK: - Initialization

    init(
        conversationId: String?,
        sendMessageUseCase: SendMessageUseCaseProtocol,
        chatRepository: ChatRepository,
        apiClient: APIClientProtocol? = nil,
        authRepository: AuthRepository? = nil,
        isGuest: Bool = false,
        guestSessionId: String? = nil,
        voiceInputManager: any VoiceInputManagerProtocol,
        ocrManager: any OCRManagerProtocol,
        streamingHandler: StreamingMessageHandlerProtocol? = nil,
        onConversationIdChange: ((String?) -> Void)? = nil
    ) {
        self.conversationId = conversationId
        self.guestSessionId = guestSessionId
        self.sendMessageUseCase = sendMessageUseCase
        self.chatRepository = chatRepository
        self.apiClient = apiClient
        self.authRepository = authRepository
        self.isGuest = isGuest
        self.onConversationIdChange = onConversationIdChange
        self.voiceInputManager = voiceInputManager
        self.ocrManager = ocrManager
        self.streamingHandler = streamingHandler ?? StreamingMessageHandler()
        let env = ProcessInfo.processInfo.environment
        let hasXCTestConfig = env["XCTestConfigurationFilePath"] != nil
        self.isUIAutomationTesting = env["UI_TESTING"] == "1"
        self.isUITesting = self.isUIAutomationTesting || hasXCTestConfig
        self.isRunningTests = hasXCTestConfig
        self.simulateOCRSuccess = env["SIMULATE_OCR_SUCCESS"] == "true"
        self.simulateOCRNoText = env["SIMULATE_OCR_NO_TEXT"] == "true"
        self.simulateOCRInvalidImage = env["SIMULATE_OCR_INVALID_IMAGE"] == "true"
        self.simulateOCRError = env["SIMULATE_OCR_ERROR"] == "true"
        self.simulatedOCRText = env["OCR_EXTRACTED_TEXT"]
        self.simulatedOCRLanguage = env["OCR_DETECTED_LANGUAGE"]
        self.forceGuestForConversation = isGuest

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
        
        // DEBUG: Clear any lingering error state in UI tests to prevent screenshots showing error banners
        if isUITesting {
            AppLogger.chat.logDebug("UI_TESTING: Clearing any existing error state on ChatViewModel init")
            self.error = nil
            self.errorMessage = nil
            AppLogger.chat.logDebug("UI_TESTING: Error state cleared - error: \(self.error?.localizedDescription ?? "nil"), errorMessage: \(self.errorMessage ?? "nil")")
        }

        if canToggleModePreference {
            Task {
                await loadModePreference()
            }
        }
    }

    // MARK: - Public Methods

    var canToggleModePreference: Bool {
        guard !isGuest, let authRepository else { return false }
        return authRepository.isLoggedIn()
    }

    var isFactCheckModeEnabled: Bool {
        modePreference == ModePreference.factCheck
    }

    func toggleModePreference() {
        let nextMode = isFactCheckModeEnabled ? ModePreference.research : ModePreference.factCheck
        Task {
            await updateModePreference(nextMode)
        }
    }

    func loadModePreference() async {
        guard let authRepository else {
            AppLogger.chat.logDebug("Skipping mode preference load: auth repository unavailable")
            return
        }
        guard !isGuest else {
            AppLogger.chat.logDebug("Skipping mode preference load: guest session")
            return
        }
        guard authRepository.isLoggedIn() else {
            AppLogger.auth.logInfo(
                prefix: AppLogger.LogPrefix.authState,
                "event=modePreference.load.skipped reason=notAuthenticated"
            )
            return
        }
        isModePreferenceLoading = true
        defer { isModePreferenceLoading = false }
        do {
            let response = try await authRepository.getModePreference()
            modePreference = response.modePreference
        } catch {
            AppLogger.chat.logWarning("Failed to load mode preference reason=\(type(of: error))")
            errorMessage = ChatOperationError.warningMessage(for: .modePreference)
        }
    }

    func updateModePreference(_ mode: Int) async {
        guard let authRepository else {
            AppLogger.chat.logDebug("Skipping mode preference update: auth repository unavailable")
            return
        }
        guard !isGuest else {
            AppLogger.chat.logDebug("Skipping mode preference update: guest session")
            return
        }
        guard authRepository.isLoggedIn() else {
            AppLogger.auth.logInfo(
                prefix: AppLogger.LogPrefix.authState,
                "event=modePreference.update.skipped reason=notAuthenticated requestedMode=\(mode)"
            )
            return
        }
        isModePreferenceLoading = true
        defer { isModePreferenceLoading = false }
        do {
            let response = try await authRepository.setModePreference(ModePreferenceRequest(modePreference: mode))
            modePreference = response.modePreference
        } catch {
            AppLogger.chat.logWarning("Failed to update mode preference reason=\(type(of: error))")
            errorMessage = ChatOperationError.warningMessage(for: .modePreference)
        }
    }

    // MARK: - Sharing

    /// Whether the share control should be offered at all.
    ///
    /// Sharing publishes a *persisted, owned* conversation: `PUT /api/conversations/{id}/share`
    /// is auth-protected, and a brand-new chat has no id to publish yet. Guests fail
    /// both tests, so they never see the control.
    var canShareConversation: Bool {
        guard !isGuest, let authRepository, authRepository.isLoggedIn() else { return false }
        guard let conversationId, !conversationId.trimmed.isEmpty else { return false }
        return true
    }

    /// Seeds the toggle from the server when the popover opens.
    ///
    /// WHY: the conversation may already be shared from the web app or a previous
    /// session. Assuming `false` would show a private-looking switch for a chat that
    /// is in fact public — the most dangerous direction for this control to lie in.
    func loadShareStatus() async {
        guard canShareConversation, let conversationId else { return }

        isSharePopoverLoading = true
        defer { isSharePopoverLoading = false }

        do {
            let status = try await chatRepository.conversationShareStatus(id: conversationId)
            isShared = status.isShared
            shareURL = status.isShared
                ? ShareLink.normalize(status.shareUrl, conversationId: conversationId)
                : nil
        } catch {
            AppLogger.chat.logWarning("Failed to load share status reason=\(type(of: error))")
            errorMessage = ChatOperationError.warningMessage(for: .shareStatus)
        }
    }

    /// Publishes or unpublishes the conversation.
    ///
    /// The toggle moves optimistically so the switch feels instant, then snaps back
    /// if the PUT is rejected. Leaving it "on" after a failure would tell the user a
    /// private conversation is public.
    func setSharing(_ enabled: Bool) async {
        guard canShareConversation, let conversationId else { return }
        guard !isSharePopoverLoading else { return }

        let previousIsShared = isShared
        let previousShareURL = shareURL
        guard previousIsShared != enabled else { return }

        isShared = enabled
        isSharePopoverLoading = true
        defer { isSharePopoverLoading = false }

        do {
            let serverURL = try await chatRepository.setConversationShared(id: conversationId, isShared: enabled)
            isShared = enabled
            // The server URL is preferred but not trusted verbatim: an older backend
            // still emits the legacy `/shared/<id>` path form. See `ShareLink.normalize`.
            shareURL = enabled ? ShareLink.normalize(serverURL, conversationId: conversationId) : nil
        } catch {
            isShared = previousIsShared
            shareURL = previousShareURL
            AppLogger.chat.logError(
                "Failed to update share status for conversation \(conversationId) requested=\(enabled)",
                error: error
            )
            errorMessage = ChatOperationError.warningMessage(for: .shareStatus)
        }
    }

    /// Sends a message to the assistant
    func sendMessage(prefilledMessage: String? = nil) {
        let candidateText = prefilledMessage ?? inputText
        let trimmed = candidateText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !isLoading,
              !isRecording,
              !isProcessingOCR else {
            AppLogger.chat.logDebug("SendMessage ignored: invalid state (empty=\(candidateText.isEmpty), loading=\(isLoading), recording=\(isRecording), ocr=\(isProcessingOCR))")
            return
        }

        let messageText = trimmed
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
                isAwaitingFirstResponseChunk = true
                error = nil
                errorMessage = nil
                let isGuestFlow = isGuest || forceGuestForConversation
                thinkingMessages = isGuestFlow ? [] : [LocalizationKeys.thinking.localized]

                // Guest path: use streaming SSE endpoint to receive incremental chunks
                if let apiClient = apiClient {
                    AppLogger.chat.logInfo("\(isGuestFlow ? "Guest/local" : "Authenticated") mode - streaming message via API")

                    // Optionally include a session id. Prefer a persistent guestSessionId when available,
                    // otherwise fall back to threadId or conversation id for continuity within the app session.
                    let sessionIdToUse = guestSessionId ?? threadId ?? conversationId ?? activeConversationId
                    let request = ChatRequest(
                        question: messageText,
                        threadId: threadId,
                        languagePreference: LanguageManager.shared.currentLanguage.rawValue,
                        sessionId: sessionIdToUse,
                        enableThinking: enableThinking
                    )

                    // Try to save user message locally if this conversation is local-only or authenticated (so history persists)
                    var shouldSaveAssistant = !isGuestFlow
                    if let chatRepo = Optional(self.chatRepository) {
                        if let conv = try await chatRepo.fetchConversation(byId: activeConversationId), conv.isLocalOnly {
                            shouldSaveAssistant = true
                            // Save user message locally so it's persisted for guest local-only conversations
                            _ = try await chatRepo.addMessage(
                                toConversation: activeConversationId,
                                content: messageText,
                                isUserMessage: true,
                                sources: []
                            )
                        } else if !isGuestFlow {
                            // Authenticated flow: persist user message immediately
                            _ = try await chatRepo.addMessage(
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
                    let rawStream = try await (isGuestFlow ? apiClient.streamGuestMessage(request) : apiClient.streamMessage(request))
                    let stream = try await streamingHandler.handleStream(rawStream)
                    
                    var assembled = ""
                    var assistantMessageId: String? = nil
                    var sawDone = false
                    
                    for try await event in stream {
                        switch event {
                        case .metadata(let tid):
                            if self.threadId == nil || self.threadId != tid {
                                AppLogger.chat.logInfo("Stream metadata - updating threadId to \(tid)")
                                self.threadId = tid
                            }
                        case .thinking(let text):
                            guard isAwaitingFirstResponseChunk else { break }
                            AppLogger.chat.logDebug("Stream: thinking event received: \(text)")
                            thinkingMessages = [text]
                        case .chunk(let piece):
                            if isAwaitingFirstResponseChunk {
                                isAwaitingFirstResponseChunk = false
                                thinkingMessages.removeAll()
                            }
                            assembled += piece
                            upsertAssistantMessage(content: assembled, assistantMessageId: &assistantMessageId, activeConversationId: activeConversationId)
                        case .done(let finalAnswer):
                            sawDone = true
                            if let final = finalAnswer {
                                assembled = final
                            }
                            guard !assembled.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                throw ChatOperationException(
                                    operation: .sendMessage,
                                    code: "E-CHAT-EMPTY-RESPONSE",
                                    retryable: true,
                                    description: "Stream completed without response content"
                                )
                            }
                            if isAwaitingFirstResponseChunk {
                                isAwaitingFirstResponseChunk = false
                            }
                            thinkingMessages.removeAll()
                            upsertAssistantMessage(content: assembled, assistantMessageId: &assistantMessageId, activeConversationId: activeConversationId)
                            isLoading = false
                            await persistThreadIdIfNeeded()
                        case .error(let error):
                            AppLogger.chat.logError("Stream error", error: error)
                            throw error
                        }
                    }
                    if !sawDone {
                        throw ChatOperationException(
                            operation: .sendMessage,
                            code: "E-CHAT-STREAM-INCOMPLETE",
                            retryable: true,
                            description: "Stream ended before completion"
                        )
                    }

                    // Stream finished - persist assistant message if needed
                    if shouldSaveAssistant, let assistantId = assistantMessageId, let chatRepo = Optional(self.chatRepository) {
                        if let assistant = messages.first(where: { $0.id == assistantId }) {
                            _ = try await chatRepo.addMessage(
                                toConversation: activeConversationId,
                                content: assistant.content,
                                isUserMessage: false,
                                sources: assistant.sources
                            )
                        }
                    }

                    isAwaitingFirstResponseChunk = false
                    thinkingMessages.removeAll()
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

                isAwaitingFirstResponseChunk = false
                isLoading = false
                thinkingMessages.removeAll()

            } catch {
                AppLogger.chat.logError("Failed to send message", error: error)
                handleError(error, operation: .sendMessage)
                isAwaitingFirstResponseChunk = false
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
        if let existingId = conversationId {
            guard let existingConversation = try await chatRepository.fetchConversation(byId: existingId) else {
                throw ChatOperationException(
                    operation: .loadConversation,
                    code: "E-CHAT-MISSING-CONVERSATION",
                    retryable: true,
                    description: "Conversation not found"
                )
            }
            forceGuestForConversation = existingConversation.isLocalOnly
            // If this conversation already has history but no threadId, fall back to server conversation id for continuity
            if threadId == nil,
               existingConversation.hasMessages,
               existingConversation.isLocalOnly == false {
                threadId = existingConversation.threadId ?? existingConversation.id
                if let tid = threadId {
                    AppLogger.chat.logInfo("ensureConversationForSend - assigning fallback threadId \(tid) for existing conversation \(existingId)")
                    try await chatRepository.updateConversationThreadId(id: existingId, threadId: tid)
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
        forceGuestForConversation = conversation.isLocalOnly
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
            if try await chatRepository.fetchConversation(byId: conversationId) != nil {
                try await chatRepository.updateConversationThreadId(id: conversationId, threadId: newThreadId)
                AppLogger.chat.logInfo("Persisted threadId \(newThreadId) for conversation \(conversationId)")
            }
        } catch {
            AppLogger.chat.logError("Failed to persist threadId \(threadId ?? "nil") for conversation \(conversationId)", error: error)
            errorMessage = ChatOperationError.warningMessage(for: .continuity)
        }
    }

    /// Loads messages for the current conversation
    func loadMessages() async {
        guard let conversationId = conversationId else {
            AppLogger.chat.logDebug("loadMessages called with no conversationId - showing empty chat")
            forceGuestForConversation = isGuest
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
                forceGuestForConversation = conversation.isLocalOnly
                if let fetchedThreadId = conversation.threadId {
                    threadId = fetchedThreadId
                    AppLogger.chat.logInfo("loadMessages - applied threadId from conversation: \(fetchedThreadId)")
                } else if !conversation.isLocalOnly, !fetchedMessages.isEmpty {
                    // Fallback: use server conversation id as thread id when history exists but threadId is missing
                    threadId = conversationId
                    AppLogger.chat.logInfo("loadMessages - threadId missing; defaulting to conversationId for continuity: \(conversationId)")
                    do {
                        try await chatRepository.updateConversationThreadId(id: conversationId, threadId: conversationId)
                    } catch {
                        AppLogger.chat.logError("Failed to persist fallback threadId", error: error)
                        errorMessage = ChatOperationError.warningMessage(for: .continuity)
                    }
                }
            }
        } catch {
            AppLogger.chat.logError("Failed to load messages", error: error)
            handleError(error, operation: .loadConversation)
        }
    }

    /// Updates the input text
    func updateInputText(_ text: String) {
        inputText = text
    }

    /// Clears the current error
    func clearError() {
        AppLogger.chat.logDebug("clearError called - error: \(self.error?.localizedDescription ?? "nil"), errorMessage: \(self.errorMessage ?? "nil")")
        error = nil
        errorMessage = nil
        AppLogger.chat.logDebug("clearError completed - error: \(self.error?.localizedDescription ?? "nil"), errorMessage: \(self.errorMessage ?? "nil")")
    }

    /// Returns whether the send button should be enabled
    var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isRecording && !isProcessingOCR
    }

    /// Quickly seed the chat with a suggested question from the empty state.
    func sendSuggestion(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !isLoading,
              !isRecording,
              !isProcessingOCR else {
            return
        }

        inputText = trimmed
        sendMessage(prefilledMessage: trimmed)
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
        AppLogger.voiceInput.logInfo(
            "Starting voice input deviceLocale=\(Locale.current.identifier) preferredLanguages=\(Locale.preferredLanguages.joined(separator: ",")) inputLen=\(inputText.count)"
        )

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
        AppLogger.voiceInput.logInfo("Voice input selected locale=\(locale.identifier)")

        do {
            try await voiceInputManager.startRecording(locale: locale)
            AppLogger.voiceInput.logInfo("Voice input recording started successfully with locale: \(locale.identifier)")
        } catch {
            AppLogger.voiceInput.logError("Failed to start voice input recording", error: error)
            if let voiceError = error as? VoiceInputError {
                AppLogger.voiceInput.logWarning("Voice input start failed with VoiceInputError=\(voiceError.userMessageWithCode)")
                voiceInputError = voiceError
            } else {
                errorMessage = error.userFacingMessage
            }
        }
    }

    /// Stops voice input recording
    func stopVoiceInput() {
        AppLogger.voiceInput.logInfo("Stopping voice input manually from ViewModel")
        voiceInputManager.stopRecording()
    }

    /// Clears voice input error
    func clearVoiceInputError() {
        voiceInputError = nil
        voiceInputManager.clearError()
    }

    // MARK: - Composer Options

    private static let thinkingPreferenceKey = "chat_enable_thinking"

    /// Defaults to on, matching the backend default, so behaviour is unchanged until the
    /// user opts out.
    static func loadThinkingPreference() -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: thinkingPreferenceKey) != nil else { return true }
        return defaults.bool(forKey: thinkingPreferenceKey)
    }

    func toggleThinking() {
        enableThinking.toggle()
        UserDefaults.standard.set(enableThinking, forKey: Self.thinkingPreferenceKey)
        AppLogger.chat.logInfo("thinking toggled to \(enableThinking)")
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error, operation: ChatOperation = .sendMessage) {
        AppLogger.chat.logError("handleError called with error: \(error)")
        self.error = error
        let failure = ChatOperationError.from(error, operation: operation)
        errorMessage = failure.userMessage
        if failure.requiresAuth {
            requiresAuth = true
        }
        AppLogger.chat.logInfo("Set errorMessage from ChatOperationError code=\(failure.debugCode) operation=\(operation)")
        
        // DEBUG: Log error message state for screenshot debugging
        AppLogger.chat.logDebug("ERROR STATE DEBUG - error: \(self.error?.localizedDescription ?? "nil"), errorMessage: \(self.errorMessage ?? "nil"), requiresAuth: \(self.requiresAuth)")
        
        // DEBUG: Check if we're in UI testing mode
        if isUITesting {
            AppLogger.chat.logDebug("ERROR STATE IN UI TEST - errorMessage: \(self.errorMessage ?? "nil"), this will be visible in screenshots")
        }
    }

    // MARK: - OCR Methods

    /// Handles camera button tap
    func handleCameraButtonTap() {
        AppLogger.ocr.logInfo("Camera button tapped, showing image source sheet")

        if isRunningTests {
            if cameraPermissionOverride == .denied {
                showCameraPermissionDenied = true
                showImageSourceSheet = false
            } else {
                showImageSourceSheet = true
            }
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

        if isUIAutomationTesting {
            showImageSourceSheet = false
            showCameraPicker = false
            showPhotoLibraryPicker = false
            if cameraPermissionOverride == .denied {
                showCameraPermissionDenied = true
                return
            }
            scheduleTestOCRConfirmationInjection()
            return
        }
        if isRunningTests {
            showCameraPicker = true
            showImageSourceSheet = false
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
        if isUIAutomationTesting {
            showImageSourceSheet = false
            showPhotoLibraryPicker = false
            showCameraPicker = false
            if photoPermissionOverride == .denied {
                showPhotoPermissionDenied = true
                return
            }
            scheduleTestOCRConfirmationInjection()
            return
        }
        if isRunningTests {
            showPhotoLibraryPicker = true
            showImageSourceSheet = false
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
    /// Extracts text from an image using the backend's OCR, then shows the review sheet.
    ///
    /// Apple Vision is deliberately **not** used. It only supports the languages in
    /// `VNRecognizeTextRequest.recognitionLanguages` and has **no Urdu support at all** —
    /// the supported set is fixed by the OS, so Urdu cannot be added. Every Urdu
    /// screenshot failed with "No text found in image" while the same image worked on the
    /// web, which uses the backend's vision model (`services/image_service.py`).
    ///
    /// This costs no extra round trip: the fact-check turn already needs an `image_url`
    /// from this endpoint, and the app was previously calling it purely for that while
    /// discarding `extracted_text`. One call now serves both, and the URL is cached so the
    /// image uploads once rather than twice.
    private func processImageWithOCR(_ image: UIImage) async {
        AppLogger.ocr.logInfo("Starting OCR processing for image with size: \(image.size)")

        guard let compressed = compressImage(image, maxSizeKB: 200) else {
            AppLogger.ocr.logError("Could not compress the selected image")
            ocrError = .invalidImage
            selectedImage = nil
            return
        }

        isProcessingOCR = true
        defer { isProcessingOCR = false }

        do {
            let response = try await chatRepository.ocr(
                OCRRequest(
                    imageBase64: compressed.base64EncodedString(),
                    threadId: conversationId,
                    languageHint: nil
                )
            )
            let text = response.extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                AppLogger.ocr.logWarning("Server OCR returned no text for this image")
                ocrError = .noTextFound
                selectedImage = nil
                return
            }

            AppLogger.ocr.logInfo("Server OCR extracted \(text.count) chars, language: \(response.metadata.detectedLanguage ?? "unknown")")
            ocrExtractedText = text
            ocrDetectedLanguage = response.metadata.detectedLanguage
            ocrImageData = compressed
            resolvedFactCheckImageUrl = response.imageUrl
            showOCRConfirmation = true
            selectedImage = nil
        } catch {
            // Surface the real failure rather than silently degrading to an engine that
            // cannot read the user's language.
            AppLogger.ocr.logError("Server OCR failed", error: error)
            ocrError = .recognitionFailed(error.localizedDescription)
            selectedImage = nil
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

    /// Sends a fact-check message with image data and language metadata using backend streaming
    private func sendFactCheckMessage(text: String, imageData: Data?, detectedLanguage: String?) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            AppLogger.chat.logDebug("Attempted to send empty fact-check message, ignoring")
            return
        }

            guard imageData != nil else {
                AppLogger.chat.logError("Missing image data for fact-checking", error: nil)
                handleError(
                    ChatOperationException(
                        operation: .factCheck,
                        code: "E-CHAT-FACT-MISSING-IMAGE",
                        retryable: true,
                        description: "Missing image data"
                    ),
                    operation: .factCheck
                )
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
            isAwaitingFirstResponseChunk = true
            error = nil
            errorMessage = nil

            // Save user message locally
            _ = try await chatRepository.addFactCheckMessage(
                toConversation: activeConversationId,
                content: trimmedText,
                isUserMessage: true,
                sources: [],
                imageData: imageData,
                detectedLanguage: detectedLanguage,
                isFactCheckMessage: true
            )

            var resolvedImageUrl: String? = nil
            if Self.factCheckRequiresImageUrl {
                resolvedImageUrl = try await resolveFactCheckImageUrl(
                    imageData: imageData,
                    threadId: threadId,
                    languageHint: detectedLanguage
                )
            }

            var assembled = ""
            var assistantMessageId: String? = nil
            var retriedWithUploadedImage = false
            while true {
                do {
                    // Start backend fact-check stream; upload image only when required by backend validation.
                    let request = ConfirmFactCheckRequest(
                        reviewedText: trimmedText,
                        imageUrl: resolvedImageUrl,
                        imageBase64: nil,
                        threadId: threadId,
                        languagePreference: LanguageManager.shared.currentLanguage.rawValue,
                        enableThinking: enableThinking
                    )

                    let rawStream = try await chatRepository.confirmFactCheck(request)
                    let stream = try await streamingHandler.handleStream(rawStream)

                    assembled = ""
                    assistantMessageId = nil
                    var sawDone = false

                    for try await event in stream {
                        switch event {
                        case .metadata(let tid):
                            threadId = tid
                        case .thinking(let text):
                            guard isAwaitingFirstResponseChunk else { break }
                            AppLogger.chat.logDebug("Fact-check stream: thinking event received: \(text)")
                            thinkingMessages = [text]
                        case .chunk(let piece):
                            if isAwaitingFirstResponseChunk {
                                isAwaitingFirstResponseChunk = false
                                thinkingMessages.removeAll()
                            }
                            assembled += piece
                            upsertAssistantMessage(content: assembled, assistantMessageId: &assistantMessageId, activeConversationId: activeConversationId)
                        case .done(let finalAnswer):
                            sawDone = true
                            if let final = finalAnswer {
                                assembled = final
                            }
                            guard !assembled.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                throw ChatOperationException(
                                    operation: .factCheck,
                                    code: "E-CHAT-FACT-EMPTY-RESPONSE",
                                    retryable: true,
                                    description: "Fact-check stream completed without response content"
                                )
                            }
                            if isAwaitingFirstResponseChunk {
                                isAwaitingFirstResponseChunk = false
                            }
                            thinkingMessages.removeAll()
                            upsertAssistantMessage(content: assembled, assistantMessageId: &assistantMessageId, activeConversationId: activeConversationId)
                            isLoading = false
                        case .error(let error):
                            AppLogger.chat.logError("Fact-check stream error", error: error)
                            throw error
                        }
                    }
                    if !sawDone {
                        throw ChatOperationException(
                            operation: .factCheck,
                            code: "E-CHAT-FACT-INCOMPLETE",
                            retryable: true,
                            description: "Fact-check stream ended before completion"
                        )
                    }

                    if resolvedImageUrl == nil {
                        Self.factCheckRequiresImageUrl = false
                    }
                    break
                } catch {
                    if !retriedWithUploadedImage &&
                        resolvedImageUrl == nil &&
                        isMissingImageUrlValidation(error) {
                        AppLogger.chat.logInfo("Backend requires image_url for fact-check; retrying after OCR upload")
                        Self.factCheckRequiresImageUrl = true
                        resolvedImageUrl = try await resolveFactCheckImageUrl(
                            imageData: imageData,
                            threadId: threadId,
                            languageHint: detectedLanguage
                        )
                        retriedWithUploadedImage = true
                        continue
                    }
                    throw error
                }
            }

            // Persist final message
            if let aid = assistantMessageId, let assistant = messages.first(where: { $0.id == aid }) {
                _ = try await chatRepository.addMessage(
                    toConversation: activeConversationId,
                    content: assistant.content,
                    isUserMessage: false,
                    sources: assistant.sources
                )
            }

            isAwaitingFirstResponseChunk = false
            thinkingMessages.removeAll()
            isLoading = false

        } catch {
            AppLogger.chat.logError("Fact-check stream failed", error: error)
            handleError(error, operation: .factCheck)
            isAwaitingFirstResponseChunk = false
            isLoading = false
            thinkingMessages.removeAll()

            if let optimisticId = optimisticMessageId,
               let index = messages.firstIndex(where: { $0.id == optimisticId }) {
                messages.remove(at: index)
            }
        }
    }

    private func resolveFactCheckImageUrl(
        imageData: Data?,
        threadId: String?,
        languageHint: String?
    ) async throws -> String {
        guard let imageData = imageData, !imageData.isEmpty else {
            throw NetworkError.invalidResponse
        }

        // The OCR step already uploaded this image and returned a URL; re-uploading costs
        // a second round trip and leaves a duplicate object in S3.
        if let cached = resolvedFactCheckImageUrl, !cached.isEmpty {
            AppLogger.chat.logInfo("Reusing image_url from the OCR step")
            return cached
        }

        AppLogger.chat.logInfo("Uploading fact-check image to resolve image_url")
        let ocrRequest = OCRRequest(
            imageBase64: imageData.base64EncodedString(),
            threadId: threadId,
            languageHint: languageHint
        )
        let ocrResponse = try await chatRepository.ocr(ocrRequest)
        let trimmedUrl = ocrResponse.imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUrl.isEmpty else {
            throw NetworkError.invalidResponse
        }
        return trimmedUrl
    }

    private func isMissingImageUrlValidation(_ error: Error) -> Bool {
        if case NetworkError.httpError(let statusCode) = error {
            return statusCode == 422
        }
        return error.localizedDescription.localizedCaseInsensitiveContains("image_url")
    }

    private func upsertAssistantMessage(content: String, assistantMessageId: inout String?, activeConversationId: String) {
        if let id = assistantMessageId, let idx = messages.firstIndex(where: { $0.id == id }) {
            // Update existing assistant message in place
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
        } else {
            // Create a new assistant message
            let newId = assistantMessageId ?? UUID().uuidString
            assistantMessageId = newId
            
            let assistant = Message(
                id: newId,
                conversationId: activeConversationId,
                content: content,
                isUserMessage: false,
                timestamp: Date(),
                sources: []
            )
            messages.append(assistant)
        }
    }

    /// Dismisses OCR confirmation dialog
    func dismissOCRConfirmation() {
        showOCRConfirmation = false
        resolvedFactCheckImageUrl = nil
        ocrExtractedText = ""
        ocrDetectedLanguage = nil
        ocrImageData = nil
    }

    /// Handles a fact-check payload imported via extension deep link.
    func handleImportedFactCheckIfAvailable() {
        guard let payload = FactCheckImportManager.shared.consume() else {
            if FactCheckImportManager.shared.consumeImportFailure() {
                handleError(
                    ChatOperationException(
                        operation: .shareImport,
                        code: "E-CHAT-SHARE-MISSING",
                        retryable: true,
                        description: "Missing shared fact-check payload"
                    ),
                    operation: .shareImport
                )
            }
            return
        }

        Task {
            let importedText = payload.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            // Android parity:
            // 1) If image exists -> run OCR and present confirmation sheet (do not auto-send).
            // 2) If only text exists -> prefill input (do not auto-send).
            if let data = payload.imageData, let image = UIImage(data: data) {
                do {
                    // Same reasoning as processImageWithOCR: server OCR, never Vision.
                    await processImageWithOCR(image)
                    guard showOCRConfirmation else { return }
                    AppLogger.chat.logInfo("Imported image payload prepared for OCR confirmation")
                    return
                } catch {
                    AppLogger.chat.logError("Failed to OCR imported fact-check image", error: error)
                    ocrError = .recognitionFailed(error.localizedDescription)
                    return
                }
            }

            if !importedText.isEmpty {
                inputText = importedText
                AppLogger.chat.logInfo("Imported text payload applied to chat input")
                return
            }

            AppLogger.chat.logWarning("Imported fact-check payload was empty; no action taken")
        }
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
        if simulateOCRNoText {
            ocrError = .noTextFound
            return
        }
        if simulateOCRInvalidImage {
            ocrError = .invalidImage
            return
        }
        if simulateOCRError {
            ocrError = .recognitionFailed("Simulated OCR failure")
            return
        }

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

    /// Defers OCR confirmation presentation to the next run loop so source-sheet dismissal can complete.
    private func scheduleTestOCRConfirmationInjection() {
        DispatchQueue.main.async { [weak self] in
            self?.injectTestOCRConfirmation()
        }
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

    func syncRemoteConversations(forceRefresh: Bool) async throws {}

    func setConversationShared(id: String, isShared: Bool) async throws -> String? {
        return isShared ? "https://shamelagpt.com/shared?chatid=\(id)" : nil
    }

    func conversationShareStatus(id: String) async throws -> ShareStatusResponse {
        return ShareStatusResponse(conversationId: id, isShared: false, shareUrl: nil)
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

    func fetchMessages(forConversation conversationId: String, forceRefresh: Bool) async throws -> [Message] {
        return [Message.preview, Message.previewAssistant]
    }

    func updateMessageContent(id: String, content: String) async throws {}

    func deleteMessage(id: String) async throws {}

    func ocr(_ request: OCRRequest) async throws -> OCRResponse {
        return OCRResponse(
            extractedText: "Mock extracted text",
            imageUrl: "https://example.com/image.jpg",
            metadata: OCRMetadata(success: true, detectedLanguage: "English", confidence: "0.99", textLength: 19)
        )
    }

    func confirmFactCheck(_ request: ConfirmFactCheckRequest) async throws -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            continuation.yield("data: {\"type\": \"chunk\", \"content\": \"Mock answer\"}")
            continuation.yield("data: {\"type\": \"done\", \"full_answer\": \"Mock answer\"}")
            continuation.finish()
        }
    }
}
#endif

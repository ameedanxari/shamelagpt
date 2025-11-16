//
//  SendMessageUseCase.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine

/// Use case for sending a message and handling the response
final class SendMessageUseCase {

    // MARK: - Result Type

    struct Result {
        let userMessage: Message
        let assistantMessage: Message
        let conversation: Conversation
    }

    // MARK: - Properties

    private let chatRepository: ChatRepository
    private let apiClient: APIClientProtocol
    private let networkMonitor: NetworkMonitorProtocol

    // MARK: - Initialization

    init(
        chatRepository: ChatRepository,
        apiClient: APIClientProtocol,
        networkMonitor: NetworkMonitorProtocol
    ) {
        self.chatRepository = chatRepository
        self.apiClient = apiClient
        self.networkMonitor = networkMonitor
    }

    // MARK: - Execution

    /// Executes the use case to send a message
    /// - Parameters:
    ///   - conversationId: The ID of the conversation to send the message to
    ///   - message: The message content from the user
    ///   - imageData: Optional image data for fact-check messages
    ///   - detectedLanguage: Optional detected language code
    ///   - isFactCheckMessage: Whether this is a fact-check message
    ///   - saveUserMessage: Whether to save the user message (false for fact-check messages where it's already saved)
    /// - Returns: Result containing the user message, assistant response, and updated conversation
    /// - Throws: NetworkError or repository errors
    func execute(
        conversationId: String,
        message: String,
        imageData: Data? = nil,
        detectedLanguage: String? = nil,
        isFactCheckMessage: Bool = false,
        saveUserMessage: Bool = true
    ) async throws -> Result {
        AppLogger.chat.logInfo("SendMessageUseCase.execute called with conversationId: \(conversationId)")

        // Fetch the conversation to get thread ID
        guard let conversation = try await chatRepository.fetchConversation(byId: conversationId) else {
            AppLogger.chat.logError("Conversation not found in local database: \(conversationId)")
            throw ChatRepositoryError.conversationNotFound
        }

        AppLogger.chat.logInfo("Conversation found, threadId: \(conversation.threadId ?? "nil")")
        let shouldSendAsGuest = conversation.isLocalOnly

        // Save user message locally first (unless it's a fact-check message already saved)
        let userMessage: Message
        if saveUserMessage {
            AppLogger.chat.logDebug("Saving user message locally")
            
            if isFactCheckMessage || imageData != nil {
                userMessage = try await chatRepository.addFactCheckMessage(
                    toConversation: conversationId,
                    content: message,
                    isUserMessage: true,
                    sources: [],
                    imageData: imageData,
                    detectedLanguage: detectedLanguage,
                    isFactCheckMessage: isFactCheckMessage
                )
            } else {
                userMessage = try await chatRepository.addMessage(
                    toConversation: conversationId,
                    content: message,
                    isUserMessage: true,
                    sources: []
                )
            }
            AppLogger.chat.logInfo("User message saved with ID: \(userMessage.id)")
        } else {
            AppLogger.chat.logDebug("Skipping user message save (already saved with metadata)")
            // For fact-check messages, create a placeholder since we won't return it
            // The actual message with metadata was already saved before calling this use case
            userMessage = Message(
                id: "", // Placeholder - not used
                conversationId: conversationId,
                content: message,
                isUserMessage: true,
                timestamp: Date(),
                sources: [],
                imageData: imageData,
                detectedLanguage: detectedLanguage,
                isFactCheckMessage: isFactCheckMessage
            )
        }

        // Check network connectivity after persisting the user message locally
        guard networkMonitor.isConnected else {
            AppLogger.chat.logWarning("No network connection")
            throw NetworkError.noConnection
        }

        do {
            // Send message to API
            // Reuse existing thread when history exists but threadId is missing by falling back to conversation id
            var threadIdForRequest = conversation.threadId
            if threadIdForRequest == nil,
               conversation.isLocalOnly == false,
               conversation.hasMessages {
                threadIdForRequest = conversation.id
                try? await chatRepository.updateConversationThreadId(id: conversationId, threadId: conversation.id)
                AppLogger.chat.logDebug("Thread ID missing; defaulting to conversationId for request: \(conversation.id)")
            }

            // Guest/local-only conversations should prefer sessionId over threadId
            let sessionIdForRequest = shouldSendAsGuest ? (threadIdForRequest ?? conversation.id) : nil
            let threadIdPayload = shouldSendAsGuest ? nil : threadIdForRequest

            AppLogger.network.logInfo("Sending message to API with threadId: \(threadIdPayload ?? "nil") sessionId: \(sessionIdForRequest ?? "nil") for conversation \(conversationId)")

            let request = ChatRequest(
                question: message,
                threadId: threadIdPayload,
                languagePreference: LanguageManager.shared.currentLanguage.rawValue,
                sessionId: sessionIdForRequest
            )

            let response = try await apiClient.sendMessage(request)

            AppLogger.network.logInfo("Received response from API with threadId: \(response.threadId ?? "nil")")
            AppLogger.network.logDebug("Raw API answer length: \(response.answer.count)")
            AppLogger.network.logDebug("Raw API answer preview (first 500 chars): \(response.answer.prefix(500))")

            // Update thread ID if provided and this is the first message
            if conversation.threadId == nil, let newThreadId = response.threadId {
                AppLogger.chat.logInfo("Updating conversation \(conversationId) threadId to \(newThreadId)")
                try await chatRepository.updateConversationThreadId(
                    id: conversationId,
                    threadId: newThreadId
                )
            } else if response.threadId == nil {
                AppLogger.chat.logWarning("API response did not include thread_id")
            }

            // Parse the markdown response to extract content and sources
            AppLogger.chat.logDebug("Parsing markdown response")
            let parsedResponse = ResponseParser.parseMarkdownResponse(response.answer)

            AppLogger.chat.logInfo("Parsed response: \(parsedResponse.cleanContent.count) chars, \(parsedResponse.sources.count) sources")

            // Save assistant message with sources
            AppLogger.chat.logDebug("Saving assistant message locally")
            let assistantMessage = try await chatRepository.addMessage(
                toConversation: conversationId,
                content: parsedResponse.cleanContent,
                isUserMessage: false,
                sources: parsedResponse.sources
            )

            AppLogger.chat.logInfo("Assistant message saved with ID: \(assistantMessage.id)")

            // Fetch updated conversation
            guard let updatedConversation = try await chatRepository.fetchConversation(byId: conversationId) else {
                AppLogger.chat.logError("Failed to fetch updated conversation")
                throw ChatRepositoryError.conversationNotFound
            }

            AppLogger.chat.logInfo("SendMessageUseCase completed successfully")

            return Result(
                userMessage: userMessage,
                assistantMessage: assistantMessage,
                conversation: updatedConversation
            )

        } catch {
            AppLogger.chat.logError("SendMessageUseCase failed", error: error)
            // If API call fails, we keep the user message in local storage
            // This allows offline mode and retry capability
            throw error
        }
    }

    /// Executes the use case and returns a publisher
    /// - Parameters:
    ///   - conversationId: The ID of the conversation
    ///   - message: The message content
    ///   - imageData: Optional image data for fact-check messages
    ///   - detectedLanguage: Optional detected language code
    ///   - isFactCheckMessage: Whether this is a fact-check message
    ///   - saveUserMessage: Whether to save the user message (false for fact-check messages)
    /// - Returns: Publisher that emits the result or an error
    func executePublisher(
        conversationId: String,
        message: String,
        imageData: Data? = nil,
        detectedLanguage: String? = nil,
        isFactCheckMessage: Bool = false,
        saveUserMessage: Bool = true
    ) -> AnyPublisher<Result, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await self.execute(
                        conversationId: conversationId,
                        message: message,
                        imageData: imageData,
                        detectedLanguage: detectedLanguage,
                        isFactCheckMessage: isFactCheckMessage,
                        saveUserMessage: saveUserMessage
                    )
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

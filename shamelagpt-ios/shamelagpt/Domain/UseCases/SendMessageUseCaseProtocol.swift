//
//  SendMessageUseCaseProtocol.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine

/// Protocol for sending messages use case
protocol SendMessageUseCaseProtocol {
    /// Executes the use case to send a message
    func execute(
        conversationId: String,
        message: String,
        imageData: Data?,
        detectedLanguage: String?,
        isFactCheckMessage: Bool,
        saveUserMessage: Bool
    ) async throws -> SendMessageUseCase.Result
    
    /// Executes the use case and returns a publisher
    func executePublisher(
        conversationId: String,
        message: String,
        imageData: Data?,
        detectedLanguage: String?,
        isFactCheckMessage: Bool,
        saveUserMessage: Bool
    ) -> AnyPublisher<SendMessageUseCase.Result, Error>
}

/// Extension to provide default parameter values
extension SendMessageUseCaseProtocol {
    func execute(
        conversationId: String,
        message: String,
        imageData: Data? = nil,
        detectedLanguage: String? = nil,
        isFactCheckMessage: Bool = false,
        saveUserMessage: Bool = true
    ) async throws -> SendMessageUseCase.Result {
        try await execute(
            conversationId: conversationId,
            message: message,
            imageData: imageData,
            detectedLanguage: detectedLanguage,
            isFactCheckMessage: isFactCheckMessage,
            saveUserMessage: saveUserMessage
        )
    }
    
    func executePublisher(
        conversationId: String,
        message: String,
        imageData: Data? = nil,
        detectedLanguage: String? = nil,
        isFactCheckMessage: Bool = false,
        saveUserMessage: Bool = true
    ) -> AnyPublisher<SendMessageUseCase.Result, Error> {
        executePublisher(
            conversationId: conversationId,
            message: message,
            imageData: imageData,
            detectedLanguage: detectedLanguage,
            isFactCheckMessage: isFactCheckMessage,
            saveUserMessage: saveUserMessage
        )
    }
}

/// Extension to make SendMessageUseCase conform to the protocol
extension SendMessageUseCase: SendMessageUseCaseProtocol {}

//
//  DeleteConversationUseCase.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine

/// Use case for deleting conversations
final class DeleteConversationUseCase {

    // MARK: - Properties

    private let chatRepository: ChatRepository

    // MARK: - Initialization

    init(chatRepository: ChatRepository) {
        self.chatRepository = chatRepository
    }

    // MARK: - Execution

    /// Executes the use case to delete a single conversation
    /// - Parameter id: The ID of the conversation to delete
    /// - Throws: Repository errors
    func execute(id: String) async throws {
        try await chatRepository.deleteConversation(id: id)
    }

    /// Executes the use case to delete all conversations
    /// - Throws: Repository errors
    func executeDeleteAll() async throws {
        try await chatRepository.deleteAllConversations()
    }

    /// Executes the use case and returns a publisher for single deletion
    /// - Parameter id: The ID of the conversation to delete
    /// - Returns: Publisher that emits success or an error
    func executePublisher(id: String) -> AnyPublisher<Void, Error> {
        Future { promise in
            Task {
                do {
                    try await self.execute(id: id)
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Executes the use case and returns a publisher for deleting all conversations
    /// - Returns: Publisher that emits success or an error
    func executeDeleteAllPublisher() -> AnyPublisher<Void, Error> {
        Future { promise in
            Task {
                do {
                    try await self.executeDeleteAll()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

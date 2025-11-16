//
//  GetConversationsUseCase.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine

/// Use case for fetching all conversations
final class GetConversationsUseCase {

    // MARK: - Properties

    private let chatRepository: ChatRepository

    // MARK: - Initialization

    init(chatRepository: ChatRepository) {
        self.chatRepository = chatRepository
    }

    // MARK: - Execution

    /// Executes the use case to fetch all conversations
    /// - Returns: Array of conversations sorted by most recent first
    /// - Throws: Repository errors
    func execute() async throws -> [Conversation] {
        let conversations = try await chatRepository.fetchAllConversations()

        // Sort by updatedAt descending (most recent first)
        return conversations.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Executes the use case and returns a publisher
    /// - Returns: Publisher that emits conversations or an error
    func executePublisher() -> AnyPublisher<[Conversation], Error> {
        Future { promise in
            Task {
                do {
                    let conversations = try await self.execute()
                    promise(.success(conversations))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Returns a Combine publisher that continuously emits conversation updates
    /// - Returns: Publisher that emits conversation arrays
    func observeConversations() -> AnyPublisher<[Conversation], Never> {
        chatRepository.conversationsPublisher
            .map { conversations in
                // Sort by updatedAt descending (most recent first)
                conversations.sorted { $0.updatedAt > $1.updatedAt }
            }
            .eraseToAnyPublisher()
    }
}

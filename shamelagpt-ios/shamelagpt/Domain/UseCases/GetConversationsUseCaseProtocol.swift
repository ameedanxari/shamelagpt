//
//  GetConversationsUseCaseProtocol.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine

/// Protocol for getting conversations use case
protocol GetConversationsUseCaseProtocol {
    func execute() async throws -> [Conversation]
    func executePublisher() -> AnyPublisher<[Conversation], Error>
    func observeConversations() -> AnyPublisher<[Conversation], Never>
}

/// Extension to make GetConversationsUseCase conform to the protocol
extension GetConversationsUseCase: GetConversationsUseCaseProtocol {}

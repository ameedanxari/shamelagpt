//
//  DeleteConversationUseCaseProtocol.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine

/// Protocol for deleting conversations use case
protocol DeleteConversationUseCaseProtocol {
    func execute(id: String) async throws
    func executeDeleteAll() async throws
    func executePublisher(id: String) -> AnyPublisher<Void, Error>
    func executeDeleteAllPublisher() -> AnyPublisher<Void, Error>
}

/// Extension to make DeleteConversationUseCase conform to the protocol
extension DeleteConversationUseCase: DeleteConversationUseCaseProtocol {}

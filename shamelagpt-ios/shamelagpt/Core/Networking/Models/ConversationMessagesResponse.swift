//
//  ConversationMessagesResponse.swift
//  ShamelaGPT
//
//  Created by Codex on 12/07/2025.
//

import Foundation

struct ConversationMessagesResponse: Codable, Equatable {
    let conversationId: String?
    let messages: [MessageResponse]
}

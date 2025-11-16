//
//  ConversationResponse.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

struct ConversationResponse: Codable, Equatable {
    let id: String
    let threadId: String?
    let title: String?
    let createdAt: String?
    let updatedAt: String?
}

//
//  MessageResponse.swift
//  ShamelaGPT
//
//  Created by Codex on 12/07/2025.
//

import Foundation

struct MessageResponse: Codable, Equatable {
    let id: String?
    let role: String?
    let content: String?
    let createdAt: String?
    /// The model's chain-of-thought for an assistant message, already concatenated
    /// server-side. Nullable: absent on user messages and on anything stored before
    /// the backend started splitting reasoning out of `thinking_steps`.
    let reasoning: String?
}

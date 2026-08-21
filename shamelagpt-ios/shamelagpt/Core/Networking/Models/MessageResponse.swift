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
    /// Defaulted so call sites that predate the reasoning channel — tests and fixtures
    /// constructing this directly — keep compiling without restating it.
    let reasoning: String?

    init(
        id: String?,
        role: String?,
        content: String?,
        createdAt: String?,
        reasoning: String? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.reasoning = reasoning
    }
}

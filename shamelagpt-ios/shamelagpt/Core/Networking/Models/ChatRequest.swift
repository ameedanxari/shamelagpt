//
//  ChatRequest.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Request model for sending a chat message to the API
struct ChatRequest: Codable {
    let question: String
    let threadId: String?

    init(question: String, threadId: String? = nil) {
        self.question = question
        self.threadId = threadId
    }

    enum CodingKeys: String, CodingKey {
        case question
        case threadId = "thread_id"
    }
}

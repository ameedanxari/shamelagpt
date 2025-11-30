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

    // CodingKeys removed to allow JSONEncoder/Decoder keyEncodingStrategy to handle snake_case conversion automatically
}

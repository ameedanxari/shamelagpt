//
//  ChatResponse.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Response model for chat API endpoint
struct ChatResponse: Codable {
    let answer: String
    let threadId: String?

    enum CodingKeys: String, CodingKey {
        case answer
        case threadId = "thread_id"
    }
}

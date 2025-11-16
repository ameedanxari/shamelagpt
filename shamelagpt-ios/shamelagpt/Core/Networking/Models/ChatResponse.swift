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

    // CodingKeys removed to allow JSONDecoder keyDecodingStrategy to handle snake_case conversion automatically
}

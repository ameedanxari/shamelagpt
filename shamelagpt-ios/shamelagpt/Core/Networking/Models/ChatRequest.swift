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
    let promptConfig: PromptConfig?
    let languagePreference: String?
    let customSystemPrompt: String?
    let sessionId: String?
    let enableThinking: Bool?

    init(
        question: String,
        threadId: String? = nil,
        promptConfig: PromptConfig? = nil,
        languagePreference: String? = nil,
        customSystemPrompt: String? = nil,
        sessionId: String? = nil,
        enableThinking: Bool? = nil
    ) {
        self.question = question
        self.threadId = threadId
        self.promptConfig = promptConfig
        self.languagePreference = languagePreference
        self.customSystemPrompt = customSystemPrompt
        self.sessionId = sessionId
        self.enableThinking = enableThinking
    }

    // CodingKeys removed to allow JSONEncoder/Decoder keyEncodingStrategy to handle snake_case conversion automatically
}

/// Represents the prompt_config field which may be a preset string or a custom object
enum PromptConfig: Codable, Equatable {
    case preset(String)
    case custom([String: String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let preset = try? container.decode(String.self) {
            self = .preset(preset)
        } else if let config = try? container.decode([String: String].self) {
            self = .custom(config)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported prompt_config format"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .preset(let preset):
            try container.encode(preset)
        case .custom(let config):
            try container.encode(config)
        }
    }
}

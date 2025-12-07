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
}

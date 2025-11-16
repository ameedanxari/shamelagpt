//
//  UserResponse.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

struct UserResponse: Codable, Equatable {
    let id: String
    let firebaseUid: String
    let email: String?
    let displayName: String?
    let createdAt: String
    let updatedAt: String
    let lastLogin: String?
}

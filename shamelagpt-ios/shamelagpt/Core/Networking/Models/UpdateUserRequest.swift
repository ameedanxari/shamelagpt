//
//  UpdateUserRequest.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

struct UpdateUserRequest: Codable, Equatable {
    let email: String?
    let displayName: String?
}

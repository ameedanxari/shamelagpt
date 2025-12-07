//
//  SignupRequest.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

struct SignupRequest: Codable, Equatable {
    let email: String
    let password: String
    let displayName: String?
}

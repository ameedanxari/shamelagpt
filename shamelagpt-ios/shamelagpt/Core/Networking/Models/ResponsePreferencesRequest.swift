//
//  ResponsePreferencesRequest.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

struct ResponsePreferencesRequest: Codable, Equatable {
    let length: String?
    let style: String?
    let focus: String?
}

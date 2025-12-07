//
//  GenerateTitleRequest.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

struct GenerateTitleRequest: Codable, Equatable {
    let question: String
    let language: String?
}

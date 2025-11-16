//
//  HealthResponse.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Response model for health check endpoint
struct HealthResponse: Codable {
    let status: String
    let service: String
}

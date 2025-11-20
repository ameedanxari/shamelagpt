//
//  AppRoute.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Defines all possible navigation routes in the app
enum AppRoute: Hashable {
    case welcome
    case chat(conversationId: String?)
    case history
    case settings
    case languageSelection
    case about
    case privacyPolicy
    case termsOfService
}

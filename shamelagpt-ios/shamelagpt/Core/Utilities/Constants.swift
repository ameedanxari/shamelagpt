//
//  Constants.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 04/11/2025.
//

import Foundation

enum Constants {
    // MARK: - API Configuration
    enum API {
        static let baseURL = "https://api.shamelagpt.com"
        static let timeoutInterval: TimeInterval = 30.0

        enum Endpoints {
            static let health = "/api/health"
            static let chat = "/api/chat"
        }
    }

    // MARK: - App Configuration
    enum App {
        static let name = "ShamelaGPT"
        static let bundleId = "com.shamelagpt.ios"
        static let version = "1.0.0"
    }

    // MARK: - Storage Keys
    enum Storage {
        static let hasSeenWelcome = "hasSeenWelcome"
        static let selectedLanguage = "selectedLanguage"
    }

    // MARK: - URLs
    enum ExternalURLs {
        static let donation = "https://www.paypal.com/donate/?hosted_button_id=MSBDG5ESU2AMU"
        static let shamela = "https://shamela.ws"
    }

    // MARK: - UI Configuration
    enum UI {
        static let messageBubbleRadius: CGFloat = 18
        static let maxInputLines: Int = 5
        static let messageFontSize: CGFloat = 16
        static let iconSize: CGFloat = 80
    }
}

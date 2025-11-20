//
//  AppTheme.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 04/11/2025.
//

import SwiftUI

/// App-wide theme configuration
struct AppTheme {
    // MARK: - Colors
    struct Colors {
        static let primary = Color.primaryGreen
        static let primaryLight = Color.primaryLight
        static let accent = Color.accentGold

        // Message Bubbles
        static let userMessageBackground = Color.blue
        static let aiMessageBackground = Color(.systemGray5)
        static let messageText = Color.primary

        // Backgrounds
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)

        // Text
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(.tertiaryLabel)
    }

    // MARK: - Typography
    struct Typography {
        static let title = Font.system(size: 28, weight: .bold)
        static let heading = Font.system(size: 20, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 14, weight: .regular)
        static let small = Font.system(size: 12, weight: .regular)
    }

    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Layout
    struct Layout {
        static let cornerRadius: CGFloat = 12
        static let messageBubbleRadius: CGFloat = 18
        static let buttonHeight: CGFloat = 50
        static let iconSize: CGFloat = 24
        static let largeIconSize: CGFloat = 80
    }

    // MARK: - Animation
    struct Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
}

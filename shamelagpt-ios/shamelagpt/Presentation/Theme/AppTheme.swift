//
//  AppTheme.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 04/11/2025.
//
//  This file provides backward-compatible access to theme values.
//  New code should prefer using DesignSystem directly.
//

import SwiftUI
import UIKit

/// App-wide theme configuration
/// Note: For new code, prefer using `DesignSystem` directly for full light/dark mode support.
struct AppTheme {
    // MARK: - Colors (Legacy API - maintained for compatibility)
    struct Colors {
        static let primary = DesignSystem.Colors.primary
        static let primaryLight = DesignSystem.Colors.primaryLight
        static let accent = DesignSystem.Colors.accent

        // Message Bubbles - Updated to minimal styling per website design
        // Note: Website uses no bubble backgrounds, just text on background
        static let userMessageBackground = Color.clear
        static let aiMessageBackground = Color.clear
        static let messageText = Color.primary

        // Backgrounds - These use system colors for automatic light/dark support
        // For explicit control, use DesignSystem.Colors.background(colorScheme)
        // Adaptive rather than `systemBackground`, otherwise screens using this legacy
        // API render plain white while the brand surfaces are warm cream, and the app
        // looks like two different products stitched together.
        static let background = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.071, green: 0.078, blue: 0.059, alpha: 1)   // #12140F
                : UIColor(red: 0.980, green: 0.969, blue: 0.949, alpha: 1)   // #FAF7F2
        })
        static let secondaryBackground = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.102, green: 0.114, blue: 0.086, alpha: 1)   // #1A1D16
                : UIColor(red: 0.953, green: 0.929, blue: 0.890, alpha: 1)   // #F3EDE3
        })

        // Text
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(.tertiaryLabel)
        
        // Source links (amber color per website)
        static let sourceLink = DesignSystem.Colors.sourceLink
    }

    // MARK: - Typography (delegated to DesignSystem)
    struct Typography {
        static let title = DesignSystem.Typography.title
        static let heading = DesignSystem.Typography.title3
        static let body = DesignSystem.Typography.body
        static let caption = DesignSystem.Typography.subheadline
        static let small = DesignSystem.Typography.caption
    }

    // MARK: - Spacing (delegated to DesignSystem)
    struct Spacing {
        static let xxs: CGFloat = DesignSystem.Spacing.xxs
        static let xs: CGFloat = DesignSystem.Spacing.xs
        static let sm: CGFloat = DesignSystem.Spacing.sm
        static let md: CGFloat = DesignSystem.Spacing.md
        static let lg: CGFloat = DesignSystem.Spacing.lg
        static let xl: CGFloat = DesignSystem.Spacing.xl
        static let xxl: CGFloat = DesignSystem.Spacing.xxl
    }

    // MARK: - Layout (delegated to DesignSystem)
    struct Layout {
        static let cornerRadius: CGFloat = DesignSystem.Layout.cornerRadius
        static let messageBubbleRadius: CGFloat = DesignSystem.Layout.cornerRadiusLarge
        static let buttonHeight: CGFloat = DesignSystem.Layout.buttonHeight
        static let iconSize: CGFloat = DesignSystem.Layout.iconSize
        static let largeIconSize: CGFloat = 80
    }

    // MARK: - Animation (delegated to DesignSystem)
    struct Animation {
        static let standard = DesignSystem.Animation.standard
        static let quick = DesignSystem.Animation.quick
        static let slow = DesignSystem.Animation.slow
    }
    
    // MARK: - Gradients
    struct Gradients {
        static let primary = DesignSystem.Gradients.primary
        static let button = DesignSystem.Gradients.button
        static let vertical = DesignSystem.Gradients.vertical
    }
}

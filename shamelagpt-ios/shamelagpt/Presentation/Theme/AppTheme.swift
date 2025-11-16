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
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)

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

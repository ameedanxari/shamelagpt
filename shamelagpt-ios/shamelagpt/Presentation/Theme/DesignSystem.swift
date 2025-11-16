//
//  DesignSystem.swift
//  ShamelaGPT
//
//  Centralized design tokens for consistent theming across the app.
//  Supports light/dark modes and future white-label customization.
//

import SwiftUI

// MARK: - Design System

/// Centralized design system providing semantic tokens for colors, typography, spacing, and gradients.
/// All UI components should reference these tokens instead of hardcoded values.
enum DesignSystem {
    
    // MARK: - Brand Colors (Raw Values)
    
    enum Brand {
        /// Primary emerald color - #10B981
        static let emerald = Color(hex: "#10B981")
        /// Light emerald variant - #5CDBB3
        static let emeraldLight = Color(hex: "#5CDBB3")
        /// Dark emerald variant - #059669
        static let emeraldDark = Color(hex: "#059669")
        
        /// Teal for gradients - #2DD4BF
        static let teal = Color(hex: "#2DD4BF")
        /// Cyan for gradients - #22D3EE
        static let cyan = Color(hex: "#22D3EE")
        
        /// Amber accent - #F59E0B
        static let amber = Color(hex: "#F59E0B")
        /// Light amber variant - #FACC15
        static let amberLight = Color(hex: "#FACC15")
    }
    
    // MARK: - Semantic Colors
    
    enum Colors {
        // MARK: Primary
        
        /// Main brand color for buttons, links, active states
        static let primary = Brand.emerald
        /// Lighter variant for hover/pressed states in dark mode
        static let primaryLight = Brand.emeraldLight
        /// Darker variant for hover/pressed states in light mode
        static let primaryDark = Brand.emeraldDark
        
        /// Accent color for highlights, source links, badges
        static let accent = Brand.amber
        
        // MARK: Backgrounds
        
        /// Main background - dark mode: #0f0f0f, light mode: system
        static func background(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#0f0f0f") : Color(hex: "#FAFAFA")
        }
        
        /// Secondary/surface background - dark mode: #171717, light mode: system secondary
        static func surface(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#171717") : Color(hex: "#F1F3F6")
        }
        
        /// Card/elevated surface - dark mode: #1F2937, light mode: white
        static func card(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#1F2937") : Color.white
        }
        
        /// Input field background
        static func inputBackground(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#1F2937") : Color(hex: "#E8ECF2")
        }
        
        // MARK: Text
        
        /// Primary text color
        static func textPrimary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color.white : Color(hex: "#111827")
        }
        
        /// Secondary/muted text color
        static func textSecondary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#9CA3AF") : Color(hex: "#6B7280")
        }
        
        /// Tertiary/placeholder text color
        static func textTertiary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#6B7280") : Color(hex: "#9CA3AF")
        }
        
        // MARK: Messages (Minimal styling per website design)
        
        /// User message text color (right-aligned, on background)
        static func userMessageText(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color.white : Color(hex: "#111827")
        }
        
        /// AI message text color (left-aligned, on background)
        static func aiMessageText(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color.white : Color(hex: "#111827")
        }
        
        /// Source link color (amber)
        static let sourceLink = Brand.amber
        
        // MARK: Borders & Outlines
        
        /// Default border color
        static func border(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#374151") : Color(hex: "#CBD5E1")
        }
        
        /// Focus ring color
        static let focusRing = Brand.emerald
        
        // MARK: Feedback
        
        /// Error color
        static let error = Color(hex: "#EF4444")
        /// Success color
        static let success = Brand.emerald
        /// Warning color
        static let warning = Brand.amber
    }
    
    // MARK: - Gradients
    
    enum Gradients {
        /// Primary brand gradient: Emerald → Teal → Cyan (horizontal)
        static let primary = LinearGradient(
            colors: [Brand.emerald, Brand.teal, Brand.cyan],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        /// Vertical brand gradient
        static let vertical = LinearGradient(
            colors: [Brand.emerald, Brand.teal, Brand.cyan],
            startPoint: .top,
            endPoint: .bottom
        )
        
        /// Subtle gradient for buttons (emerald to teal only)
        static let button = LinearGradient(
            colors: [Brand.emerald, Brand.teal],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Typography
    
    enum Typography {
        private static func customFont(_ name: String, size: CGFloat, weight: Font.Weight) -> Font {
            // Temporary UI-test bypass: use pure system fonts across all locales/languages.
            return .system(size: size, weight: weight)
        }
        
        static let largeTitle = customFont("SFArabic", size: 34, weight: .bold)
        static let title = customFont("SFArabic", size: 28, weight: .bold)
        static let title2 = customFont("SFArabic", size: 22, weight: .bold)
        static let title3 = customFont("SFArabic", size: 20, weight: .semibold)
        static let headline = customFont("SFArabic", size: 17, weight: .semibold)
        static let body = customFont("SFArabic", size: 17, weight: .regular)
        static let callout = customFont("SFArabic", size: 16, weight: .regular)
        static let subheadline = customFont("SFArabic", size: 15, weight: .regular)
        static let footnote = customFont("SFArabic", size: 13, weight: .regular)
        static let caption = customFont("SFArabic", size: 12, weight: .regular)
        static let caption2 = customFont("SFArabic", size: 11, weight: .regular)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Layout
    
    enum Layout {
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadius: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        static let cornerRadiusXL: CGFloat = 24
        
        static let buttonHeight: CGFloat = 50
        static let inputHeight: CGFloat = 48
        static let iconSize: CGFloat = 24
        static let iconSizeLarge: CGFloat = 32
        static let avatarSize: CGFloat = 40
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies the primary gradient as foreground
    func gradientForeground() -> some View {
        self.foregroundStyle(DesignSystem.Gradients.primary)
    }
    
    /// Applies the primary gradient as background with corner radius
    func gradientBackground(cornerRadius: CGFloat = DesignSystem.Layout.cornerRadius) -> some View {
        self.background(DesignSystem.Gradients.button)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Button Styles

/// Primary gradient button style matching website design
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(
                Group {
                    if isEnabled {
                        DesignSystem.Gradients.button
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusLarge))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

/// Secondary outlined button style
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(isEnabled ? DesignSystem.Colors.primary : .gray)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(DesignSystem.Colors.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusLarge)
                    .stroke(
                        isEnabled ? DesignSystem.Colors.primary : Color.gray.opacity(0.3),
                        lineWidth: 1.5
                    )
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Input Field Style

/// Styled text field matching website design
struct ThemedTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.inputBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusLarge)
                    .stroke(DesignSystem.Colors.border(colorScheme), lineWidth: 1)
            )
    }
}

extension TextFieldStyle where Self == ThemedTextFieldStyle {
    static var themed: ThemedTextFieldStyle { ThemedTextFieldStyle() }
}

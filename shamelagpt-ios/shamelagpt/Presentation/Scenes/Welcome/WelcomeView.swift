//
//  WelcomeView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void
    var onSkipToChat: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var contentOffset: CGFloat = 30
    @State private var contentOpacity: Double = 0.0

    var body: some View {
        ZStack {
            DesignSystem.Colors.background(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // Logo
                Image(systemName: "book.circle.fill")
                    .font(.system(size: AppTheme.Layout.largeIconSize))
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding(.top, AppTheme.Spacing.xxl)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .accessibilityLabel(Text(LocalizationKeys.logoAccessibilityLabel.localizedKey))
                    .accessibilityIdentifier(AccessibilityID.Welcome.logo)

                // Scrollable Welcome Message
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        welcomeText
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                // Buttons
                VStack(spacing: AppTheme.Spacing.sm) {
                    // Get Started Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            onGetStarted()
                        }
                    }) {
                        Text(LocalizationKeys.getStarted.localizedKey)
                            .font(AppTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.Layout.buttonHeight)
                    }
                    .buttonStyle(.primary)
                    .accessibilityLabel(Text(LocalizationKeys.getStarted.localizedKey))
                    .accessibilityIdentifier(AccessibilityID.Welcome.getStartedButton)
                    .accessibilityHint(Text(LocalizationKeys.getStartedAccessibilityHint.localizedKey))

                    // Skip to Chat Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            onSkipToChat()
                        }
                    }) {
                        Text(LocalizationKeys.skipToChat.localizedKey)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .accessibilityLabel(Text(LocalizationKeys.skipToChat.localizedKey))
                    .accessibilityIdentifier(AccessibilityID.Welcome.skipToChatButton)
                    .accessibilityHint(Text(LocalizationKeys.skipToChatAccessibilityHint.localizedKey))
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.lg)
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                contentOffset = 0
                contentOpacity = 1.0
            }
        }
    }

    private var welcomeText: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Welcome Header
            Text(LocalizationKeys.welcomeTitle.localizedKey)
                .font(AppTheme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))

            // Introduction
            Text(LocalizationKeys.welcomeIntro.localizedKey)
                .font(AppTheme.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                .lineSpacing(4)

            Divider()
                .padding(.vertical, AppTheme.Spacing.xs)

            // Sign In Section
            Text(LocalizationKeys.welcomeSignInTitle.localizedKey)
                .font(AppTheme.Typography.heading)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))

            Text(LocalizationKeys.welcomeSignInMessage.localizedKey)
                .font(AppTheme.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                .lineSpacing(4)
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(
            onGetStarted: {},
            onSkipToChat: {}
        )
    }
}

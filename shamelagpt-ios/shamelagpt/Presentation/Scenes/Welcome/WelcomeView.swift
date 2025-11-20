//
//  WelcomeView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var contentOffset: CGFloat = 30
    @State private var contentOpacity: Double = 0.0

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // Logo
                Image(systemName: "book.circle.fill")
                    .font(.system(size: AppTheme.Layout.largeIconSize))
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding(.top, AppTheme.Spacing.xxl)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .accessibilityLabel(LocalizationKeys.logoAccessibilityLabel.localized)

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
                            coordinator.dismissWelcome()
                        }
                    }) {
                        Text(LocalizationKeys.getStarted.localized)
                            .font(AppTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.Layout.buttonHeight)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.Layout.cornerRadius)
                    }
                    .accessibilityLabel(LocalizationKeys.getStarted.localized)
                    .accessibilityHint(LocalizationKeys.getStartedAccessibilityHint.localized)

                    // Skip to Chat Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            coordinator.dismissWelcome()
                        }
                    }) {
                        Text(LocalizationKeys.skipToChat.localized)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .accessibilityLabel(LocalizationKeys.skipToChat.localized)
                    .accessibilityHint(LocalizationKeys.skipToChatAccessibilityHint.localized)
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
            Text(LocalizationKeys.welcomeTitle.localized)
                .font(AppTheme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.primaryText)

            // Introduction
            Text(LocalizationKeys.welcomeIntro.localized)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .lineSpacing(4)

            Divider()
                .padding(.vertical, AppTheme.Spacing.xs)

            // Sign In Section
            Text(LocalizationKeys.welcomeSignInTitle.localized)
                .font(AppTheme.Typography.heading)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.primaryText)

            Text(LocalizationKeys.welcomeSignInMessage.localized)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .lineSpacing(4)
        }
    }
}

#Preview {
    WelcomeView(coordinator: AppCoordinator())
}
